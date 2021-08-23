#!/bin/bash

set -e

# review configure-windows-virtual-machine.sh
# contains a number of post-build features which may be useful
# this script creates encrypted vm with aad login enabled with a focus on secure defaults

if [[ -z "${12}" ]] ; then
    printf 'location: ' && read LOCATION
    printf 'subscription name: ' && read SUB_NAME
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'purpose: ' && read TAG_PURPOSE
    printf 'vm name: ' && read VM_NAME
    printf 'vm diagnostics storage acc: ' && read DIAG_STORE
    printf 'name of existing nic: ' && read NICNAME
    printf 'name of existing nsg: ' && read NSGNAME
    printf 'name of existing vnet: ' && read VNETNAME
    printf 'keyvault: ' && read KEYVAULT
    printf 'projectlink: ' && read PROJLINK
    printf 'azure ad groupid or userid: ' && read ADGROUPOBJECT
else
    LOCATION="${1}"
    SUB_NAME="${2}"
    RESOURCE_GROUP="${3}"
    TAG_PURPOSE="${4}"
    VM_NAME="${5}"
    DIAG_STORE="${6}"
    NICNAME="${7}"
    NSGNAME="${8}"
    VNETNAME="${9}"
    KEYVAULT="${10}"
    PROJLINK="${11}"
    ADGROUPOBJECT="${12}"
fi

VM_USER="localuser"
TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

VM_PASSWD=`openssl rand -base64 12`

echo "user: ${VM_USER}"
echo "password: ${VM_PASSWD}"
echo "hostname: ${VM_NAME}"
echo "resource: ${VM_NAME}"

az keyvault secret set \
--name "${VM_NAME}" \
--vault-name "${KEYVAULT}" \
--description "${VM_USER}" \
--value "${VM_PASSWD}" | jq

#auto patching is still in preview and has been enabled for the subscription prior to execution of this script with
#az feature register --namespace Microsoft.Compute --name InGuestAutoPatchVMPreview
#az feature register --namespace Microsoft.Compute --name InGuestPatchVMPreview
#az feature show --namespace Microsoft.Compute --name InGuestAutoPatchVMPreview
#az feature show --namespace Microsoft.Compute --name InGuestPatchVMPreview
#az provider register --namespace Microsoft.Compute
#--patch-mode 'AutomaticByPlatform' 

az vm create --name "${VM_NAME}" \
--assign-identity \
--nics ${NICNAME} \
--resource-group ${RESOURCE_GROUP} \
--admin-password ${VM_PASSWD} \
--admin-username ${VM_USER} \
--authentication-type password \
--computer-name ${VM_NAME} \
--enable-agent true \
--enable-auto-update true \
--enable-hotpatching true \
--image 'MicrosoftWindowsDesktop:Windows-10:20h2-pro:19042.804.2102050012' \
--license-type None \
--location ${LOCATION} \
--os-disk-name "osdisk-${VM_NAME}" \
--size 'Standard_B2ms' \
--subscription "${SUB_NAME}" \
--boot-diagnostics-storage ${DIAG_STORE} \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice=${TAG_PRACTICE} \
Owner=${TAG_OWNER} \
ReviewDate=${TAG_REVIEWDATE} \
ProjectLink="${PROJLINK}" | jq

# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-cli-quickstart
az vm encryption enable \
--resource-group ${RESOURCE_GROUP} \
--name "${VM_NAME}" \
--disk-encryption-keyvault ${KEYVAULT} | jq

# https://docs.microsoft.com/en-us/azure/active-directory/devices/howto-vm-sign-in-azure-ad-windows
az vm extension set \
--publisher "Microsoft.Azure.ActiveDirectory" \
--name "AADLoginForWindows" \
--resource-group ${RESOURCE_GROUP} \
--vm-name "${VM_NAME}" | jq

# https://stackoverflow.com/questions/63033002/azure-vm-cant-install-qualys-extension
az vm extension set \
--name "WindowsAgent.AzureSecurityCenter" \
--publisher "Qualys"
--resource-group ${RESOURCE_GROUP} \
--vm-name "${VM_NAME}" | jq

az role assignment create \
--role "Virtual Machine Administrator Login" \
--assignee ${ADGROUPOBJECT} \
--scope `az vm show --resource-group ${RESOURCE_GROUP} --name "${VM_NAME}" --query id -o tsv` | jq
