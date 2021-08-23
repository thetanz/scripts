#!/bin/bash

set -e

if [[ -z "${10}" ]] ; then
printf 'vnet to join: ' && read VNET
printf 'subnet name to join: ' && read SUBNET
printf 'nic name: ' && read NICNAME
printf 'location: ' && read LOCATION
printf 'nsg name: ' && read NSGNAME
printf 'public ip name: ' && read PIPNAME
printf 'subscription name: ' && read SUB_NAME
printf 'resource group: ' && read RESOURCE_GROUP
printf 'purpose: ' && read TAG_PURPOSE
printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
else
FOO="${1}"
VNET="${1}"
SUBNET="${2}"
NICNAME="${3}"
LOCATION="${4}"
NSGNAME="${5}"
PIPNAME="${6}"
SUB_NAME="${7}"
RESOURCE_GROUP="${8}"
TAG_PURPOSE="${9}"
TAG_ENVIRONMENT="${10}"
fi

TAG_OWNER=`az ad signed-in-user show --query userPrincipalName --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`
TAG_ENVIRONMENT='Prod'

az network nic create \
--name "${NICNAME}" \
--resource-group "${RESOURCE_GROUP}" \
--network-security-group "${NSGNAME}" \
--vnet-name "${VNET}" \
--subnet "${SUBNET}" \
--location "${LOCATION}" \
--subscription "${SUB_NAME}" \
--public-ip-address "${PIPNAME}" \
--tags \
Purpose="${TAG_PURPOSE}" \
Practice="${TAG_PRACTICE}" \
Owner="${TAG_OWNER}" \
ReviewDate="${TAG_REVIEWDATE}" \
Environment="${TAG_ENVIRONMENT}" \
| jq
