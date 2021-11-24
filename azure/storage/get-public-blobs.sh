#!/bin/bash

set -e
#set -x

# compose a list of publicly accessible files in blob storage within the context of your current subscription
# 1. fetch all storage accounts in the subscription
# 2. for each storage account, check if implicitly denies access to the public
# 3. if not, fetch all containers in the storage account
# 4. for each container, fetch all blobs in the container
# 5. for each blob, check if it is publicly accessible
# 6. if so, print the URL to the blob

# a faster, brief check of storage accounts allowing public access can be achieved with the following resource graph query
# https://portal.azure.com/#blade/HubsExtension/ArgQueryBlade
# 
# resources
# | where type =~ 'Microsoft.Storage/storageAccounts'
# | extend allowBlobPublicAccess = parse_json(properties).allowBlobPublicAccess
# | where isnull(allowBlobPublicAccess) or allowBlobPublicAccess==true
# | project name, resourceGroup, allowBlobPublicAccess, id
# 

# wipe output file if already exists
rm public-blobs.txt ||

current_subscription_context=$(az account show --query name -o tsv)
echo 'listing all storage accounts in context of:' "${current_subscription_context}"
# produce a list of storage account names
storageacc_names=`az storage account list --query '[].name' --output tsv`
for account in ${storageacc_names}
do
  echo 'processing storage account:' ${account}
  # grab the primary account key for future operations
  key="$(az storage account keys list --account-name "${account}" --query "[0].{value:value}" --output tsv)"
  # check if public access is disabled by default at the root level
  blob_public=`az storage account show --name "${account}" --query allowBlobPublicAccess --output tsv`
  # if public access is not explicitly set to false
  if [ -z ${blob_public} ] || [ ${blob_public} != false ]; then
    echo 'public access is NOT restricted across the account'
    # list out all containers within the storage account
    containers=`az storage container list --account-name "${account}" \
    --account-key ${key} --query "[].{name:name}" --output tsv`
    # for each container we've found in the potentially public storage account
    for container in ${containers}
    do
      echo 'processing container:' "${container}"
      # check if the container denies public access
      public_access_container=`az storage container show --account-name "${account}" \
      --account-key ${key} --name "${container}" \
      --query 'properties.publicAccess' --output tsv`
      if [ -n "${public_access_container}" ]; then
      # if the container does not explictly deny public access
        echo 'public blob discovered'
        # list out all blobs within the container
        blobs=`az storage blob list --account-name "${account}" \
        --account-key ${key} --container "${container}" \
        --query "[].{name:name}" --output tsv`
        # print each public blob
        echo 'writing public blobs to file'
        while IFS= read -r line; do
            echo 'https://'"${account}"'.blob.core.windows.net/'"${container}"'/'"${line}" \
            >> public-blobs.txt
        done <<< "$blobs"
      else
        echo 'public access is restricted within the container'
      fi
    done
  else
    echo 'public access is restricted across the account'
  fi
done
