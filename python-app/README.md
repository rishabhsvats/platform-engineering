Python Application


Kind Cluster : https://kind.sigs.k8s.io/docs/user/ingress/
- Ingress worker processes update same as the number of worker processes running in Nginx pod
```
$ kubectl -n ingress-nginx exec -it ingress-nginx-controller-xxxx sh
$ ps -ef 
$ kubectl edit configmap -n ingress-nginx ingress-nginx-controller
```

Github Runner : https://github.com/actions/actions-runner-controller/blob/master/docs/quickstart.md

