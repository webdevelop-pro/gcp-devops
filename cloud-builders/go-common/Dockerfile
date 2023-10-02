FROM golang:1.20.2-alpine3.17@sha256:405962195c7fd525604cb74ab86cb7c88fcfc30af0e31a5b3c0636a7c4e9e567 AS builder

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

RUN ./make.sh build

FROM alpine:3.17.2@sha256:e2e16842c9b54d985bf1ef9242a313f36b856181f188de21313820e177002501

RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /app/app /app/app

CMD ["/app/app"]
