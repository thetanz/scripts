#!/bin/bash

set -e

if [[ -z "${6}" ]] ; then
    printf 'nsg name: ' && read NSG_NAME
    printf 'location: ' && read LOCATION
    printf 'subscription name: ' && read SUB_NAME
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'resource purpose (tag): ' && read TAG_PURPOSE
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
else
    NSG_NAME="${1}"
    LOCATION="${2}"
    SUB_NAME="${3}"
    RESOURCE_GROUP="${4}"
    TAG_PURPOSE="${5}"
    TAG_ENVIRONMENT="${6}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

az network nsg create \
--name "${NSG_NAME}" \
--location "${LOCATION}" \
--subscription "${SUB_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
| jq
