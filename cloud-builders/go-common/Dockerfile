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

RUN apk add --no-cache make gcc musl-dev linux-headers git gettext

ADD . /app

WORKDIR /app

RUN ./build-deploy.sh build

FROM alpine:3.18.4@sha256:48d9183eb12a05c99bcc0bf44a003607b8e941e1d4f41f9ad12bdcc4b5672f86

RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /app/app /app/app
COPY etc ./etc /app/

CMD ["/app/app"]
