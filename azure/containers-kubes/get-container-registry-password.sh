#!/bin/bash

set -e

if [[ -z "${3}" ]] ; then
    printf 'acr name:' && read ACR_NAME
    printf 'resource group:' && read RESOURCE_GROUP
    printf 'subscription:' && read SUBSCRIPTION
else
    ACR_NAME="${1}"
    RESOURCE_GROUP="${2}"
    SUBSCRIPTION="${3}"
fi

az acr credential show \
--name "${ACR_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--subscription "${SUBSCRIPTION}" \
--query passwords[0].value \
--output tsv
