FROM golang:alpine as build_app

RUN apk add git
# Build the Go app
ENV GO111MODULE off

RUN go get github.com/jpoles1/gopherbadger
RUN go build -o /gopherbadger /go/src/github.com/jpoles1/gopherbadger

FROM golang:alpine
RUN apk add bash
COPY --from=build_app /gopherbadger /bin/gopherbadger

ENTRYPOINT ["/bin/gopherbadger"]