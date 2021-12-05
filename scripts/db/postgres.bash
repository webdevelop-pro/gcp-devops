#!/usr/bin/env bash

function create_database()
{
  DATABASE=$1
  ENV=$(printenv env_name)
  DATABASE_NAME=$(printenv env_db_databases_${DATABASE}_name)
  # ToDo: Do for each in env_db
  DATABASE_INSTANCE_NAME=$ENV
  DATABASE_VERSION=$(printenv env_db_${ENV}_version)
  DATABASE_CPU=$(printenv env_db_${ENV}_cpu)
  DATABASE_MEM=$(printenv env_db_${ENV}_mem)
  DB_NODE_TYPE=$(printenv env_db_${ENV}_node_type)

  gcloud sql instances create ${DATABASE_INSTANCE_NAME} \
    --project ${env_project_id} \
    --region ${env_project_region} \
    --database-version ${DATABASE_VERSION} \
    --cpu ${DATABASE_CPU} \
    --memory ${DATABASE_MEM}

  gcloud beta sql databases create ${DATABASE_NAME} \
    --project ${env_project_id} \
    --instance ${DATABASE_INSTANCE_NAME}

  gcloud sql instances patch ${DATABASE_INSTANCE_NAME} \
    --project ${env_project_id} \
    --tier ${DB_NODE_TYPE} \
    --backup-start-time="00:00" \
    --availability-type REGIONAL \
    --backup-start-time=00:00
}

function create_user()
{
  USER=$1
  ENV=$(printenv env_name)
  USER_NAME=$(printenv env_db_${ENV}_app_username)
  USER_PASSWORD=$(printenv env_db_${ENV}_app_password)
  DATABASE_INSTANCE_NAME=$ENV

  gcloud beta sql users set-password ${USER_NAME} \
    --project ${env_project_id} \
    --instance=${DATABASE_INSTANCE_NAME} \
    --password=${USER_PASSWORD}
}
