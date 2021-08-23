#!/bin/bash

set -e

if [[ -z "${6}" ]] ; then
    printf 'location: ' && read LOCATION
    printf 'storage account name: ' && read STORAGE_ACC_NAME
    printf 'subscription name: ' && read SUB_NAME
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'purpose: ' && read TAG_PURPOSE
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
else
    LOCATION="${1}"
    STORAGE_ACC_NAME="${2}"
    SUB_NAME="${3}"
    RESOURCE_GROUP="${4}"
    TAG_PURPOSE="${5}"
    TAG_ENVIRONMENT="${6}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

az storage account create \
--encryption-key-type-for-queue Service \
--encryption-key-type-for-table Service \
--access-tier Hot --allow-blob-public-access true \
--https-only true --kind StorageV2 \
--location "${LOCATION}" \
--name "${STORAGE_ACC_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--enable-hierarchical-namespace true \
--min-tls-version TLS1_2 \
--publish-internet-endpoints true \
--assign-identity \
--publish-microsoft-endpoints true \
--routing-choice InternetRouting \
--sku Standard_LRS \
--subscription "${SUB_NAME}" \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
| jq
