#!/bin/bash

set -e

if [[ -z "${5}" ]] ; then
    printf 'location:' && read LOCATION
    printf 'subscription name:' && read SUB_NAME
    printf 'resource group name: ' && read RESOURCE_GROUP
    printf 'utc shutdown time (10PM NZDT==9AM UTC):' && read UTC_SHUTDOWN_TIME
    printf 'virtual machine name:' && read VIRTUAL_MACHINE_NAME
    printf 'webhook uri:' && read WEBHOOK_URI
else
    LOCATION="${1}"
    SUB_NAME="${2}"
    RESOURCE_GROUP="${3}"
    UTC_SHUTDOWN_TIME="${4}"
    VIRTUAL_MACHINE_NAME="${5}"
    WEBHOOK_URI="${6}"
fi

VIRTUAL_MACHINE_LOCATION=`az vm show \
--name "${VIRTUAL_MACHINE_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--query location --output tsv`

az vm auto-shutdown \
--webhook "${WEBHOOK_URI}" \
--time "${UTC_SHUTDOWN_TIME}" \
--name "${VIRTUAL_MACHINE_NAME}" \
--location "${VIRTUAL_MACHINE_LOCATION}" \
--resource-group "${RESOURCE_GROUP}" \
| jq

unset WEBHOOK_URI VIRTUAL_MACHINE_LOCATION
