#!/bin/bash

set -e

if [[ -z "${4}" ]] ; then
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'public ip name: ' && read PIPNAME
    printf 'log analytics resource group: ' && read LAW_RG
    printf 'log analytics workspace: ' && read LAW_NAME
else
    RESOURCE_GROUP="${1}"
    PIPNAME="${2}"
    LAW_RG="${3}"
    LAW_NAME="${4}"
fi

PIP_ID=`az network public-ip show \
--name ${PIPNAME} \
--resource-group ${RESOURCE_GROUP} \
--query id --output tsv`

LOGANALYTICS_ID=`az monitor log-analytics workspace show \
--resource-group ${LAW_RG} \
--workspace-name ${LAW_NAME} \
--query id --output tsv`

az monitor diagnostic-settings create \
--resource "${PIP_ID}" --name "loganalytics" \
--workspace "${LOGANALYTICS_ID}" --metrics \
'[
  {
    "category": "AllMetrics",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  }
]' | jq
