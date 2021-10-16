#!/usr/bin/env bash

STATIC_IP_NAME="public-frontend-ip"

function create_static_ip()
{
    gcloud compute addresses create ${STATIC_IP_NAME} \
      --project ${env_project_id} \
      --network-tier=PREMIUM \
      --ip-version=IPV4 \
      --global
}
