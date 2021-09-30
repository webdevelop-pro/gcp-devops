FROM testcafe/testcafe

ENV DOCKERIZE_VERSION v0.6.1
USER root
RUN apk add --no-cache openssl ca-certificates wget yarn && update-ca-certificates
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz
COPY package.json .
RUN yarn
ENTRYPOINT ["/opt/testcafe/docker/testcafe-docker.sh"]

