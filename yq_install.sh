# apt install -y python3.11 python3-pip && \
  curl -L https://github.com/mikefarah/yq/releases/download/v4.35.2/yq_linux_amd64.tar.gz | tar xz \
    && chmod +x yq_linux_amd64 \
    && mv yq_linux_amd64 /usr/bin/yq