#!/bin/bash

# use this with a management group to run commands in the context of all your subscriptions

if [[ -z "${1}" ]] ; then
  printf 'batch az command:' && read AZCMD
else
  AZCMD="${1}"
fi

# if AZCMD is help or h print usage
if [[ "${AZCMD}" == "help" || "${AZCMD}" == "-h" ]] ; then
  echo 'try things such as;'
  echo './iterate-subscriptions.sh "az webapp list --query '[].hostNames' --output tsv"'
  echo './iterate-subscriptions.sh "az network public-ip list --query '[].ipAddress' --output tsv"'
  echo './iterate-subscriptions.sh "az storage account list --query '[].name' --output tsv"'
  echo './iterate-subscriptions.sh storage/get-all-public-storage-containers.sh'
  echo './iterate-subscriptions.sh appservices-functions/get-all-functions-without-authentication.sh'
  exit
fi

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

SUBSCRIPTIONS=`az account list --query "[].id" -o tsv`
subcount=$(echo "${SUBSCRIPTIONS}" | wc -l | xargs)
echo "||| found ${subcount} subscriptions"
count=1

while read SUBSCRIPTION ; do
  echo "||| iterating sub ${count} of ${subcount} - sub id: ${SUBSCRIPTION}"
  az account set --subscription ${SUBSCRIPTION}
  eval ${AZCMD}
  count=$((count+1))
done <<< "${SUBSCRIPTIONS}"
