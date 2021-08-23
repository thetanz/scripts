#!/bin/bash

set -e

if [[ -z "${4}" ]] ; then
    printf 'storage account name: ' && read account_name
    printf 'storage blob name: ' && read blob_name
    printf 'apim tenant name: ' && read apim_tenant
    printf 'apim resource group: ' && read rg_name
else
    account_name="${1}"
    blob_name="${2}"
    apim_tenant="${3}"
    rg_name="${4}"
fi

storage_key=`az storage account keys list \
--account-name "${account_name}" \
--query '[0].value' --output tsv`

timestamp=`date +%s`

az apim backup \
--resource-group "${rg_name}" \
--name "${apim_tenant}" \
--backup-name "backup-${timestamp}-${apim_tenant}" \
--storage-account-name "${account_name}" \
--storage-account-container "${blob_name}" \
--storage-account-key "${storage_key}" \
| jq

unset storage_key
