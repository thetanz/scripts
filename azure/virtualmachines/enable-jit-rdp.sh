#!/bin/bash

set -e

# https://docs.microsoft.com/en-us/rest/api/securitycenter/jitnetworkaccesspolicies/createorupdate

if [[ -z "${3}" ]] ; then
  printf 'virtual machine name: ' && read VM_NAME
  printf 'resource group: ' && read RESOURCE_GROUP
  printf 'location: ' && read LOCATION
else
  VM_NAME="${1}"
  RESOURCE_GROUP="${2}"
  LOCATION="${3}"
fi

VMID=$(az vm show -g ${RESOURCE_GROUP} -n ${VM_NAME} -o tsv --query "id")
LOCATION=$(az vm show -g ${RESOURCE_GROUP} -n ${VM_NAME} -o tsv --query "location")
SUB=$(echo ${VMID} | cut -d \/ -f 3)

ENDPOINT="https://management.azure.com/subscriptions/${SUB}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Security/locations/${LOCATION}/jitNetworkAccessPolicies/default?api-version=2020-01-01"
POLICY_ID="/subscriptions/${SUB}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Security/locations/${LOCATION}/jitNetworkAccessPolicies/default"

JSON=$(cat <<-EOF
  {
    "kind": "Basic",
    "properties": {
       "virtualMachines": [
          {
            "id": "$VMID",
            "ports": [
              {
                "number": "3389",
                "protocol": "*",
                "allowedSourceAddressPrefix": "210.54.148.61",
                "maxRequestAccessDuration": "PT3H"
              }
            ]
          }
        ]
    },
    "id": "$POLICY_ID",
    "name": "default",
    "type": "Microsoft.Security/locations/jitNetworkAccessPolicies",
    "location": "$LOCATION"
  }
EOF
)

COMPRESSED_JSON=$(echo ${JSON} | jq -c)

az rest \
--method put \
--uri "${ENDPOINT}" \
--body "${COMPRESSED_JSON}" \
--output json \
| jq
