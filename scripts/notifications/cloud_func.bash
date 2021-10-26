#!/usr/bin/env bash

BASE_PATH=$(dirname "$0")
function craete_cloudbuild_notification()
{

cat > /tmp/cloudbuild.env << EOF
SLACK_TOKEN: ${env_slack_bot_token}
GIT_REPO_OWNER: ${env_github_repo_owner}
GITHUB_ACCESS_TOKEN: ${env_github_access_token}
CHANNELS: ${env_build_notifications}
EOF

  gcloud functions deploy build-notifications \
     --project ${env_project_id} \
     --runtime go116 \
     --trigger-topic cloud-builds \
     --allow-unauthenticated \
     --entry-point=CloudBuildSubscribe \
     --source=${BASE_PATH}/../../core/cloud-func/notifications \
     --env-vars-file=/tmp/cloudbuild.env
}
