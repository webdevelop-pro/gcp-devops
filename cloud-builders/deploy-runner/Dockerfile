FROM google/cloud-sdk:alpine@sha256:a7e555db3c3d8eee3a3a387872f75d891a72d5acd7df48962355053ae69e74e1

COPY ./requirements.txt requirements.txt
COPY ./yq_install.sh yq_install.sh

RUN apk update
RUN apk add --no-cache --virtual .build-deps  ca-certificates
RUN apk add bash python3 py3-pip

RUN ./yq_install.sh
RUN pip install -r requirements.txt

ENTRYPOINT [ "bash", "-c" ]
