#!/bin/bash

set -e

if [[ -z "${8}" ]] ; then
    printf 'location: ' && read LOCATION
    printf 'vnet name: ' && read VNET_NAME
    printf 'subnet name: ' && read SNET_NAME
    printf 'nsg to associate with: ' && read NSG_NAME
    printf 'subscription name: ' && read SUB_NAME
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'resource purpose (tag): ' && read TAG_PURPOSE
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
else
    LOCATION="${1}"
    VNET_NAME="${2}"
    SNET_NAME="${3}"
    NSG_NAME="${4}"
    SUB_NAME="${5}"
    RESOURCE_GROUP="${6}"
    TAG_PURPOSE="${7}"
    TAG_ENVIRONMENT="${8}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

az network vnet create \
--name "${VNET_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--ddos-protection false \
--location "${LOCATION}" \
--network-security-group "${NSG_NAME}" \
--subnet-name "${SNET_NAME}" \
--subscription "${SUB_NAME}" \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
| jq
