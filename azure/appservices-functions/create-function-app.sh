#!/bin/bash

set -e

if [[ -z "${9}" ]] ; then
    printf 'location:' && read LOCATION
    printf 'app service plan name:' && read ASP_NAME
    printf 'app service plan resource group:' && read APP_SERVICE_RG_NAME
    printf 'subscription name:' && read SUB_NAME
    printf 'resource group:' && read RESOURCE_GROUP
    printf 'purpose:' && read TAG_PURPOSE
    printf 'function app name:' && read FN_APP_NAME
    printf 'storage account:' && read FN_STOR_ACC
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
else
    LOCATION="${1}"
    ASP_NAME="${2}"
    APP_SERVICE_RG_NAME="${3}"
    SUB_NAME="${4}"
    RESOURCE_GROUP="${5}"
    TAG_PURPOSE="${6}"
    FN_APP_NAME="${7}"
    FN_STOR_ACC="${8}"
    TAG_ENVIRONMENT="${9}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

STORAGE_ACCOUNT_ID=`az storage account show --name "${FN_STOR_ACC}" --query id --output tsv`
APP_SERVICE_PLAN_ID=`az appservice plan show --name "${ASP_NAME}" --resource-group ${APP_SERVICE_RG_NAME} --query id --output tsv`

az functionapp create \
--name "${FN_APP_NAME}" --resource-group "${RESOURCE_GROUP}" \
--storage-account "${STORAGE_ACCOUNT_ID}" --assign-identity \
--functions-version 3 --os-type Linux --plan "${APP_SERVICE_PLAN_ID}" \
--runtime python --runtime-version 3.8 --subscription "${SUB_NAME}" \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
| jq

az functionapp update \
--name "${FN_APP_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--set httpsOnly=true \
| jq

az webapp config set \
--name "${FN_APP_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--subscription "${SUB_NAME}" \
--ftps-state FtpsOnly \
| jq
