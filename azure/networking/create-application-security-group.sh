#!/bin/bash

set -e

if [[ -z "${6}" ]] ; then
    printf 'location: ' && read LOCATION
    printf 'subscription name: ' && read SUB_NAME
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'asg name: ' && read ASG_NAME
    printf 'purpose: ' && read TAG_PURPOSE
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
else
    LOCATION="${1}"
    SUB_NAME="${2}"
    RESOURCE_GROUP="${3}"
    ASG_NAME="${4}"
    TAG_PURPOSE="${5}"
    TAG_ENVIRONMENT="${6}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

az network asg create \
-g "${RESOURCE_GROUP}" \
-n "${ASG_NAME}" \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
| jq
