#!/usr/bin/env bash

PROXY_NAME="https-lb-proxy"
CERTIFICATE_NAME="$(echo ${env_project_domain} | tr -d '.')"

function create_certificate()
{
    CERTIFICATE_DIR=$1

    gcloud compute ssl-certificates create ${CERTIFICATE_NAME} \
        --project ${env_project_id} \
        --certificate=${CERTIFICATE_DIR}/ca.crt \
        --private-key=${CERTIFICATE_DIR}/key.crt \
        --global

    gcloud compute target-https-proxies update ${PROXY_NAME} \
        --project ${env_project_id} \
        --ssl-certificates="${CERTIFICATE_NAME}"
}
