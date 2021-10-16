#!/usr/bin/env bash

BASE_PATH=$(dirname "$0")

CERTIFICATE_NAME="frontend-certificate"
PROXY_NAME="https-lb-proxy"

function create_gcp_certificate()
{
  DOMAINS="$1"

  gcloud compute ssl-certificates create ${CERTIFICATE_NAME} \
      --project ${env_project_id} \
      --domains ${DOMAINS} \
      --global
}

function create_tmp_certificate()
{
  DOMAINS="$1"

  gcloud compute ssl-certificates create ${CERTIFICATE_NAME}-tmp \
      --project ${env_project_id} \
      --domains ${DOMAINS} \
      --global

  gcloud compute target-https-proxies update ${PROXY_NAME} \
    --project ${env_project_id} \
    --ssl-certificates="${CERTIFICATE_NAME}-tmp,${CERTIFICATE_NAME}"

  STATUS="PROVISIONING"
  while [[ ${STATUS} != "ACTIVE" ]]; do
    STATUS=$(gcloud compute ssl-certificates describe ${CERTIFICATE_NAME}-tmp --project ${env_project_id} --format json | jq '.managed.status')
    echo "Craete certificate ${CERTIFICATE_NAME}-tmp, status - ${STATUS}"
    sleep 10s
  done
}

function delete_tmp_certificate()
{
  gcloud compute target-https-proxies update ${PROXY_NAME} \
    --project ${env_project_id} \
    --ssl-certificates="${CERTIFICATE_NAME}"

  gcloud compute ssl-certificates delete ${CERTIFICATE_NAME}-tmp --project ${env_project_id}
}

function delete_certificate()
{
  gcloud compute target-https-proxies update ${PROXY_NAME} \
    --project ${env_project_id} \
    --ssl-certificates="${CERTIFICATE_NAME}-tmp"

  gcloud compute ssl-certificates delete ${CERTIFICATE_NAME} --project ${env_project_id}
}

function create_domains_list()
{
  DOMAINS=""
  for FILE_NAME in $(find ${BASE_PATH}/../buckets -maxdepth 1 -type f)
  do
    FILE_NAME=$(basename ${FILE_NAME})
    SERVICE_NAME="${FILE_NAME%.*}"

    if [[ ${env_name} == "master" ]]
    then
      export DOMAIN_RECORD="${SERVICE_NAME}.${env_project_domain}"
    else
      export DOMAIN_RECORD="${SERVICE_NAME}-${env_name}.${env_project_domain}"
    fi

    DOMAINS+="${DOMAIN_RECORD},"
  done
}

function update_certificate()
{
  create_domains_list

  echo "Start create certificates for:"
  echo "${DOMAINS}"

  create_tmp_certificate ${DOMAINS}

  delete_certificate

  create_gcp_certificate ${DOMAINS}

  delete_tmp_certificate
}

function create_certificate()
{
  create_domains_list

  echo "Start create certificates for:"
  echo "${DOMAINS}"

  delete_certificate

  create_gcp_certificate ${DOMAINS}
}
