#!/usr/bin/env bash

function create_backend_bucket_lb() {
  SERVICE_NAME=$1
  DOMAIN_RECORD=$2
  BACKEND_BUCKET_NAME="${SERVICE_NAME}-${ENV_NAME}-backend-bucket"

  BUCKET_NAME="${PROJECT_NAME}-${ENV_NAME}-${SERVICE_NAME}"
  PATH_MATCHER_NAME="${ENV_NAME}-${SERVICE_NAME}-matcher"

  gsutil mb -p ${PROJECT_ID} -l ${BUCKETS_LOCATION} -c standard -b on gs://${BUCKET_NAME}

  gcloud compute backend-buckets create ${BACKEND_BUCKET_NAME} \
      --gcs-bucket-name=${BUCKET_NAME} \
      --enable-cdn

  gcloud compute url-maps add-path-matcher ${HTTPS_LB_NAME} \
    --path-matcher-name=${PATH_MATCHER_NAME} \
    --new-hosts=${DOMAIN_RECORD} \
    --default-backend-bucket=${BACKEND_BUCKET_NAME}
}

function disable_cdn()
{
    SERVICE_NAME=$1
    BACKEND_BUCKET_NAME="${SERVICE_NAME}-${ENV_NAME}-backend-bucket"

    gcloud compute backend-buckets update ${BACKEND_BUCKET_NAME} \
        --no-enable-cdn
}
