#!/usr/bin/env bash

BASE_PATH=$(dirname "$0")/../core

ENV_CONFIG=$1
DEPLOY_CONFIG="/tmp/deploy_config.yaml"

source ${BASE_PATH}/etc/parse_yaml.sh

function read_config()
{
    j2 --filters ${BASE_PATH}/etc/jinja_custom_filters.py -o ${DEPLOY_CONFIG} ${ENV_CONFIG} ${ENV_CONFIG}

    eval $(parse_yaml ${DEPLOY_CONFIG})

    set
}
