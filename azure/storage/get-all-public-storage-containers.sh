#!/bin/bash

set -e

# compose a list of publicly accessible files in blob storage within the context of your current subscription

# a faster, brief check of storage accounts allowing public access can be achieved with the following resource graph query
# https://portal.azure.com/#blade/HubsExtension/ArgQueryBlade
# 
# resources
# | where type =~ 'Microsoft.Storage/storageAccounts'
# | extend allowBlobPublicAccess = parse_json(properties).allowBlobPublicAccess
# | where isnull(allowBlobPublicAccess) or allowBlobPublicAccess==true
# | project name, resourceGroup, allowBlobPublicAccess, id
# 

# for a given subscription produce a list of storage account names
storageacc_names=`az storage account list --query '[].name' --output tsv`

# for each storage account we've discovered
for account in ${storageacc_names}
do
  # grab the storage account key for future operations
  key="$(az storage account keys list --account-name ${account} --query "[0].{value:value}" --output tsv)"
  # check if public access is disabled by default at the root level
  blob_public=`az storage account show --name $account --query allowBlobPublicAccess --output tsv`
  # if public access is not explicitly set to false
  if [ -z ${blob_public} ] || [ ${blob_public} != false ]; then
    # list out all containers within the storage account
    containers=`az storage container list --account-name ${account} \
    --account-key ${key} --query "[].{name:name}" --output tsv`
    # for each container we've found in the potentially public storage account
    for container in ${containers}
    do
      # check if the container denies public access
      public_access_container=`az storage container show --account-name ${account} \
      --account-key ${key} --name ${container} \
      --query 'properties.publicAccess' --output tsv`
      # if the container does not explictly deny public access
      if [ -n "${public_access_container}" ]; then
        # list out all blobs within the container
        blobs=`az storage blob list \
        --container-name ${container} \
        --num-results "*" \
        --account-name ${account} \
        --account-key ${key} \
        --query '[].name' \
        --output tsv`
        # for each blob we've found in the container
        for item in ${blobs}
        do
          # compose a URL's for the file
          echo 'https://'${account}.blob.core.windows.net/${container}/"$item" \
          | tee -a storage_account.bloburis
        done
      fi
    done
  fi
done
