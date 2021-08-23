#!/bin/bash

set -e

if [[ -z "${7}" ]] ; then
    printf 'ip prefixes in cidr:' && read ADDRESS_PREFIX
    printf 'vnet to create subnet within:' && read VNET_NAME
    printf 'nsg to associate with:' && read NSG_NAME
    printf 'subnet name:' && read SNET_NAME
    printf 'location:' && read LOCATION
    printf 'subscription name:' && read SUB_NAME
    printf 'resource group:' && read RESOURCE_GROUP
else
    ADDRESS_PREFIX="${1}"
    VNET_NAME="${2}"
    NSG_NAME="${3}"
    SNET_NAME="${4}"
    LOCATION="${5}"
    SUB_NAME="${6}"
    RESOURCE_GROUP="${7}"
fi

az network vnet subnet create \
--address-prefixes "${ADDRESS_PREFIX}" \
--name "${SNET_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--vnet-name "${VNET_NAME}" \
--network-security-group "${NSG_NAME}" \
--subscription "${SUB_NAME}" \
| jq
