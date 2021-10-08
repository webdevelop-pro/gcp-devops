#!/usr/bin/env bash

function create_https_lb()
{
  export DEFAULT_BACKEND_BUCKET_NAME="${PROJECT_NAME}-default-backend"
  export DEFAULT_BUCKET_NAME=${PROJECT_NAME}-default

  gsutil mb -p ${PROJECT_ID} -c standard -b on gs://${DEFAULT_BUCKET_NAME}

  gcloud compute backend-buckets create ${DEFAULT_BACKEND_BUCKET_NAME} \
      --gcs-bucket-name=${DEFAULT_BUCKET_NAME}

  gcloud compute url-maps create ${HTTPS_LB_NAME} \
      --default-backend-bucket=${DEFAULT_BACKEND_BUCKET_NAME}

  gcloud compute target-https-proxies create ${PROXY_NAME} \
    --url-map=${HTTPS_LB_NAME} \
    --ssl-certificates=${CERTIFICATE_NAME}

  gcloud compute forwarding-rules create ${LB_RULE_NAME} \
      --address=${STATIC_IP_NAME} \
      --global \
      --target-https-proxy=${PROXY_NAME} \
      --ports=443
}
