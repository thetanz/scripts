#!/bin/bash

# use this with a management group to run commands in the context of all your subscriptions!
# ./iterate-subscriptions.sh "az webapp list --query '[].hostNames' --output tsv"
# ./iterate-subscriptions.sh "az network public-ip list --query '[].ipAddress' --output tsv"
# ./iterate-subscriptions.sh "az storage account list --query '[].name' --output tsv"
# ./iterate-subscriptions.sh storage/get-all-public-storage-containers.sh
# ./iterate-subscriptions.sh appservices-functions/get-all-functions-without-authentication.sh

if [[ -z "${1}" ]] ; then
  printf 'batch az command:' && read AZCMD
else
  AZCMD="${1}"
fi

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

SUBSCRIPTIONS=`az account list --query "[].id" -o tsv`

while read SUBSCRIPTION ; do
  echo "iterating sub id: ${SUBSCRIPTION}"
  az account set --subscription ${SUBSCRIPTION}
  eval ${AZCMD}
done <<< "${SUBSCRIPTIONS}"
