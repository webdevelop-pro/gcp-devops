#!/usr/bin/env bash

function create_static_ip()
{
    gcloud compute addresses create ${STATIC_IP_NAME} \
      --network-tier=PREMIUM \
      --ip-version=IPV4 \
      --global
}
