FROM golang:1.21.3-alpine3.18@sha256:27c76dcf886c5024320f4fa8ceb57d907494a3bb3d477d0aa7ac8385acd871ea

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
