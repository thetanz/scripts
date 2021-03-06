#!/bin/bash
# get all nested permission assignments within an azure resource group

set -e #-x

if [[ -z "${1}" ]] ; then
    printf 'resource group: ' && read AZURE_RG
else
    AZURE_RG="${1}"
fi

# view top-level permissions with
# az role assignment list --resource-group "${AZURE_RG}" --output table

echo "attempting to generate IAM report for resource-assigned permissions within rg: "${AZURE_RG}""

AZ_RESOURCES=`az resource list --resource-group "${AZURE_RG}" --query '[].id' --output tsv`
RESOURCE_COUNT=`echo "${AZ_RESOURCES}" | wc -l | sed 's/^ *//g'`

TASK_COUNT=1
FOUND_ASSIGNMENTS=0
while IFS= read -r resourceid; do
    RESOURCE_NAME=`az resource show --ids "${resourceid}" --query name --output tsv`
    echo "iterating ${RESOURCE_NAME} - ${TASK_COUNT}/${RESOURCE_COUNT}"
    AZ_ASSIGNMENTS=`az role assignment list --scope "${resourceid}" --output table > /dev/null 2>&1 || echo "no assignments found"`
    if [ -n "${AZ_ASSIGNMENTS}" ]; then
        echo "${RESOURCE_NAME}" >> iam-report-${AZURE_RG}.txt
        echo "${AZ_ASSIGNMENTS}" >> iam-report-${AZURE_RG}.txt
        FOUND_ASSIGNMENTS=$((FOUND_ASSIGNMENTS+1))
    fi
    unset AZ_ASSIGNMENTS RESOURCE_NAME
    TASK_COUNT=$[$TASK_COUNT +1]
done <<< "${AZ_RESOURCES}"

if [ ${FOUND_ASSIGNMENTS} -gt 0 ]; then
    echo "found ${FOUND_ASSIGNMENTS} permissions assignments"
    echo "output within iam-report-${AZURE_RG}.txt"
    cat iam-report-${AZURE_RG}.txt
else
    echo "no resource IAM assignments found"
fi
