#!/usr/bin/env bash

REDIRECT_NAME="apps-https-redirect"
HTTP_LB_NAME="apps-http-lb"
STATIC_IP_NAME="public-frontend-ip"

function create_http_to_https_redirect()
{
  echo "
kind: compute#urlMap
name: ${REDIRECT_NAME}
defaultUrlRedirect:
   redirectResponseCode: MOVED_PERMANENTLY_DEFAULT
   httpsRedirect: True
" > /tmp/http-to-https.yaml

  gcloud compute url-maps import ${REDIRECT_NAME} \
   --project ${env_project_id} \
   --source /tmp/http-to-https.yaml \
   --global

  gcloud compute target-http-proxies create ${HTTP_LB_NAME} \
   --project ${env_project_id} \
   --url-map=${REDIRECT_NAME} \
   --global

  gcloud compute forwarding-rules create ${HTTP_LB_NAME}-rule \
   --project ${env_project_id} \
   --address=${STATIC_IP_NAME} \
   --global \
   --target-http-proxy=${HTTP_LB_NAME} \
   --ports=80
}
