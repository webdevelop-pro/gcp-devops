COMPANY_NAME=webdevelop-pro
SERVICE_NAME=go-common

build() {
  go build -ldflags "-s -w -X main.repository=${REPOSITORY} -X main.revisionID=${GIT_COMMIT} -X main.version=${BUILD_DATE}:${GIT_COMMIT} -X main.service=${SERVICE_NAME}" -o ./app ./*.go && chmod +x ./app
}

case $1 in

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

*)
  BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
  GIT_COMMIT=`git rev-parse --short HEAD`
  echo $BRANCH_NAME, $GIT_COMMIT
  docker build -t cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:$GIT_COMMIT -t cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:latest-dev --platform=linux/amd64 .
  snyk container test cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:$GIT_COMMIT
  if [ $? -ne 0 ]; then
    echo "===================="
    echo "snyk has found a vulnerabilities, please consider choosing alternative image from snyk"
    echo "===================="
  fi
  docker push cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:$GIT_COMMIT
  docker push cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:latest-dev
  ;;

esac

