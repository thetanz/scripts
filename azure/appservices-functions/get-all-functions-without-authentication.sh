#!/bin/bash
# theta.co.nz/cyber
# https://docs.microsoft.com/en-au/azure/app-service/overview-authentication-authorization

set -e
output_filename="functions-noauth.csv"

azfunctions=`az functionapp list --query '[].name' --output tsv`
functions_count=`echo ${azfunctions} | wc -w | tr -d ' '`

loop_counter=1
for fn in ${azfunctions}
do
    echo "processing ${loop_counter} of ${functions_count} - ${fn}"
    current_subscription=`az account show --query id --output tsv`
    resource_group=`az functionapp list --query "[?name=='${fn}'].resourceGroup"  -o tsv`
    fn_uri="https://management.azure.com/subscriptions/${current_subscription}/resourceGroups/${resource_group}/providers/Microsoft.Web/sites/${fn}/functions?api-version=2017-08-01"
    fn_authvalues=`az rest --url ${fn_uri} \
    | jq '.value[].properties | .config.bindings[].authLevel + "," + .config.bindings[].type + "," + .invoke_url_template'`
    # fn_authvalues returns 3 comma separated values - create variable for each
    for authvalue in ${fn_authvalues}
    do
        auth_level=`echo ${authvalue} | cut -d',' -f1 | tr -d '"'`
        auth_type=`echo ${authvalue} | cut -d',' -f2 | tr -d '"'`
        invoke_url_template=`echo ${authvalue} | cut -d',' -f3 | tr -d '"'`
        if [ "$auth_level" == "anonymous" ]
        then
            # check if the function is public by assessing status code of invoke url
            # :enhancement tbd: - check various http verbs
            status_code=`curl -s -o /dev/null -w "%{http_code}" ${invoke_url_template}`
            if [ "${status_code}" != "401" ] && [ "${status_code}" != "403" ]
            then
                echo "public function: ${fn}"
                echo "auth_level: ${auth_level}"
                echo "auth_type: ${auth_type}"
                echo "invoke_url_template: ${invoke_url_template}"
                # if CSV header does not exist (assume if no file present) add it
                if [ ! -f "functions_without_authentication.csv" ]
                then
                    echo "name,auth_level,auth_type,invoke_url_template" > ${output_filename}
                fi
                echo "${fn},${auth_level},${auth_type},${invoke_url_template}" >> ${output_filename}
            fi
        fi
    done
    loop_counter=$((loop_counter+1))
done
