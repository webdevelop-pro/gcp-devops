#!/usr/bin/env bash

function create_certificate()
{
    CERTIFICATE_DIR=$1

    gcloud compute ssl-certificates create ${CERTIFICATE_NAME} \
        --certificate=${CERTIFICATE_DIR}/ca.crt \
        --private-key=${CERTIFICATE_DIR}/key.crt \
        --global

    gcloud compute target-https-proxies update ${PROXY_NAME} \
        --ssl-certificates="${CERTIFICATE_NAME}"
}
