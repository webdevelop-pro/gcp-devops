#!/usr/bin/env bash

DNS_ZONE_NAME=$(echo "${env_project_domain}" | tr -d '.-_')

function create_dns_record()
{
  _TYPE=$1
  _DOMAIN_RECORD=$2
  _IP=$3
  _TTL=$4

  echo "Create DNS record: ${_TYPE} ${_DOMAIN_RECORD} ${_IP} ${_TTL}"

  if [[ ${_TTL} == "" ]]; then
    _TTL=300
  fi

  _CURRENT_DOMAIN=$(gcloud dns record-sets list --project ${env_project_id} --zone ${DNS_ZONE_NAME} --format json | jq ".[] | select(.name==\"${_DOMAIN_RECORD}.\") | select(.type==\"${_TYPE}\")")

  if [[ ${_CURRENT_DOMAIN} == "" ]]
  then
    rm /tmp/transaction.yaml

    gcloud dns record-sets transaction start \
      --project ${env_project_id} \
      --zone=${DNS_ZONE_NAME} \
      --transaction-file=/tmp/transaction.yaml

    gcloud dns record-sets transaction add \
      --project ${env_project_id} \
      --name=${_DOMAIN_RECORD} \
      --type=${_TYPE} \
      --ttl=${_TTL} \
      --zone=${DNS_ZONE_NAME} \
      --transaction-file=/tmp/transaction.yaml \
      -- "${_IP}"

    gcloud dns record-sets transaction execute \
      --project ${env_project_id} \
      --zone=${DNS_ZONE_NAME} \
      --transaction-file=/tmp/transaction.yaml

    # For multiline CNAME, please don't remove this =)
    gcloud dns record-sets update ${_DOMAIN_RECORD} \
      --project ${env_project_id} \
      --rrdatas "${_IP}" \
      --type=${_TYPE} \
      --zone ${DNS_ZONE_NAME}
  else
    gcloud dns record-sets update ${_DOMAIN_RECORD} \
      --project ${env_project_id} \
      --rrdatas "${_IP}" \
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
