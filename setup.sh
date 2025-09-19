#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="kind"
KIND_CONFIG=$(mktemp)
ARGOCD_VALUES="python-app/charts/values-argo.yaml"

create_kind_config() {
cat <<EOF > "$KIND_CONFIG"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
EOF
}

install_ingress() {
    echo "[+] Installing ingress-nginx..."
    kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml

    echo "[+] Waiting for ingress controller to become ready..."
    kubectl wait --namespace ingress-nginx \
      --for=condition=Ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=180s
    echo "[+] Ingress-NGINX installed successfully."
}

install_argocd() {
    if [ ! -f "$ARGOCD_VALUES" ]; then
        echo "[-] ERROR: Values file not found at $ARGOCD_VALUES"
        exit 1
    fi

    echo "[+] Installing ArgoCD with values from $ARGOCD_VALUES..."
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1
    helm repo update >/dev/null 2>&1
    helm upgrade --install argocd argo/argo-cd \
        -n argocd \
        -f "$ARGOCD_VALUES"

    echo "[+] Waiting for ArgoCD server to become ready..."
    kubectl wait --namespace argocd \
      --for=condition=Ready pod \
      --selector=app.kubernetes.io/name=argocd-server \
      --timeout=300s
    echo "[+] ArgoCD installed successfully."
}

case "${1:-}" in
  create)
    create_kind_config
    kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
    echo "[+] Kind cluster '$CLUSTER_NAME' created with host ports 8080/8443."
    ;;
  ingress)
    install_ingress
    ;;
  argocd)
    install_argocd
    ;;
  remove)
    echo "[+] Deleting Kind cluster '$CLUSTER_NAME'..."
    kind delete cluster --name "$CLUSTER_NAME" || true
    echo "[+] Cleanup done."
    ;;
  *)
    echo "Usage: $0 {create|ingress|argocd|remove}"
    ;;
esac

