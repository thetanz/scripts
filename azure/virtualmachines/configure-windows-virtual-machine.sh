#!/bin/bash

set -e

#http://schema.management.azure.com/schemas/2016-11-17/runcommands.json
#https://docs.microsoft.com/en-us/cli/azure/vm/run-command?view=azure-cli-latest

if [[ -z "${4}" ]] ; then
    printf 'vm name: ' && read VM_NAME
    printf 'resource group: ' && read RG_NAME
    printf 'storage account: ' && read STORAC
    printf 'fileshare name: ' && read FS_NAME
else
    VM_NAME="${1}"
    RG_NAME="${2}"
    STORAC="${3}"
    FS_NAME="${4}"
fi

echo "enabling vm autoupdate"
az vm run-command invoke \
--command-id EnableWindowsUpdate \
--name "${VM_NAME}" \
--resource-group "${RG_NAME}" | jq

echo "disabling nla to allow rdp through JIT on macOS, sigh"
az vm run-command invoke \
--command-id DisableNLA \
--name "${VM_NAME}" \
--resource-group "${RG_NAME}" | jq

echo "disabling old ssl & tls ciphers"
az vm run-command invoke \
--command-id RunPowerShellScript \
--name "${VM_NAME}" \
--resource-group "${RG_NAME}" \
--scripts @assets/disable-old-windows-ciphers.ps1 | jq

echo "installing crowdstrike falcon"
az vm run-command invoke \
--command-id RunPowerShellScript \
--name "${VM_NAME}" \
--resource-group "${RG_NAME}" \
--scripts @assets/install-crowdstrike.ps1 | jq

echo "mounting azure fileshare"
# using AADDS for identity-based access to the storage account would be nice but msft make this overwhelmingly complicated
# https://docs.microsoft.com/en-au/azure/storage/files/storage-files-identity-auth-active-directory-enable
storage_key=`az storage account keys list \
--resource-group ${RG_NAME} \
--account-name ${STORAC} \
--query '[0].value' --output tsv`

storage_fs_uri=`az storage account show \
--resource-group ${RG_NAME} \
--name ${STORAC} \
--query 'primaryEndpoints.file' \
--output tsv`

strip_uri=${storage_fs_uri#*//}
storage_fs_fqdn=${strip_uri%/}
# get an FQDN out of a URL (https://theta.co.nz/ > theta.co.nz)

az vm run-command invoke \
--command-id RunPowerShellScript \
--name "${VM_NAME}" \
--resource-group "${RG_NAME}" \
--scripts @assets/mount-fileshare.ps1 \
--parameters "storac=${STORAC}" "fsname=${FS_NAME}" \
"fsfqdn=${storage_fs_fqdn}" "storkey=${storage_key}" | jq

echo "restarting host to apply registry changes"
az vm restart \
--name "${VM_NAME}" \
--resource-group "${RG_NAME}" | jq
