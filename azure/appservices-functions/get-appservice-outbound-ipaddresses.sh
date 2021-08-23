#!/bin/bash

set -e

if [[ -z "${3}" ]] ; then
    printf 'resource group:' && read RESOURCE_GROUP
    printf 'web app name:' && read WEBAPPNAME
    printf 'subscription: ' && read SUBSCRIPTION
else
    RESOURCE_GROUP="${1}"
    WEBAPPNAME="${2}"
    SUBSCRIPTION="${3}"
fi

az webapp show \
--name "${WEBAPPNAME}" \
--resource-group "${RESOURCE_GROUP}" \
--subscription "${SUBSCRIPTION}" \
--query [possibleOutboundIpAddresses,outboundIpAddresses] \
--output table
