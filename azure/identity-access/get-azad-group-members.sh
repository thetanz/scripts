#!/bin/bash
# get all azure ad group members

set -e

if [[ -z "${1}" ]] ; then
    printf 'group name: ' && read groupname
else
    groupname="${1}"
fi

az ad group member list --group "${groupname}" --query "[].userPrincipalName" --output tsv