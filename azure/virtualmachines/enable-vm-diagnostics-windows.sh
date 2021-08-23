#!/bin/bash

set -e

# https://docs.microsoft.com/en-us/cli/azure/vm/diagnostics
# this spits a 'WARNING: There are no credentials' message, ignore it if you have an active session with az
# https://github.com/Azure/azure-cli/issues/16063

if [[ -z "${3}" ]] ; then
    printf 'resource group: ' && read RG_NAME
    printf 'vm name: ' && read VM_NAME
    printf 'storage account: ' && read STORAGE_ACC
else
    RG_NAME="${1}"
    VM_NAME="${2}"
    STORAGE_ACC="${3}"
fi

VM_ID=$(az vm show -g ${RG_NAME} -n ${VM_NAME} --query "id" -o tsv)

CONFIG=$(az vm diagnostics get-default-config --is-windows-os \
    | sed "s#__DIAGNOSTIC_STORAGE_ACCOUNT__#${STORAGE_ACC}#g" \
    | sed "s#__VM_OR_VMSS_RESOURCE_ID__#${VM_ID}#g")

storage_sastoken=$(az storage account generate-sas \
    --account-name ${STORAGE_ACC} --expiry 2025-12-31T23:59:00Z \
    --permissions acuw --resource-types co --services bt \
    --https-only --output tsv)

PRO_SETTINGS="{'storageAccountName': '${STORAGE_ACC}', 'storageAccountSasToken': '${storage_sastoken}'}"

az vm diagnostics set \
--settings "${CONFIG}" \
--protected-settings "${PRO_SETTINGS}" \
--resource-group "${RG_NAME}" \
--vm-name "${VM_NAME}" \
| jq
