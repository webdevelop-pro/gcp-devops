#!/usr/bin/env bash

function create_database()
{
  DATABASE=$1
  DATABASE_NAME=$(printenv env_db_databases_${DATABASE}_name)
  DATABASE_INSTANCE_NAME=$(printenv env_db_databases_${DATABASE}_instance)
  DATABASE_VERSION=$(printenv env_db_instances_${DATABASE_INSTANCE_NAME}_version)
  DATABASE_CPU=1
  DATABASE_MEM="3840MiB"
  DB_NODE_TYPE=$(printenv env_db_instances_${DATABASE_INSTANCE_NAME}_node_type)

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
  USER_NAME=$(printenv env_db_users_${USER}_username)
  USER_PASSWORD=$(printenv env_db_users_${USER}_password)
  DATABASE_INSTANCE_NAME=$(printenv env_db_users_${USER}_instance)

  gcloud beta sql users set-password ${USER_NAME} \
    --project ${env_project_id} \
    --instance=${DATABASE_INSTANCE_NAME} \
    --password=${USER_PASSWORD}
}
