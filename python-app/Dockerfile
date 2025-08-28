FROM python:3.10-alpine

COPY ./python-app/requirements.txt /tmp

RUN pip install -r /tmp/requirements.txt

COPY ./python-app/src /src

CMD python /src/app.py