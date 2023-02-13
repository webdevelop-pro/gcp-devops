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

GLOBAL_CONFIGS=${BASE_PATH}/../configs/global/${env_project_name}

if [ -d ${BASE_PATH}/../configs/secrets/${env_secrets} ]; then
    ENV_SECRETS=${BASE_PATH}/../configs/secrets/${env_secrets}
fi


function _render_template()
{
    SERVICE_NAME=$1
    TEMPLATE_FILE=$2

    echo "Render $(basename $TEMPLATE_FILE) for $SERVICE_NAME"

    j2 --filters ${BASE_PATH}/etc/jinja_custom_filters.py -e os "${TEMPLATE_FILE}" ${DEPLOY_CONFIG} | sed '/^[[:blank:]]*$/ d' > ${RENDERED_TEMPLATES_DIR}/${SERVICE_NAME}/$(basename ${TEMPLATE_FILE})

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "!!!!!!!!!! Failed while render $(basename $TEMPLATE_FILE) template for service ${SERVICE_NAME}"
        exit 1
    fi
}

function _get_services_manifests_dir()
{
    SERVICE_NAME=$1

    if [[ ${SERVICE_NAME} = "" ]]; then
        SERVICE_NAME="all"
    fi

    if [[ $( echo ${SERVICE_NAME} | tr '[:upper:]' '[:lower:]' ) = 'all' ]]; then
        SERVICE_NAME='*'
    fi

    find ${RENDERED_APPS_DIR} -type d -name "${SERVICE_NAME}.yaml"
}

function _get_service_config()
{
    SERVICE_NAME=$1

    if [[ ${SERVICE_NAME} = "" ]]; then
        SERVICE_NAME="all"
    fi

    if [[ $( echo ${SERVICE_NAME} | tr '[:upper:]' '[:lower:]' ) = 'all' ]]; then
        SERVICE_NAME='*'
    fi

    find ${GLOBAL_CONFIGS} ${ENV_SECRETS} -type f -name "${SERVICE_NAME}.yaml"
}

function _get_template_file()
{
    GROUP=$1
    TEMPLATE_NAME=$2

    if [[ ${TEMPLATE_NAME} = "" ]]; then
        TEMPLATE_NAME="all"
    fi

    if [[ $( echo ${TEMPLATE_NAME} | tr '[:upper:]' '[:lower:]' ) = 'all' ]]; then
        TEMPLATE_NAME='*'
    fi

    find ${TEMPLATES_DIR}/${GROUP} -type f -name "${TEMPLATE_NAME}.yaml"
}

function _render_app_templates()
{
    SERVICE_NAME=$1
    TEMPLATE_NAME=$2

    sed 's/{{/((/g' ${DEPLOY_CONFIG} | sed 's/}}/))/g' > /tmp/new_deploy.yaml

    cp /tmp/new_deploy.yaml ${DEPLOY_CONFIG}

    for FILENAME in $(_get_service_config ${SERVICE_NAME})
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

    for FILENAME in $(_get_service_config ${SERVICE_NAME})
    do
        FILE_NAME=$(basename ${FILENAME})
        export filename=${FILE_NAME}

        OUTPUT_DIR=apps/${FILE_NAME}
        mkdir -p ${RENDERED_TEMPLATES_DIR}/${OUTPUT_DIR}

        for TEMPLATE_FILE in $(_get_template_file apps ${TEMPLATE_NAME})
        do
            _render_template ${OUTPUT_DIR} ${TEMPLATE_FILE}
        done
    done
}

function _render_global_templates() {
    TEMPLATE_NAME=$1

    mkdir -p ${RENDERED_GLOBAL_DIR}

    for TEMPLATE_FILE in $(_get_template_file global ${TEMPLATE_NAME})
    do
        _render_template global ${TEMPLATE_FILE}
    done
}

function render_templates()
{
    SERVICE_NAME=$1
    TEMPLATE_NAME=$2

    rm -rf ${RENDERED_TEMPLATES_DIR}

    if [[ ${SERVICE_NAME} = "global" ]]; then
        _render_global_templates $TEMPLATE_NAME
    else
        _render_app_templates $SERVICE_NAME $TEMPLATE_NAME
    fi

    # Delete empty files
    find ${RENDERED_TEMPLATES_DIR} -size  0 -print -delete

    echo "Render finish successfully"
}

function _apply_apps()
{
    SERVICE_NAME=$1
    TEMPLATE_NAME=$2
    
    for SERVICE_DIR in $(_get_services_manifests_dir $SERVICE_NAME)
    do
        echo $SERVICE_DIR
        for TEMPLATE_FILE in $(_get_template_file apps ${TEMPLATE_NAME})
        do
            K8S_MANIFEST="${SERVICE_DIR}/$(basename ${TEMPLATE_FILE})"

            echo "Apply ${K8S_MANIFEST}"

            if [ -f ${K8S_MANIFEST} ]; then
                cat ${K8S_MANIFEST} | kubectl apply -f -
            fi
        done
    done
}

function _apply_global()
{
    TEMPLATE_NAME=$1

    for TEMPLATE_FILE in $(_get_template_file global ${TEMPLATE_NAME})
    do
        K8S_MANIFEST="${RENDERED_GLOBAL_DIR}/$(basename ${TEMPLATE_FILE})"

        echo "Apply ${K8S_MANIFEST}"

        if [ -f ${K8S_MANIFEST} ]; then
            cat ${K8S_MANIFEST} | kubectl apply -f -
        fi
    done
}

function apply()
{
    SERVICE_NAME=$1
    TEMPLATE_NAME=$2

    if [[ ${SERVICE_NAME} = "global" ]]; then
        _apply_global $TEMPLATE_NAME
    else
        _apply_apps $SERVICE_NAME $TEMPLATE_NAME
    fi
}

function deploy()
{
    render_templates $1 $2
    apply $1 $2
}

function help()
{
    echo "Usage:
        ./deploy_apps.bash <command> [arguments]

    Commands:
        render_templates [app_name] [template_name]        Render templates for k8s manifests per service
        apply [app_name] [template_name]                   Apply rendered templates to k8s
        deploy [app_name] [template_name]                  Render + Apply
    
    Args:
        app_name - App name, example: \"cms-api\", default: \"all\"
        template_name - Template name, example: \"configmap\", default: \"all\"

    Examples:
        Render only configmap for cms-api
            ./scripts/k8s/deploy_apps.bash render_templates cms-api configmap

        Render only global services
            ./scripts/k8s/deploy_apps.bash render_templates global
    "
}

$@
