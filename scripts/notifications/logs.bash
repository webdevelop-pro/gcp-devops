#!/usr/bin/env bash

BASE_PATH=$(dirname "$0")/../../core
TOPIC="logs-errors"

function create_logs_cloudfunc()
{
    MAIN_FUNC="LogsSubscribe"
    FUNCTION_NAME="logs-notifications"

    cat > /tmp/logs.env << EOF
SLACK_TOKEN: ${env_slack_bot_token}
CHANNELS: '${env_logs_notifications}'
EOF

  gcloud functions deploy ${FUNCTION_NAME} \
     --project ${env_project_id} \
     --runtime go116 \
     --trigger-topic ${TOPIC} \
     --allow-unauthenticated \
     --entry-point=${MAIN_FUNC} \
     --source=${BASE_PATH}/cloud-func/notifications \
     --env-vars-file=/tmp/logs.env
}

function create_logs_router()
{
  PROJECT_NUMBER=$(gcloud projects describe ${env_project_id} --format json | jq '.projectNumber' | tr -d '"')

  gcloud pubsub topics create --project ${env_project_id} ${TOPIC}

  gcloud  --project ${env_project_id} logging sinks create log-errors \
     "pubsub.googleapis.com/projects/${env_project_id}/topics/${TOPIC}" \
     --log-filter='labels."k8s-pod/logsNotifications" = "true" severity=(ERROR OR CRITICAL OR ALERT OR EMERGENCY) resource.labels.container_name!="cloudsql-proxy"'

  WRITER_IDENTITY=$(gcloud  --project ${env_project_id} logging sinks describe log-errors --format json | jq '.writerIdentity' | tr -d '"')

  gcloud pubsub topics add-iam-policy-binding \
    projects/${PROJECT_NUMBER}/topics/${TOPIC} --role=roles/pubsub.publisher \
    --member=${WRITER_IDENTITY}

}
