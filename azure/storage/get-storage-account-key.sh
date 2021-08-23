#!/bin/bash

set -e

if [[ -z "${3}" ]] ; then
    printf 'storage account name:' && read ACCOUNT_NAME
    printf 'resource group:' && read RG_NAME
    printf 'subscription name:' && read SUBSCRIPTION
else
    ACCOUNT_NAME="${1}"
    RG_NAME="${2}"
    SUBSCRIPTION="${3}"
fi

az storage account keys list \
--subscription "${SUBSCRIPTION}" \
--resource-group "${RG_NAME}" \
--account-name "${ACCOUNT_NAME}" \
--query '[0].value' --output tsv
