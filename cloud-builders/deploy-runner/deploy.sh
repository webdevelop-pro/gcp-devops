#!/bin/sh
set -xv

cp ../../requirements.txt requirements.txt
cp ../../yq_install.sh yq_install.sh

ARCH="$(uname -p)"
DATE_DDMMYYYY="$(date +%d%m%Y)"

IMAGE_TAG="${1:-$DATE_DDMMYYYY}"
IMAGE_NAME=cr.webdevelop.us/webdevelop-pro/deploy-runner:$IMAGE_TAG

echo $IMAGE_NAME

if [ "$ARCH" == "arm" ]; then
    echo "Building docker image under Mac OS X platform"
    docker buildx build --platform linux/amd64 -t $IMAGE_NAME --push .
else 
    echo "Build an image from a Dockerfile"
    docker build -t $IMAGE_NAME .
    docker push $IMAGE_NAME
fi
