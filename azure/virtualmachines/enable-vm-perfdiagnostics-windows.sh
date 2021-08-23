#!/bin/bash

set -e

# https://docs.microsoft.com/en-us/azure/azure-monitor/agents/diagnostics-extension-windows-install

if [[ -z "${4}" ]] ; then
  printf 'storage account name: ' && read STORAGEACC
  printf 'resource group name: ' && read RG_NAME
  printf 'virtual machine name: ' && read VM_NAME
  printf 'subscription: ' && read SUBSCRIPTION
else
  STORAGEACC="${1}"
  RG_NAME="${2}"
  VM_NAME="${3}"
  SUBSCRIPTION="${4}"
fi

STORKEY=`az storage account keys list \
--account-name "${STORAGEACC}" \
--subscription "${SUBSCRIPTION}" \
--query '[0].value' --output tsv`

STORFQDN=`az storage account show \
--name "${STORAGEACC}" \
--query 'primaryEndpoints.blob' \
--subscription "${SUBSCRIPTION}" \
--output tsv | sed 's:/*$::'`

PROTECC_SETTINGS='
{
"storageAccountName": "'${STORAGEACC}'",
"storageAccountKey": "'${STORKEY}'",
"storageAccountEndPoint": "'${STORFQDN}'"
}'

SETTINGS='
{
  "StorageAccount": "'${STORAGEACC}'",
  "WadCfg": {
    "DiagnosticMonitorConfiguration": {
      "overallQuotaInMB": 5120,
      "PerformanceCounters": {
        "scheduledTransferPeriod": "PT1M",
        "PerformanceCounterConfiguration": [
          {
            "counterSpecifier": "\\Processor Information(_Total)\\% Processor Time",
            "unit": "Percent",
            "sampleRate": "PT60S"
          }
        ]
      },
      "WindowsEventLog": {
        "scheduledTransferPeriod": "PT1M",
        "DataSource": [
          {
            "name": "Application!*[System[(Level=1 or Level=2 or Level=3)]]"
          }
        ]
      }
    }
  }
}
'

az vm extension set \
--resource-group "${RG_NAME}" \
--vm-name "${VM_NAME}" \
--name IaaSDiagnostics \
--publisher Microsoft.Azure.Diagnostics \
--subscription "${SUBSCRIPTION}" \
--protected-settings "${PROTECC_SETTINGS}" \
--settings "${SETTINGS}"
