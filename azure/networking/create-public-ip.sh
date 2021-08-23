#!/bin/bash

set -e

# this will create a single resource group containing an az asg

if [[ -z "${7}" ]] ; then
    printf 'location: ' && read LOCATION
    printf 'subscription name: ' && read SUB_NAME
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'dns name: ' && read DNS_NAME
    printf 'pip name: ' && read PIP_NAME
    printf 'purpose: ' && read TAG_PURPOSE
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
else
    LOCATION="${1}"
    SUB_NAME="${2}"
    RESOURCE_GROUP="${3}"
    DNS_NAME="$4"
    PIP_NAME="${5}"
    TAG_PURPOSE="${6}"
    TAG_ENVIRONMENT="${7}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

#--version IPv6
az network public-ip create \
--name "${PIP_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--sku 'Standard' \
--dns-name "${DNS_NAME}" \
--location "${LOCATION}" \
--subscription "${SUB_NAME}" \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
| jq
