#!/usr/bin/env bash

REDIRECT_NAME="apps-https-redirect"
HTTPS_LB_NAME="apps-https-lb"
STATIC_IP_NAME="public-frontend-ip"
PROXY_NAME="https-lb-proxy"
CERTIFICATE_NAME="frontend-certificate"
LB_RULE_NAME="https-lb-rule"
PROJECT_NAME="${env_project_id}"

function create_https_lb()
{
  export DEFAULT_BACKEND_BUCKET_NAME="${PROJECT_NAME}-default-backend"
  export DEFAULT_BUCKET_NAME=${PROJECT_NAME}-${env_name}-default

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
