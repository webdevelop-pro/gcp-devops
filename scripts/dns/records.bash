#!/usr/bin/env bash

function create_dns_record()
{
  _DOMAIN_RECORD=$1

  _CURRENT_DOMAIN=$(gcloud dns record-sets list --zone ${DNS_ZONE_NAME} --format json | jq ".[] | select(.name==\"${_DOMAIN_RECORD}.\")")
  _IP=$(gcloud compute addresses describe --global --format json ${STATIC_IP_NAME} | jq '.address' | tr -d '"')

  if [[ ${_CURRENT_DOMAIN} == "" ]]
  then
    rm /tmp/transaction.yaml

    gcloud dns record-sets transaction start --zone=${DNS_ZONE_NAME} --transaction-file=/tmp/transaction.yaml

    gcloud dns record-sets transaction add ${_IP} \
      --name=${_DOMAIN_RECORD} \
      --type=A \
      --ttl 300 \
      --zone=${DNS_ZONE_NAME} \
      --transaction-file=/tmp/transaction.yaml

    gcloud dns record-sets transaction execute --zone=${DNS_ZONE_NAME} --transaction-file=/tmp/transaction.yaml
  else
    gcloud dns record-sets update ${_DOMAIN_RECORD} \
      --rrdatas ${_IP} \
      --type=A \
      --zone ${DNS_ZONE_NAME}
  fi
}