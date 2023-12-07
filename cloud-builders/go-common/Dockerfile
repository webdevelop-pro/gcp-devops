FROM golang:1.21.5-alpine3.18@sha256:38d710f811d4b304c0db6e5af7f35d565c3555da77821a26f9a199d8fdf22ade

ARG GIT_COMMIT=unspecified
ARG BUILD_DATE=unspecified
ARG SERVICE_NAME=unspecified
ARG REPOSITORY=unspecified
ARG VERSION

LABEL GIT_COMMIT=$GIT_COMMIT
LABEL BUILD_DATE=$BUILD_DATE
LABEL SERVICE_NAME=$SERVICE_NAME
LABEL REPOSITORY=$REPOSITORY

ENV GOPATH=/go
ENV VERSION=${VERSION:-unknown}

RUN apk add --no-cache make gcc musl-dev linux-headers git gettext ca-certificates

ADD . /app

WORKDIR /app

RUN ./build-deploy.sh build

COPY etc ./etc /app/etc/
CMD ["/bin/sh"]
