#!/usr/bin/env bash

BASE_PATH=$(dirname "$0")

function create_certificate()
{
  DOMAINS="$1"

  gcloud compute ssl-certificates create ${CERTIFICATE_NAME} \
      --domains ${DOMAINS} \
      --global

  STATUS="PROVISIONING"
  while [[ ${STATUS} != "ACTIVE" ]]; do
    STATUS=$(gcloud compute ssl-certificates describe ${CERTIFICATE_NAME}-tmp --format json | jq '.managed.status')
    echo "Craete certificate ${CERTIFICATE_NAME}-tmp, status - ${STATUS}"
    sleep 10s
  done
}

function create_tmp_certificate()
{
  DOMAINS="$1"

  gcloud compute ssl-certificates create ${CERTIFICATE_NAME}-tmp \
      --domains ${DOMAINS} \
      --global

  gcloud compute target-https-proxies update ${PROXY_NAME} \
    --ssl-certificates="${CERTIFICATE_NAME}-tmp,${CERTIFICATE_NAME}"

  STATUS="PROVISIONING"
  while [[ ${STATUS} != "ACTIVE" ]]; do
    STATUS=$(gcloud compute ssl-certificates describe ${CERTIFICATE_NAME}-tmp --format json | jq '.managed.status')
    echo "Craete certificate ${CERTIFICATE_NAME}-tmp, status - ${STATUS}"
    sleep 10s
  done
}

function delete_tmp_certificate()
{
  gcloud compute target-https-proxies update ${PROXY_NAME} \
    --ssl-certificates="${CERTIFICATE_NAME}"

  gcloud compute ssl-certificates delete ${CERTIFICATE_NAME}-tmp
}

function delete_certificate()
{
  gcloud compute target-https-proxies update ${PROXY_NAME} \
    --ssl-certificates="${CERTIFICATE_NAME}-tmp"

  gcloud compute ssl-certificates delete ${CERTIFICATE_NAME}
}

function create_domains_list()
{
  DOMAINS=""
  for FILE_NAME in $(ls -1 ${BASE_PATH}/../backend-buckets)
  do
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

    DOMAINS+="${DOMAIN_RECORD},"
  done
}

function main()
{
  create_domains_list

  echo "Start create certificates for:"
  echo "${DOMAINS}"

  create_tmp_certificate ${DOMAINS}

  delete_certificate

  create_certificate ${DOMAINS}

  delete_tmp_certificate
}

main
