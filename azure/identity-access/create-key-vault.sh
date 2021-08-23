#!/bin/bash

set -e

# this will create a single keyvault enabled for diskencryption
# https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/disk-encryption-key-vault

if [[ -z "${8}" ]] ; then
    printf 'location: ' && read LOCATION
    printf 'subscription name: ' && read SUB_NAME
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'keyvault name: ' && read KV_NAME
    printf 'purpose: ' && read TAG_PURPOSE
    printf 'diagnostic storage account name: ' && read STORAGE_ACC_NAME
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
    printf 'projectlink: ' && read PROJLINK
    printf 'azuread group id or userid for access: ' && read AADACCESSID
else
    LOCATION="${1}"
    SUB_NAME="${2}"
    RESOURCE_GROUP="${3}"
    KV_NAME="${4}"
    TAG_PURPOSE="${5}"
    STORAGE_ACC_NAME="${6}"
    TAG_ENVIRONMENT="${7}"
    PROJLINK="${8}"
    AADACCESSID="${9}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

az keyvault create \
--subscription "${SUB_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--enable-purge-protection true \
--enable-rbac-authorization true \
--location "${LOCATION}" \
--name "${KV_NAME}" \
--retention-days 14 \
--enabled-for-disk-encryption \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
ProjectLink="${PROJLINK}" \
| jq

KEY_VAULT_ID=`az keyvault show \
--subscription "${SUB_NAME}" \
--name "${KV_NAME}" \
--query 'id' --output tsv`

STORAGE_ACCOUNT_ID=`az storage account show \
--subscription "${SUB_NAME}" \
--name "${STORAGE_ACC_NAME}" \
--query 'id' --output tsv`

az monitor diagnostic-settings create \
--storage-account "${STORAGE_ACCOUNT_ID}" \
--resource "${KEY_VAULT_ID}" \
--name "Key Vault Logs" \
--logs '[{"category": "AuditEvent","enabled": true}]' \
--metrics '[{"category": "AllMetrics","enabled": true}]' \
| jq

az role assignment create \
--role "Key Vault Secrets Officer" \
--assignee ${AADACCESSID} \
--scope `az keyvault show --name ${KV_NAME} \
--resource-group ${RESOURCE_GROUP} \
--query id -o tsv` | jq
