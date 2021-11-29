#!/bin/bash
# ./list-all-resource-groups.sh my-resource-group | jq -r '.[].id'

set -e

if [[ -z "${1}" ]] ; then
    # get current subscription context
    SUB_NAME=`az account show --query name -o tsv`
else
    # unless one specified in stdin
    SUB_NAME="${1}"
fi

az group list \
--subscription "${SUB_NAME}" \
--query "[].{name:name,id:id}" \
--output json \
| jq
