FROM gcr.io/cloud-builders/gcloud@sha256:59b897e268a5be4a75fe078291bcbe790dd1f60ffa472c5be5030aefbcb9734c

ADD requirements.txt requirements.txt

RUN apt update -y \
    && apt install -y python3.9 python3-pip jq \
    && curl -L https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64 --output yq_linux_amd64 \
    && chmod +x yq_linux_amd64 \
    && mv yq_linux_amd64 /usr/bin/yq \
    && pip install -r requirements.txt \
    && pip install j2cli[yaml]

ENTRYPOINT [ "bash", "-c" ]
