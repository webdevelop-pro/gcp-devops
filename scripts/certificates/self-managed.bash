#!/usr/bin/env bash

function create_certificate()
{
    CERTIFICATE_DIR=$1

    echo gcloud compute ssl-certificates create ${CERTIFICATE_NAME} \
        --certificate=${CERTIFICATE_DIR}/ca.crt \
        --private-key=${CERTIFICATE_DIR}/key.crt \
        --global
}
