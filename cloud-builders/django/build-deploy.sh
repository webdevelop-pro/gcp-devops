COMPANY_NAME=webdevelop-pro
SERVICE_NAME=django
case $1 in

run)
  GIT_COMMIT=$(git rev-parse --short HEAD)
  BUILD_DATE=$(date "+%Y%m%d")
  python -m http.server
  ;;

audit)
  echo "running bandit"
  bandit --exclude ./venv -ll -r ./
  if [ $? -ne 0 ]; then
    exit 1
  fi
  ;;

*)
  BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
  GIT_COMMIT=`git rev-parse --short HEAD`
  echo $BRANCH_NAME, $GIT_COMMIT
  docker build -t cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:$GIT_COMMIT -t cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:latest-dev -t webdeveloppro/$SERVICE_NAME:$GIT_COMMIT -t webdeveloppro/$SERVICE_NAME:latest-dev --platform=linux/amd64 .
  snyk container test cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:$GIT_COMMIT
  if [ $? -ne 0 ]; then
    echo "===================="
    echo "snyk has found a vulnerabilities, please consider choosing alternative image from snyk"
    echo "===================="
  fi
  docker push cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:$GIT_COMMIT
  docker push cr.webdevelop.us/$COMPANY_NAME/$SERVICE_NAME:latest-dev
  docker push webdeveloppro/$SERVICE_NAME:$GIT_COMMIT
  docker push webdeveloppro/$SERVICE_NAME:latest-dev
  ;;

esac

