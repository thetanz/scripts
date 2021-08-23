#!/bin/bash

set -e

# script assumes an existing vnet & no existing bastion/subnet configuration

if [[ -z "${10}" ]] ; then
    printf 'location: ' && read LOCATION
    printf 'subscription name: ' && read SUB_NAME
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'target vm name: ' && read TARGET_VM
    printf 'bastion name: ' && read BASTION_NAME
    printf 'vnet name: ' && read VNET
    printf 'nsg name: '  && read NSG
    printf 'bastion pip name: ' && read PIP
    printf 'bastion dns prefix: ' && read DNSPREFIX
else
    LOCATION="${1}"
    SUB_NAME="${2}"
    RESOURCE_GROUP="${3}"
    TARGET_VM="${4}"
    BASTION_NAME="${5}"
    VNET="${6}"
    NSG="${7}"
    PIP="${8}"
    DNSPREFIX="${9}"
fi

VM_NIC_ID=`az vm get-instance-view \
--resource-group "${RESOURCE_GROUP}" \
--name "${TARGET_VM}" \
--query 'networkProfile.networkInterfaces[0].id' \
--output tsv`

VM_SUBNET_ID=`az network nic show \
--ids "${VM_NIC_ID}" \
--query 'ipConfigurations[].subnet[].id' \
--output tsv`

az network public-ip create \
--resource-group "${RESOURCE_GROUP}" \
--dns-name "${DNSPREFIX}" \
--name "${PIP}" \
--location "${LOCATION}" \
--sku Standard \
--subscription "${SUB_NAME}" \
| jq

# inbound pre-requisites - yes, they're less than ideal..
# https://docs.microsoft.com/en-us/azure/bastion/bastion-nsg
# https://github.com/MicrosoftDocs/azure-docs/issues/42737#issuecomment-554280385

az network nsg rule create \
--description 'Allow Bastion Internet Access
https://docs.microsoft.com/en-us/azure/bastion/create-host-cli' \
--name 'AllowBastionAccess' \
--nsg-name "${NSG}" \
--priority 500 \
--resource-group "${RESOURCE_GROUP}" \
--access Allow \
--destination-port-ranges 443 \
--direction Inbound \
--protocol Tcp \
--source-port-ranges '*' \
--subscription "${SUB_NAME}" \
| jq

az network nsg rule create \
--description 'Allow Bastion Internet Access
https://docs.microsoft.com/en-us/azure/bastion/create-host-cli' \
--name 'AllowBastionGateway' \
--nsg-name "${NSG}" \
--source-address-prefixes 'GatewayManager' \
--priority 501 \
--resource-group "${RESOURCE_GROUP}" \
--access Allow \
--destination-port-ranges 443 4443 \
--direction Inbound \
--protocol Tcp \
--source-port-ranges '*' \
--subscription "${SUB_NAME}" \
| jq

az network nsg rule create \
--description 'Allow Bastion Internet Access
https://docs.microsoft.com/en-us/azure/bastion/create-host-cli' \
--name 'AllowBastionIntercom' \
--nsg-name "${NSG}" \
--source-address-prefixes 'VirtualNetwork' \
--destination-address-prefixes 'VirtualNetwork' \
--priority 502 \
--resource-group "${RESOURCE_GROUP}" \
--access Allow \
--destination-port-ranges 8080 5701 \
--direction Inbound \
--protocol Tcp \
--source-port-ranges '*' \
--subscription "${SUB_NAME}" \
| jq

az network nsg rule create \
--description 'Allow Bastion Internet Access
https://docs.microsoft.com/en-us/azure/bastion/create-host-cli' \
--name 'AllowBastionIntercom' \
--nsg-name "${NSG}" \
--source-address-prefixes 'AzureLoadBalancer' \
--priority 503 \
--resource-group "${RESOURCE_GROUP}" \
--access Allow \
--destination-port-ranges 443 \
--direction Inbound \
--protocol Tcp \
--source-port-ranges '*' \
--subscription "${SUB_NAME}" \
| jq

#outbound pre-requisites

az network nsg rule create \
--description 'Allow Bastion Internet Access
https://docs.microsoft.com/en-us/azure/bastion/create-host-cli' \
--name 'AllowBastionComms' \
--nsg-name "${NSG}" \
--destination-address-prefixes 'VirtualNetwork' \
--priority 500 \
--resource-group "${RESOURCE_GROUP}" \
--access Allow \
--destination-port-ranges 3389 22 \
--direction Outbound \
--protocol Tcp \
--source-port-ranges '*' \
--subscription "${SUB_NAME}" \
| jq

az network nsg rule create \
--description 'Allow Bastion Internet Access
https://docs.microsoft.com/en-us/azure/bastion/create-host-cli' \
--name 'AllowBastionMeta' \
--nsg-name "${NSG}" \
--destination-address-prefixes 'AzureCloud' \
--priority 501 \
--resource-group "${RESOURCE_GROUP}" \
--access Allow \
--destination-port-ranges 443 \
--direction Outbound \
--protocol Tcp \
--source-port-ranges '*' \
--subscription "${SUB_NAME}" \
| jq

az network vnet subnet create \
--address-prefixes 10.0.1.0/24 \
--name AzureBastionSubnet \
--resource-group "${RESOURCE_GROUP}" \
--vnet-name "${VNET}" \
--network-security-group "${NSG}" \
--subscription "${SUB_NAME}" \
| jq

az network bastion create \
--name "${BASTION_NAME}" \
--subscription "${SUB_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--vnet-name "${VNET}" \
--public-ip-address "${PIP}" \
--location "${LOCATION}" \
| jq
