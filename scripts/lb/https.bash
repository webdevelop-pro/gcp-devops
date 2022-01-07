#!/usr/bin/env bash

REDIRECT_NAME="apps-https-redirect"
HTTPS_LB_NAME="apps-https-lb"
STATIC_IP_NAME="public-frontend-ip"
PROXY_NAME="https-lb-proxy"
CERTIFICATE_NAME="$(echo ${env_project_domain} | tr -d '.')"
LB_RULE_NAME="https-lb-rule"
PROJECT_NAME="${env_project_id}"

function create_https_lb()
{
  DEFAULT_BACKEND_BUCKET_NAME="${PROJECT_NAME}-default-backend"
  DEFAULT_BUCKET_NAME=${PROJECT_NAME}-${env_name}-default

  gsutil mb -p ${env_project_id} -c standard -b on gs://${DEFAULT_BUCKET_NAME}

  gcloud compute backend-buckets create ${DEFAULT_BACKEND_BUCKET_NAME} \
      --project ${env_project_id} \
      --gcs-bucket-name=${DEFAULT_BUCKET_NAME}

  gcloud compute url-maps create ${HTTPS_LB_NAME} \
      --project ${env_project_id} \
      --default-backend-bucket=${DEFAULT_BACKEND_BUCKET_NAME}

  gcloud compute target-https-proxies create ${PROXY_NAME} \
    --project ${env_project_id} \
    --url-map=${HTTPS_LB_NAME} \
    --ssl-certificates=${CERTIFICATE_NAME}

  gcloud compute forwarding-rules create ${LB_RULE_NAME} \
      --project ${env_project_id} \
      --address=${STATIC_IP_NAME} \
      --global \
      --target-https-proxy=${PROXY_NAME} \
      --ports=443
}

function create_backend_service()
{
  gcloud container clusters get-credentials ${env_k8s_cluster_name} --zone ${env_k8s_nodes_region} --project ${env_project_id}

  BACKEND_ENDPOINT_GROUP="ingress-${env_name}"
  BACKEND_IP="$(kubectl -n ingress-nginx get svc --template '{{ (index (index .items 0).status.loadBalancer.ingress 0).ip }}')"
  BACKEND_PORT=80
  BACKEND_SERVICE="${PROJECT_NAME}-service-backend"
  PATH_MATCHER_NAME="${env_name}-backend-matcher"

  gcloud compute network-endpoint-groups create ${BACKEND_ENDPOINT_GROUP} \
    --project ${env_project_id} \
    --network-endpoint-type=internet-ip-port \
    --global

  gcloud compute network-endpoint-groups update ${BACKEND_ENDPOINT_GROUP} \
    --project ${env_project_id} \
    --global \
    --add-endpoint="ip=${BACKEND_IP},port=${BACKEND_PORT}"

  gcloud compute backend-services create ${BACKEND_SERVICE} \
    --project ${env_project_id} \
    --global

  gcloud compute backend-services add-backend ${BACKEND_SERVICE} \
    --project ${env_project_id} \
    --global-network-endpoint-group \
    --global \
    --network-endpoint-group=${BACKEND_ENDPOINT_GROUP}

  gcloud compute url-maps add-path-matcher ${HTTPS_LB_NAME} \
    --project ${env_project_id} \
    --path-matcher-name=${PATH_MATCHER_NAME} \
    --new-hosts="*-api-${env_name}.${env_project_domain}" \
    --global \
    --default-service=${BACKEND_SERVICE}
}
