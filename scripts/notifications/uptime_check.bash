#!/usr/bin/env bash

BASE_PATH=$(dirname "$0")/../../../../core

function create_uptime()
{
    NAME=$1
    HOST=$2
    URL_PATH=$3
    GROUP=$4
    TEMPLATE_PATH=${BASE_PATH}/etc/uptime.jinja
    UPTIME_DEPLOYMENT_NAME="${NAME}-${env_name}-${GROUP}-uptimecheck"

    yes | gcloud --project ${env_project_id} deployment-manager deployments delete ${UPTIME_DEPLOYMENT_NAME}

    cp ${TEMPLATE_PATH} /tmp/uptime.jinja

    cat > /tmp/${UPTIME_DEPLOYMENT_NAME}.yaml << EOF
      imports:
        - path: /tmp/uptime.jinja
      resources:
        - name: create_uptimechecks
          type: /tmp/uptime.jinja
          properties:
            uptimechecks:
              - name: "${UPTIME_DEPLOYMENT_NAME}"
                period: "60s"
                timeout: "5s"
                monitoredResource:
                  type: "uptime_url"
                  labels:
                    project_id: ${env_project_id}
                    host: "${HOST}"
                httpCheck:
                  useSsl: true
                  validateSsl: true
                  path: "${URL_PATH}"
                  port: 443
EOF

    gcloud --project ${env_project_id} deployment-manager deployments create ${UPTIME_DEPLOYMENT_NAME} --config /tmp/${UPTIME_DEPLOYMENT_NAME}.yaml
}
