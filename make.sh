#!/usr/bin/env bash

BASE_PATH=$(dirname "$0")

set -e

source ${BASE_PATH}/etc/parse_yaml.sh

source ${BASE_PATH}/scripts/k8s/cluster.bash

DEPLOY_CONFIG="./deploy_config.yaml"
APP_CONFIG="/tmp/apps_config.yaml"
TMP_CONFIG="/tmp/tmp_config.yaml"
DEPLOYMENT_TEMPLATE="/tmp/deployment.yaml"

TEMPLATES_DIR="${BASE_PATH}/k8s"
RENDERED_TEMPLATES_DIR="rendered_templates"
RENDERED_APPS_DIR="${RENDERED_TEMPLATES_DIR}/apps"
RENDERED_GLOBAL_DIR="${RENDERED_TEMPLATES_DIR}/global"

GLOBAL_CONFIGS=${BASE_PATH}/../configs/global

if [ -d ${BASE_PATH}/../configs/secrets/${env_secrets} ]; then
    ENV_SECRETS=${BASE_PATH}/../configs/secrets/${env_secrets}
fi

function render_template()
{
    SERVICE_NAME=$1
    TEMPLATE_FILE=$2
    j2 --filters ${BASE_PATH}/etc/jinja_custom_filters.py -e os "${TEMPLATES_DIR}/${TEMPLATE_FILE}" ${DEPLOY_CONFIG} | sed '/^[[:blank:]]*$/ d' > ${RENDERED_TEMPLATES_DIR}/${SERVICE_NAME}/${TEMPLATE_FILE}
}

function render_templates()
{
    sed 's/{{/((/g' ${DEPLOY_CONFIG} | sed 's/}}/))/g' > /tmp/new_deploy.yaml

    cp /tmp/new_deploy.yaml ${DEPLOY_CONFIG}

    for FILENAME in $(find ${GLOBAL_CONFIGS} ${ENV_SECRETS} -type f)
    do
        export filename=$(basename ${FILENAME})

        cat ${DEPLOY_CONFIG} > ${TMP_CONFIG}

        # use env config for render global config
        if [[ ${FILENAME} != 'cloudsql-instance-credentials.yaml' ]]
        then
            j2 --filters ${BASE_PATH}/etc/jinja_custom_filters.py -e os ${FILENAME} ${DEPLOY_CONFIG} >> ${TMP_CONFIG}
        else
            cat ${FILENAME} >> ${TMP_CONFIG}
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

    for FILENAME in $(find ${GLOBAL_CONFIGS} ${ENV_SECRETS} -type f)
    do
        FILE_NAME=$(basename ${FILENAME})
        export filename=${FILE_NAME}

        OUTPUT_DIR=apps/${FILE_NAME}
        mkdir -p ${RENDERED_TEMPLATES_DIR}/${OUTPUT_DIR}

        # Render configmap for app
        render_template ${OUTPUT_DIR} configmap.yaml

        # Render secret for app
        render_template ${OUTPUT_DIR} secret.yaml

        # Render deployment for app
        render_template ${OUTPUT_DIR} deployment.yaml

        # Render cronjob for app
        render_template ${OUTPUT_DIR} cronjob.yaml

        # Render service for app
        render_template ${OUTPUT_DIR} service.yaml

        # Render ingress for app
        render_template ${OUTPUT_DIR} ingress.yaml

        # Render certificate for app
        render_template ${OUTPUT_DIR} certificate.yaml

        # Render namespace for app
        render_template ${OUTPUT_DIR} namespace.yaml
    done

    mkdir -p ${RENDERED_GLOBAL_DIR}

    render_template global letsencrypt-issuer.yaml

    # Delete empty files
    find ${RENDERED_TEMPLATES_DIR} -size  0 -print -delete
}

function deploy()
{
    render_templates

    deploy_namespace

    deploy_configs

    deploy_secret

    deploy_deployment

    deploy_cronjob

    deploy_service

    deploy_ingress

    deploy_certificate
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

function deploy_cronjob()
{
    for SERVICE_DIR in $(ls ${RENDERED_APPS_DIR})
    do
        K8S_MANIFEST="${RENDERED_APPS_DIR}/${SERVICE_DIR}/cronjob.yaml"

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

function deploy_namespace()
{
    for SERVICE_DIR in $(ls ${RENDERED_APPS_DIR})
    do
        K8S_MANIFEST="${RENDERED_APPS_DIR}/${SERVICE_DIR}/namespace.yaml"

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
CHANNELS: '${env_build_notifications}'
EOF

    gcloud --project ${env_project_id} functions deploy build-notifications \
     --runtime go116 \
     --trigger-topic cloud-builds \
     --allow-unauthenticated \
     --entry-point=CloudBuildSubscribe \
     --source=${BASE_PATH}/cloud-func/notifications \
     --env-vars-file=/tmp/cloudbuild.env
}

get_credentials

$@
