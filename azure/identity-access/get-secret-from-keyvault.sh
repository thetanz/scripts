#!/bin/bash

set -e

if [[ -z "${3}" ]] ; then
    printf 'key vault name: ' && read kvname
    printf 'secret name: ' && read secretname
    printf 'subscription: ' && read SUBSCRIPTION
else
    kvname="${1}"
    secretname="${2}"
    SUBSCRIPTION="${3}"
fi

az keyvault secret show \
--name "${secretname}" \
--vault-name "${kvname}" \
--subscription "${SUBSCRIPTION}" \
--query 'value' \
--output tsv
