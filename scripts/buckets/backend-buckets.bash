#!/usr/bin/env bash

function create_bucket_lb() {
  SERVICE_NAME=$1
  DOMAIN_RECORD=$2

  BACKEND_BUCKET_NAME="${SERVICE_NAME}-${ENV_NAME}-backend-bucket"
  BUCKET_NAME="${PROJECT_NAME}-${ENV_NAME}-${SERVICE_NAME}"
  PATH_MATCHER_NAME="${ENV_NAME}-${SERVICE_NAME}-matcher"

  gsutil mb -p ${PROJECT_ID} -c standard -b on gs://${BUCKET_NAME}

  gcloud compute backend-buckets create ${BACKEND_BUCKET_NAME} \
      --gcs-bucket-name=${BUCKET_NAME}

  gcloud compute url-maps add-path-matcher ${HTTPS_LB_NAME} \
    --path-matcher-name=${PATH_MATCHER_NAME} \
    --new-hosts=${DOMAIN_RECORD} \
    --default-backend-bucket=${BACKEND_BUCKET_NAME}
}

function main()
{
    FILE_NAME=$(basename $0)
    SERVICE_NAME="${FILE_NAME%.*}"

    if [[ $ENV_NAME == "master" ]]
    then
        if [[ $SERVICE_NAME == "home"  ]]
        then
            export DOMAIN_RECORD="${DOMAIN}"
        else
            export DOMAIN_RECORD="${SERVICE_NAME}.${DOMAIN}"
        fi
    else
        export DOMAIN_RECORD="${SERVICE_NAME}-${ENV_NAME}.${DOMAIN}"
    fi

    create_bucket_lb $SERVICE_NAME $DOMAIN_RECORD
}

main $@
