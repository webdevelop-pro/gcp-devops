#!/usr/bin/env sh
set -xe

# system functions
basename() {
    # Usage: basename "path" ["suffix"]
    local tmp
    tmp=${1%"${1##*[!/]}"}
    tmp=${tmp##*/}
    tmp=${tmp%'${2/"$tmp"}'}
    printf '%s\n' "${tmp:-/}"
}

lstrip() {
    # Usage: lstrip "string" "pattern"
    printf '%s\n' "${1##$2}"
}

WORK_DIR=$(pwd)
# if company name not set - try to get it from the path
if [ -z "${COMPANY_NAME}" ]; then
  COMPANY_NAME=$(lstrip $(basename `cd ..; pwd`) "pro")
else
  COMPANY_NAME="${COMPANY_NAME}"
fi

# if service name not set - try to get it from the path
if [ -z "${SERVICE_NAME}" ]; then
  SERVICE_NAME=$(lstrip $(basename $(pwd)) "i-")
else
  SERVICE_NAME="${SERVICE_NAME}"
fi


REPOSITORY=$COMPANY_NAME/$SERVICE_NAME

self_update() {
  [ ! -d "etc/" ] && mkdir etc;
  docker pull cr.webdevelop.us/webdevelop-pro/python-common:latest-dev;
  docker rm -f makesh;
  docker run --name=makesh cr.webdevelop.us/webdevelop-pro/python-common:latest-dev sh &&
  docker cp makesh:/app/etc/make.sh make.sh;
  docker cp makesh:/app/etc/ruff.toml .ruff.toml;
  docker cp makesh:/app/etc/pre-commit etc/pre-commit;
  docker stop makesh;
}

case $1 in

install)
  echo "Creating virtual envoiroment into venv folder"
  python3 -m venv venv
  . venv/bin/activate
  echo "Installing requirements"
  pip install --upgrade pip
  pip install -r requirements.txt
  pip install -r requirements-dev.txt

  echo "set up pre-commit hook and make.sh file"
  self_update;

  if [ -d ".git" -a -d ".git/hooks" ]
  then
    rm .git/hooks/pre-commit 2>/dev/null || echo 'ok' # ignore error to let sh continue
    ln -s ../../etc/pre-commit .git/hooks/pre-commit
  fi
  ;;

lint)
  ruff check app/ tests/ $2 $3
  ;;

test)
  case $2 in
  unit)
    python -m pytest -vv -s tests/unit/*.py $3 $4 
    ;;

  e2e)
    python -m pytest -vv -s tests/e2e/*.py $3 $4 
    ;;
  *)
    python -m pytest -vv -s tests/**/*.py $2 $3 
    ;;

    esac
  ;;

self-update)
  docker rm -f makesh;
  self_update;
  ;;

run-dev)
  nodemon -u -w app -e py --exec python app/__main__.py
  ;;

run)
  python -u -m app
  ;;

audit)
  bandit --exclude ./venv -ll -r ./
  if [ $? -ne 0 ]; then
    exit 1
  fi
  ;;

swag-doc)
  # docs - https://goswagger.io/use/spec/route.html
  swagger generate spec --scan-models -o swagger.json
  ;;

deploy-dev)
  BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
  GIT_COMMIT=`git rev-parse --short HEAD`
  echo $BRANCH_NAME, $GIT_COMMIT
  docker build -t cr.webdevelop.us/$REPOSITORY:$GIT_COMMIT -t cr.webdevelop.us/$REPOSITORY:latest-dev --platform=linux/amd64 .
  snyk container test cr.webdevelop.us/$REPOSITORY:$GIT_COMMIT
  if [ $? -ne 0 ]; then
    echo "===================="
    echo "snyk has found a vulnerabilities, please consider choosing alternative image from snyk"
    echo "===================="
  fi
  docker push cr.webdevelop.us/$REPOSITORY:$GIT_COMMIT
  docker push cr.webdevelop.us/$REPOSITORY:latest-dev
  kubectl -n $COMPANY_NAME-dev set image deployment/$SERVICE_NAME $SERVICE_NAME=cr.webdevelop.us/$REPOSITORY:$GIT_COMMIT
  ;;

help)
  cat make.sh | grep "^[a-z-]*)"
  ;;

*)
  echo "unknown $1, try help"
  ;;

esac
