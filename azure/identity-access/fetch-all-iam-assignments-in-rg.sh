#!/bin/bash
# get all nested permission assignments within an azure resource group

set -e

if [[ -z "${1}" ]] ; then
    printf 'resource group: ' && read AZURE_RG
else
    AZURE_RG="${1}"
fi

# view top-level permissions with
# az role assignment list --resource-group "${AZURE_RG}" --output table

echo "generating iam report for resource-assigned permissions within a resource group: "${AZURE_RG}"" > iam-report-${AZURE_RG}.txt

AZ_RESOURCES=`az resource list --resource-group "${AZURE_RG}" --query '[].id' --output tsv`
RESOURCE_COUNT=`echo "${AZ_RESOURCES}" | wc -l | sed 's/^ *//g'`

TASK_COUNT=1
while IFS= read -r resourceid; do
    RESOURCE_NAME=`az resource show --ids "${resourceid}" --query name --output tsv`
    echo "iterating ${RESOURCE_NAME} - ${TASK_COUNT}/${RESOURCE_COUNT}"
    AZ_ASSIGNMENTS=`az role assignment list --scope "${resourceid}" --output table`
    if [ -n "${AZ_ASSIGNMENTS}" ]; then
        echo "${RESOURCE_NAME}" >> iam-report-${AZURE_RG}.txt
        echo "${AZ_ASSIGNMENTS}" >> iam-report-${AZURE_RG}.txt
    fi
    unset AZ_ASSIGNMENTS RESOURCE_NAME
    TASK_COUNT=$[$TASK_COUNT +1]
done <<< "${AZ_RESOURCES}"

echo "done - see iam-report-${AZURE_RG}.txt"