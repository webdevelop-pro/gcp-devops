# Django docker image

Pre-build django image with python 3.12

- Speed up CI/CD build up to 10 times
- Make sure base image is secure with snyk vulnerability scanner
- Universal make.sh file to help have similar pipelines on different go based repos

## Installation

1. Set up credentials for cr.webdevelop.pro and docker.io/webdevelop-pro
2. Set up credentials for [snyk](https://snyk.io/) to verify image security vulnerabilities

## Deploy
1. build and deploy using `./build-deploy.sh` script

## Structure
- build all heavy dependencies (gcc, fx.uber, modern-go/concurrent, modern-go/reflect2)
- `etc/ruff.toml` - actuall rules for golang linter
- `etc/make.sh` - bash utility with usefull commands
- `etc/pre-commit` - git pre-commit rules

## Usage example
```Dockerfile
FROM cr.webdevelop.us/webdevelop-pro/go-common:latest-dev AS builder

# RUN apk add --no-cache make gcc musl-dev linux-headers git gettext - no longer needed
# fast build cause of pre-build requirements
RUN ./make.sh build 
```

# ToDo
- [ ] add ruff linter
- [ ] add ruff linter config
- [ ] add make.sh and installaion guides

