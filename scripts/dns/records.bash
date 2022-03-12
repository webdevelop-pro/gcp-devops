#!/usr/bin/env bash

DNS_ZONE_NAME=$(echo "${env_project_domain}" | tr -d '.-_')

function create_dns_record()
{
  _DOMAIN_RECORD=$1
  _IP=$2
  _TYPE=$3
  _TTL=$

  if [[ ${_TYPE} == "" ]]; than
    _TYPE="A"
  fi

  if [[ ${_TTL} == "" ]]; than
    _TTL=300
  fi

  _CURRENT_DOMAIN=$(gcloud dns record-sets list --project ${env_project_id} --zone ${DNS_ZONE_NAME} --format json | jq ".[] | select(.name==\"${_DOMAIN_RECORD}.\")")

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
      --type=${_TYPE} \
      --ttl=${_TTL} \
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
      --type=${_TYPE} \
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
