# Go lang common immage

- Improve docker build up for 10x times
- Make sure base image is secure with snyk vulnerability scanner
- Universal make.sh file to help have similar pipelines on different go based repos

## Structure
- build all heavy dependencies (gcc, fx.uber, modern-go/concurrent, modern-go/reflect2)
- `etc/golangci.yml` - actuall rules for golang linter
- `etc/make.sh` - bash utility with usefull commands
- `etc/pre-commit` - git pre-commit rules


## Usage example
```Dockerfile
FROM cr.webdevelop.us/webdevelop-pro/go-common:latest-dev AS builder

# RUN apk add --no-cache make gcc musl-dev linux-headers git gettext - no longer needed
# fast build cause of pre-build requirements
RUN ./make.sh build 
```

