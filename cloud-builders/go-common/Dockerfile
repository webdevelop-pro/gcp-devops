FROM golang:1.21.1-alpine3.18@sha256:3380a7e42c62007b14a7285882f764255d92e933ca7b31ae181f4b4dcd10fc06 AS builder

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
