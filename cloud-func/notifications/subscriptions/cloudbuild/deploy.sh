gcloud --project ${PROJECT_ID} functions deploy build-notifications \
    --runtime go116 \
    --trigger-topic cloud-builds \
    --allow-unauthenticated \
    --entry-point BuildNotification \
    --source=./ \
    --env-vars-file=/home/vladka/projects/unfederalreserve/devops/notifications/deploy.env

