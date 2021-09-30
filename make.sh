#!/usr/bin/env bash

BASE_PATH=$(dirname "$0")

set -e

source ${BASE_PATH}/etc/parse_yaml.sh

DEPLOY_CONFIG="/tmp/deploy_config.yaml"
APP_CONFIG="/tmp/apps_config.yaml"
TMP_CONFIG="/tmp/tmp_config.yaml"
DEPLOYMENT_TEMPLATE="/tmp/deployment.yaml"

TEMPLATES_DIR="${BASE_PATH}/k8s"
RENDERED_TEMPLATES_DIR="rendered_templates"
RENDERED_APPS_DIR="${RENDERED_TEMPLATES_DIR}/apps"
RENDERED_GLOBAL_DIR="${RENDERED_TEMPLATES_DIR}/global"

ENV_CONFIG=$2
GLOBAL_CONFIGS=$(dirname "$2")/../global

if [ ! -f "$2" ]; then
    echo "Config not found!"
    exit 1
fi

function render_template()
{
    SERVICE_NAME=$1
    TEMPLATE_FILE=$2
    j2 --filters ${BASE_PATH}/etc/jinja_custom_filters.py -e os "${TEMPLATES_DIR}/${TEMPLATE_FILE}" ${DEPLOY_CONFIG} | sed '/^[[:blank:]]*$/ d' > ${RENDERED_TEMPLATES_DIR}/${SERVICE_NAME}/${TEMPLATE_FILE}
}

function render_templates()
{
    for FILENAME in $(ls ${GLOBAL_CONFIGS})
    do
        export filename=${FILENAME}

        cat ${DEPLOY_CONFIG} > ${TMP_CONFIG}

        # use env config for render global config
        if [[ ${FILENAME} != 'cloudsql-instance-credentials.yaml' ]]
        then
            j2 ${GLOBAL_CONFIGS}/${FILENAME} ${DEPLOY_CONFIG} >> ${TMP_CONFIG}
        else
            cat ${GLOBAL_CONFIGS}/${FILENAME} >> ${TMP_CONFIG}
        fi

        # merge env config with global config (overwrite glbal values with env values) and convert back to yaml
        j2 -e os ${TEMPLATES_DIR}/merge_global_with_env.j2 ${TMP_CONFIG} \
            | sed 's/"/\\"/g' \
            | sed "s/'/\"/g" \
            | sed "s/True/true/g" \
            | sed "s/False/false/g" \
            | yq e -P - > ${DEPLOY_CONFIG}
    done

    rm -rf ${RENDERED_TEMPLATES_DIR}

    for FILENAME in $(ls ${GLOBAL_CONFIGS})
    do
        export filename=${FILENAME}

        OUTPUT_DIR=apps/${FILENAME}
        mkdir -p ${RENDERED_TEMPLATES_DIR}/${OUTPUT_DIR}

        # Render configmap for app
        render_template ${OUTPUT_DIR} configmap.yaml

        # Render secret for app
        render_template ${OUTPUT_DIR} secret.yaml

        # Render deployment for app
        render_template ${OUTPUT_DIR} deployment.yaml

        # Render service for app
        render_template ${OUTPUT_DIR} service.yaml

        # Render ingress for app
        render_template ${OUTPUT_DIR} ingress.yaml

        # Render certificate for app
        render_template ${OUTPUT_DIR} certificate.yaml
    done

    mkdir -p ${RENDERED_GLOBAL_DIR}

    render_template global letsencrypt-issuer.yaml

    # Delete empty files
    find ${RENDERED_TEMPLATES_DIR} -size  0 -print -delete
}

function deploy()
{
    render_templates

    deploy_configs

    deploy_secret

    deploy_deployment

    deploy_service

    deploy_ingress

    deploy_certificate

    deploy_global
}

function deploy_configs()
{
    for SERVICE_DIR in $(ls ${RENDERED_APPS_DIR})
    do
        K8S_MANIFEST="${RENDERED_APPS_DIR}/${SERVICE_DIR}/configmap.yaml"

        echo "Apply ${K8S_MANIFEST}"

        if [ -f ${K8S_MANIFEST} ]; then
            cat ${K8S_MANIFEST} | kubectl apply -f -
        fi
    done
}

function deploy_secret()
{
    for SERVICE_DIR in $(ls ${RENDERED_APPS_DIR})
    do
        K8S_MANIFEST="${RENDERED_APPS_DIR}/${SERVICE_DIR}/secret.yaml"

        echo "Apply ${K8S_MANIFEST}"

        if [ -f ${K8S_MANIFEST} ]; then
            cat ${K8S_MANIFEST} | kubectl apply -f -
        fi
    done
}

function deploy_deployment()
{
    for SERVICE_DIR in $(ls ${RENDERED_APPS_DIR})
    do
        K8S_MANIFEST="${RENDERED_APPS_DIR}/${SERVICE_DIR}/deployment.yaml"

        echo "Apply ${K8S_MANIFEST}"

        if [ -f ${K8S_MANIFEST} ]; then
            cat ${K8S_MANIFEST} | kubectl apply -f -
        fi
    done
}

function deploy_service()
{
    for SERVICE_DIR in $(ls ${RENDERED_APPS_DIR})
    do
        K8S_MANIFEST="${RENDERED_APPS_DIR}/${SERVICE_DIR}/service.yaml"

        echo "Apply ${K8S_MANIFEST}"

        if [ -f ${K8S_MANIFEST} ]; then
            cat ${K8S_MANIFEST} | kubectl apply -f -
        fi
    done
}

function deploy_ingress()
{
    for SERVICE_DIR in $(ls ${RENDERED_APPS_DIR})
    do
        K8S_MANIFEST="${RENDERED_APPS_DIR}/${SERVICE_DIR}/ingress.yaml"

        echo "Apply ${K8S_MANIFEST}"

        if [ -f ${K8S_MANIFEST} ]; then
            cat ${K8S_MANIFEST} | kubectl apply -f -
        fi
    done
}

function deploy_certificate()
{
    for SERVICE_DIR in $(ls ${RENDERED_APPS_DIR})
    do
        K8S_MANIFEST="${RENDERED_APPS_DIR}/${SERVICE_DIR}/certificate.yaml"

        echo "Apply ${K8S_MANIFEST}"

        if [ -f ${K8S_MANIFEST} ]; then
            cat ${K8S_MANIFEST} | kubectl apply -f -
        fi
    done
}

function deploy_global()
{
    for FILENAME in $(ls ${RENDERED_GLOBAL_DIR})
    do
        K8S_MANIFEST="${RENDERED_GLOBAL_DIR}/${FILENAME}"

        echo "Apply ${K8S_MANIFEST}"

        cat ${K8S_MANIFEST} | kubectl apply -f -
    done
}

function deploy_cloudbuild()
{

cat > /tmp/cloudbuild.env << EOF
SLACK_TOKEN: ${env_slack_bot_token}
GIT_REPO_OWNER: ${env_github_repo_owner}
GITHUB_ACCESS_TOKEN: ${env_github_access_token}
CHANNELS: "${env_build_notifications}"
EOF

    gcloud --project ${env_project_id} functions deploy build-notifications \
     --runtime go116 \
     --trigger-topic cloud-builds \
     --allow-unauthenticated \
     --entry-point=webdevelop-pro/gcp-devops/cloud-func/notifications/subscriptions/cloudbuild/Subscribe \
     --source=${BASE_PATH}/cloud-func/notifications \
     --env-vars-file=/tmp/cloudbuild.env
}

j2 --filters ${BASE_PATH}/etc/jinja_custom_filters.py -o ${DEPLOY_CONFIG} ${ENV_CONFIG} ${ENV_CONFIG}

eval $(parse_yaml ${DEPLOY_CONFIG})

gcloud container --project ${env_project_id} clusters get-credentials ${env_k8s_cluster_name} --region ${env_k8s_nodes_region}

kubectl create namespace ${env_k8s_apps_namespace} || kubectl get namespace ${env_k8s_apps_namespace}

$@
