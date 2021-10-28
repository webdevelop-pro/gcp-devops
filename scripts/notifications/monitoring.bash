#!/usr/bin/env bash

BASE_PATH=$(dirname "$0")/../../core

FUNCTION="monitoring-notifications"
TOPIC="monitoring"
NOTIFICATION_CHANNEL="monitoring-to-pubsub"

function recreate_monitoring_pubsub_channel()
{
    PROJECT_NUMBER=$(gcloud projects describe ${env_project_id} --format json | jq '.projectNumber' | tr -d '"')
    CHANNEL_ID=$(gcloud --project ${env_project_id} alpha monitoring channels list --format json --filter='displayName="monitoring-to-pubsub"' | jq '.[0].name' | tr -d '"')

    gcloud pubsub topics create --project ${env_project_id} ${TOPIC}

    if [[ ${CHANNEL_ID} != "null" ]]; then
        echo "Recreate channel"

        gcloud --project ${env_project_id} alpha monitoring channels delete ${CHANNEL_ID}
    fi

    gcloud --project ${env_project_id} alpha monitoring channels create --display-name="${NOTIFICATION_CHANNEL}" --type="pubsub"  --channel-labels="topic=projects/${env_project_id}/topics/${TOPIC}"

    gcloud pubsub topics add-iam-policy-binding \
        projects/${PROJECT_NUMBER}/topics/${TOPIC} --role=roles/pubsub.publisher \
        --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-monitoring-notification.iam.gserviceaccount.com
}

# Create new policies
function delete_monitoring_policies()
{
    for ID in $(echo $(gcloud alpha --project ${env_project_id} monitoring policies list --format json | jq '.[] | .name' | tr -d '"'))
    do
        gcloud alpha --project ${env_project_id} monitoring policies delete ${ID}
    done
}

function create_monitoring_policies()
{
    CHANNEL_ID=$(gcloud --project ${env_project_id} alpha monitoring channels list --format json --filter='displayName="monitoring-to-pubsub"' | jq '.[0].name'  | tr -d '"')

    for FILE in $(ls ${BASE_PATH}/monitoring)
    do
        gcloud alpha --project ${env_project_id} monitoring policies create --notification-channels="${CHANNEL_ID}" --policy-from-file=${BASE_PATH}/monitoring/$FILE
    done
}

function create_monitoring_cloudfunc()
{
    MAIN_FUNC="MonitoringSubscribe"

    cat > /tmp/monitoring.env << EOF
SLACK_TOKEN: ${env_slack_bot_token}
CHANNELS: '${env_monitoring_notifications}'
EOF

  gcloud functions deploy monitoring-notifications \
     --project ${env_project_id} \
     --runtime go116 \
     --trigger-topic ${TOPIC} \
     --allow-unauthenticated \
     --entry-point=${MAIN_FUNC} \
     --source=${BASE_PATH}/cloud-func/notifications \
     --env-vars-file=/tmp/monitoring.env
}
