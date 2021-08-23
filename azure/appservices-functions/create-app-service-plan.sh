#!/bin/bash

set -e

if [[ -z "${6}" ]] ; then
    printf 'location:' && read LOCATION
    printf 'app service plan name: ' && read ASP_NAME
    printf 'subscription name: ' && read SUB_NAME
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'purpose: ' && read TAG_PURPOSE
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
else
    LOCATION="${1}"
    ASP_NAME="${2}"
    SUB_NAME="${3}"
    RESOURCE_GROUP="${4}"
    TAG_PURPOSE="${5}"
    TAG_ENVIRONMENT="${6}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

echo 'assuming b1 sku'

az appservice plan create \
--name "${ASP_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--is-linux --location "${LOCATION}" \
--sku B1 --subscription "${SUB_NAME}" \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
| jq
