#!/usr/bin/env bash

HTTPS_LB_NAME="apps-https-lb"

function create_backend_bucket_lb() {
  SERVICE_NAME=$1
  DOMAIN_RECORD=$2
  BUCKET_NAME=$3
  PATH_NAME_PREFIX=$4
  MAIN_PAGE=$5
  ERROR_PAGE=$6

  if [[ ${MAIN_PAGE} == "" ]]; then
    MAIN_PAGE="index.html"
  fi

  if [[ ${ERROR_PAGE} == "" ]]; then
    ERROR_PAGE="index.html"
  fi

  BACKEND_BUCKET_NAME="${SERVICE_NAME}-${env_name}-backend-bucket"
  PATH_MATCHER_NAME="${PATH_NAME_PREFIX}${env_name}-${SERVICE_NAME}-matcher"

  gsutil mb -p ${env_project_id} -l ${env_project_buckets_location} -c standard -b on gs://${BUCKET_NAME}

  gsutil web set -m ${MAIN_PAGE} -e ${ERROR_PAGE} gs://${BUCKET_NAME}

  gsutil iam ch allUsers:objectViewer gs://${BUCKET_NAME}

  gcloud compute backend-buckets create ${BACKEND_BUCKET_NAME} \
      --project ${env_project_id} \
      --gcs-bucket-name=${BUCKET_NAME} \
      --enable-cdn

  gcloud compute url-maps add-path-matcher ${HTTPS_LB_NAME} \
    --project ${env_project_id} \
    --path-matcher-name=${PATH_MATCHER_NAME} \
    --new-hosts=${DOMAIN_RECORD} \
    --default-backend-bucket=${BACKEND_BUCKET_NAME}
}

function disable_cdn()
{
    SERVICE_NAME=$1
    BACKEND_BUCKET_NAME="${SERVICE_NAME}-${env_name}-backend-bucket"

    gcloud compute backend-buckets update ${BACKEND_BUCKET_NAME} \
        --project ${env_project_id} \
        --no-enable-cdn
}

function delete_files_after_30_days() {
  BUCKET_NAME=$1
  gsutil lifecycle set ./core/scripts/buckets/delete-files-30-days.json gs://$BUCKET_NAME
}

