#!/bin/bash

set -e

if [[ -z "${4}" ]] ; then
    printf 'custom domain: ' && read FQDN
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'webapp name: ' && read WEBAPP_NAME
    printf 'subscription name: ' && read SUBSCRIPTION
else
    FQDN="${1}"
    RESOURCE_GROUP="${2}"
    WEBAPP_NAME="${3}"
    SUBSCRIPTION="${4}"
fi

az webapp config hostname add \
--hostname "${FQDN}" \
--subscription "${SUBSCRIPTION}" \
--resource-group "${RESOURCE_GROUP}" \
--webapp-name "${WEBAPP_NAME}" \
| jq
