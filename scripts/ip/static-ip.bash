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


function get_frontend_ip()
{
  echo $(gcloud compute addresses describe --global --project ${env_project_id} --format json ${STATIC_IP_NAME} | jq '.address' | tr -d '"')
}

function get_backend_ip()
{
  gcloud container clusters get-credentials ${env_k8s_cluster_name} --zone ${env_k8s_nodes_region} --project ${env_project_id}

  echo $(kubectl -n ingress-nginx get svc --template '{{ (index (index .items 0).status.loadBalancer.ingress 0).ip }}')
}
