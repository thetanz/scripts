#!/bin/bash

set -e

functions=`az functionapp list --query '[].name' --output tsv`

for fn in ${functions}
do
    current_subscription=`az account show --query id --output tsv`
    resource_group=`az functionapp list --query "[?name=='${fn}'].resourceGroup"  -o tsv`
    echo https://management.azure.com/subscriptions/${current_subscription}/resourceGroups/${resource_group}/providers/Microsoft.Web/sites/${fn}/functions?api-version=2017-08-01 \
    | tee -a fn_info_uris.txt
done

for fn_uri in $(cat fn_info_uris.txt)
do
    az rest --url ${fn_uri} \
    | jq '.value[].properties | .config.bindings[].authLevel + "," + .config.bindings[].type + "," + .invoke_url_template' \
    | tee -a results.csv
done

rm fn_info_uris.txt

# authlevel=`az functionapp function show \
# --function-name ${subfn} \
# --resource-group "${resource_group}" \
# --name fn-name-here \
# | jq '.config.bindings[0].authLevel' -r`
