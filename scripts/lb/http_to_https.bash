#!/usr/bin/env bash

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
   --source /tmp/http-to-https.yaml \
   --global

  gcloud compute target-http-proxies create ${HTTP_LB_NAME} \
   --url-map=${REDIRECT_NAME} \
   --global

  gcloud compute forwarding-rules create ${HTTP_LB_NAME}-rule \
   --address=${STATIC_IP_NAME} \
   --global \
   --target-http-proxy=${HTTP_LB_NAME} \
   --ports=80
}
