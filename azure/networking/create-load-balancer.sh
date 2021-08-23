#!/bin/bash

set -e

if [[ -z "${11}" ]] ; then
    printf 'location: ' && read LOCATION
    printf 'load balancer name: ' && read LB_NAME
    printf 'subscription name: ' && read SUB_NAME
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'purpose: ' && read TAG_PURPOSE
    printf 'subnet: ' && read SUBNET
    printf 'public ip name: ' && read PIP_NAME
    printf 'vnet name: ' && read VNET_NAME
    printf 'fronted name: ' && read FRONTEND_NAME
    printf 'backend name: ' && read BACKEND_NAME
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
else
    LOCATION="${1}"
    LB_NAME="${2}"
    SUB_NAME="${3}"
    RESOURCE_GROUP="${4}"
    TAG_PURPOSE="${5}"
    SUBNET="${6}"
    PIP_NAME="${7}"
    VNET_NAME="${8}"
    FRONTEND_NAME="${9}"
    BACKEND_NAME="${10}"
    TAG_ENVIRONMENT="${11}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

PIP_ID=`az network public-ip show \
--name "${PIP_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--query id --output tsv`

az network lb create \
--name "${LB_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--location "${LOCATION}" \
--public-ip-address "${PIP_ID}" \
--frontend-ip-name "${FRONTEND_NAME}" \
--subscription "${SUB_NAME}" \
--backend-pool-name "${BACKEND_NAME}" \
--sku Standard \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
| jq
