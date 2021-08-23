#!/bin/bash

set -e

if [[ -z "${10}" ]] ; then
    printf 'location:' && read LOCATION
    printf 'app service plan name:' && read ASP_NAME
    printf 'subscription name:' && read SUB_NAME
    printf 'resource group:' && read RESOURCE_GROUP
    printf 'purpose:' && read TAG_PURPOSE
    printf 'cdn sku (commonly: Standard_Microsoft):' && read CDN_SKU
    printf 'existing cdn name:' && read CDN_NAME
    printf 'endpoint dns name:' && read ENDPOINT_NAME
    printf 'origin ip address:' && read ENDPOINT_ORIGIN
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
else
    LOCATION="${1}"
    ASP_NAME="${2}"
    SUB_NAME="${3}"
    RESOURCE_GROUP="${4}"
    TAG_PURPOSE="${5}"
    CDN_SKU="${6}"
    CDN_NAME="${7}"
    ENDPOINT_NAME="${8}"
    ENDPOINT_ORIGIN="${9}"
    TAG_ENVIRONMENT="${10}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

az cdn profile create \
--location "${LOCATION}" \
--name "${CDN_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--sku "${CDN_SKU}" \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
| jq

az cdn endpoint create \
--name "$ENDPOINT_NAME" \
--origin "${ENDPOINT_ORIGIN}" \
--profile-name "${CDN_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--enable-compression true \
--location "${LOCATION}" \
--subscription "${SUB_NAME}" \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
| jq
