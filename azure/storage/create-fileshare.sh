#!/bin/bash

set -e

# https://docs.microsoft.com/en-us/cli/azure/vm/diagnostics

# this spits a 'WARNING: There are no credentials' msg..
# ignore it if you have an active session with az
# https://github.com/Azure/azure-cli/issues/16063

if [[ -z "${4}" ]] ; then
    printf 'resource group: ' && read RG_NAME
    printf 'fileshare name: ' && read FSNAME
    printf 'storage account: ' && read STORAGE_ACC
    printf 'subscription name: ' && read SUB_NAME
else
    RG_NAME="${1}"
    FSNAME="${2}"
    STORAGE_ACC="${3}"
    SUB_NAME="${4}"
fi

storage_key=`az storage account keys list \
--account-name "${STORAGE_ACC}" \
--query '[0].value' --output tsv`

az storage share create \
--name "${FSNAME}" \
--account-name "${STORAGE_ACC}" \
--fail-on-exist \
--quota 50 \
--account-key "${storage_key}" \
--subscription "${SUB_NAME}" | jq
