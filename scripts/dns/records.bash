#!/usr/bin/env bash

DNS_ZONE_NAME=$(echo "${env_project_domain}" | tr -d '.-_')
STATIC_IP_NAME="public-frontend-ip"

function create_dns_record()
{
  _DOMAIN_RECORD=$1

  _CURRENT_DOMAIN=$(gcloud dns record-sets list --project ${env_project_id} --zone ${DNS_ZONE_NAME} --format json | jq ".[] | select(.name==\"${_DOMAIN_RECORD}.\")")
  _IP=$(gcloud compute addresses describe --global --project ${env_project_id} --format json ${STATIC_IP_NAME} | jq '.address' | tr -d '"')

  if [[ ${_CURRENT_DOMAIN} == "" ]]
  then
    rm /tmp/transaction.yaml

    gcloud dns record-sets transaction start \
      --project ${env_project_id} \
      --zone=${DNS_ZONE_NAME} \
      --transaction-file=/tmp/transaction.yaml

    gcloud dns record-sets transaction add ${_IP} \
      --project ${env_project_id} \
      --name=${_DOMAIN_RECORD} \
      --type=A \
      --ttl 300 \
      --zone=${DNS_ZONE_NAME} \
      --transaction-file=/tmp/transaction.yaml

    gcloud dns record-sets transaction execute \
      --project ${env_project_id} \
      --zone=${DNS_ZONE_NAME} \
      --transaction-file=/tmp/transaction.yaml
  else
    gcloud dns record-sets update ${_DOMAIN_RECORD} \
      --project ${env_project_id} \
      --rrdatas ${_IP} \
      --type=A \
      --zone ${DNS_ZONE_NAME}
  fi
}

function create_dns_zone()
{
  gcloud dns managed-zones create ${DNS_ZONE_NAME} \
    --project ${env_project_id} \
    --dns-name "${env_project_domain}." \
    --description "${env_project_domain} dns zone"
}
