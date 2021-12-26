#!/usr/bin/env bash

BASE_PATH=$(dirname "$0")/../core

ENV_CONFIG="/tmp/env_config.yaml"
DEPLOY_CONFIG="/tmp/deploy_config.yaml"
TMP_CONFIG="/tmp/config.yaml"
PREV_ENV_CONFIG="/tmp/env_prev_config.yaml"

rm -f ${ENV_CONFIG} ${DEPLOY_CONFIG} ${TMP_CONFIG} ${PREV_ENV_CONFIG}

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

    i=0
    touch ${PREV_ENV_CONFIG}
    while [[ $(diff ${PREV_ENV_CONFIG} ${ENV_CONFIG}) != "" ]]; do
        j2 --filters ${BASE_PATH}/etc/jinja_custom_filters.py -o ${DEPLOY_CONFIG} ${ENV_CONFIG} ${ENV_CONFIG}

        cp ${ENV_CONFIG} ${PREV_ENV_CONFIG}
        cp ${DEPLOY_CONFIG} ${ENV_CONFIG}

        (( i++ ))

        if (( i > 10 )); then
            >&2 echo "loop dependency detected!"
            exit 2
        fi

    done

    sed 's/((/{{/g' ${DEPLOY_CONFIG} | sed 's/))/}}/g' > /tmp/new_deploy.yaml

    cp /tmp/new_deploy.yaml ${DEPLOY_CONFIG}

    eval $(parse_yaml ${DEPLOY_CONFIG})

    set | sed "s/[ ]*#[^\']*//"
}
