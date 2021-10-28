#!/usr/bin/env bash

BASE_PATH=$(dirname "$0")/../core

ENV_CONFIG="/tmp/env_config.yaml"
DEPLOY_CONFIG="/tmp/deploy_config.yaml"
TMP_CONFIG="/tmp/config.yaml"

source ${BASE_PATH}/etc/parse_yaml.sh

function join_configs()
{
    ENV_DIR=$1

    echo "env: {}" > ${ENV_CONFIG}
    for CONFIG in $(ls ${ENV_DIR})
    do
        cp ${ENV_CONFIG} ${TMP_CONFIG}
        yq -P eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' ${TMP_CONFIG} ${ENV_DIR}/${CONFIG} | sed "s/'/\"/g" > ${ENV_CONFIG}
    done
}

function read_config()
{
    join_configs $1

    j2 --filters ${BASE_PATH}/etc/jinja_custom_filters.py -o ${DEPLOY_CONFIG} ${ENV_CONFIG} ${ENV_CONFIG}

    eval $(parse_yaml ${DEPLOY_CONFIG})

    set
}
