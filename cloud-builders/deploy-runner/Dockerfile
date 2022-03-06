FROM gcr.io/cloud-builders/gcloud

ADD requirements.txt requirements.txt

RUN apt update -y \
    && apt install -y python3.9 python3-pip jq \
    && curl -L https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64 --output yq_linux_amd64 \
    && chmod +x yq_linux_amd64 \
    && mv yq_linux_amd64 /usr/bin/yq \
    && pip install j2cli[yaml]

ENTRYPOINT [ "bash", "-c" ]
