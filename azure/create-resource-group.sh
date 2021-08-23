#!/bin/bash

set -e

if [[ -z "${5}" ]] ; then
    printf 'location: ' && read LOCATION
    printf 'subscription name: ' && read SUB_NAME
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'purpose: ' && read TAG_PURPOSE
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
else
    LOCATION="${1}"
    SUB_NAME="${2}"
    RESOURCE_GROUP="${3}"
    TAG_PURPOSE="${4}"
    TAG_ENVIRONMENT="${5}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

az group create \
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
