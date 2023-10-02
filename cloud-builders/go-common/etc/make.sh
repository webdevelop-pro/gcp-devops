#!/usr/bin/env sh
# system functions
basename() {
    # Usage: basename "path" ["suffix"]
    local tmp
    tmp=${1%"${1##*[!/]}"}
    tmp=${tmp##*/}
    tmp=${tmp%"${2/"$tmp"}"}
    printf '%s\n' "${tmp:-/}"
}

lstrip() {
    # Usage: lstrip "string" "pattern"
    printf '%s\n' "${1##$2}"
}

WORK_DIR=$(pwd)
COMPANY_NAME=webdevelop-pro
SERVICE_NAME=$(lstrip $(basename $(pwd)) "i-")
REPOSITORY=$COMPANY_NAME/i-$SERVICE_NAME

init() {
  GO_FILES=$(find . -name '*.go' | grep -v _test.go)
  PKG_LIST=$(go list ./... | grep -v /lib/)
}

build() {
  go build -ldflags "-s -w -X main.repository=${REPOSITORY} -X main.revisionID=${GIT_COMMIT} -X main.version=${BUILD_DATE}:${GIT_COMMIT} -X main.service=${SERVICE_NAME}" -o ./app ./cmd/server/*.go && chmod +x ./app
}

self_update() {
  mkdir etc;
  docker pull cr.webdevelop.us/webdevelop-pro/go-common:latest-dev;
  docker rm -f makesh;
  docker run --name=makesh cr.webdevelop.us/webdevelop-pro/go-common:latest-dev &&
  docker cp makesh:/app/etc/make.sh make.sh;
  docker cp makesh:/app/etc/golangci.yml .golangci.yml;
  docker cp makesh:/app/etc/pre-commit etc/pre-commit;
  docker stop makesh;
}

case $1 in

install)
  echo "golang global dependencies"
  curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.54.2
  go install github.com/go-swagger/go-swagger/cmd/swagger@latest
  go install github.com/securego/gosec/v2/cmd/gosec@latest
  go install github.com/cosmtrek/air@latest

  echo "set up pre-commit hook and make.sh file"
  self_update;

  if [ -d ".git" -a -d ".git/hooks" ]
  then
    rm .git/hooks/pre-commit 2>/dev/null;
    ln -s etc/pre-commit .git/hooks/pre-commit
  fi
  ;;

lint)
  golangci-lint -c .golangci.yml run
  ;;

test)
  case $2 in
  unit)
    init
    go test -run=Unit -count=1 ${PKG_LIST} $2 $3
    ;;

  integration)
    init
    go test -run=Integration -count=1 ${PKG_LIST} $2 $3
    ;;
  *)
      init
      go test -count=1 ${PKG_LIST} $2 $3
    ;;

    esac
  ;;

race)
  init
  go test -race -short ${PKG_LIST}
  ;;

self-update)
  docker rm -f makesh;
  self_update;
  ;;

run-dev)
  # make sure you have proper .air.toml
  air
  ;;

memory)
  init
  CC=clang go test -msan -short ${PKG_LIST}
  ;;

coverage)
  init
  mkdir /tmp/coverage >/dev/null
  rm /tmp/coverage/*.cov
  for package in ${PKG_LIST}; do
    go test -covermode=count -coverprofile "/tmp/coverage/${package##*/}.cov" "$package"
  done
  tail -q -n +2 /tmp/coverage/*.cov >>/tmp/coverage/coverage.cov
  go tool cover -func=/tmp/coverage/coverage.cov
  ;;

run)
  GIT_COMMIT=$(git rev-parse --short HEAD)
  BUILD_DATE=$(date "+%Y%m%d")
  build && ./app
  ;;

audit)
  echo "running gosec"
  gosec ./...
  ;;

build)
  build
  ;;

swag-doc)
  # docs - https://goswagger.io/use/spec/route.html
  swagger generate spec --scan-models -o swagger.json
  ;;

deploy-dev)
  BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
  GIT_COMMIT=`git rev-parse --short HEAD`
  echo $BRANCH_NAME, $GIT_COMMIT
  docker build -t cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:$GIT_COMMIT -t cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:latest-dev --platform=linux/amd64 .
  # snyk container test cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:$GIT_COMMIT
  if [ $? -ne 0 ]; then
    echo "===================="
    echo "snyk has found a vulnerabilities, please consider choosing alternative image from snyk"
    echo "===================="
  fi
  docker push cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:$GIT_COMMIT
  docker push cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:latest-dev
  kubectl -n webdevelop-dev set image deployment/$SERVICE_NAME $SERVICE_NAME=cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:$GIT_COMMIT
  ;;

help)
  cat make.sh | grep "^[a-z-]*)"
  ;;

*)
  echo "unknown $1, try help"
  ;;

esac
