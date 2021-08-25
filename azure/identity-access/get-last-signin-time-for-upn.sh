#!/bin/bash

# get last signin timestamp for an azure ad upn
# usage i.e

# ./get-last-signin-time-for-upn.sh josh.highet@theta.co.nz

set -e

if [[ -z "${1}" ]] ; then
    printf 'user principal name: ' && read MSFT_UPN
else
    MSFT_UPN="${1}"
fi



# if we try access the signin data from a upn you get the error below - so we get the userid first

# {
#   "error": {
#     "code": "UnknownError",
#     "message": "{\"@odata.context\":\"http://reportingservice.activedirectory.windowsazure.com/$metadata#Edm.String\",\"value\":\"Get By Key only supports UserId and the key has to be a valid Guid\"}",
#     "innerError": {
#       "date": "2021-08-25T04:09:30",
#       "request-id": "682c9cf2-eddc-4bf9-9ce1-a11418701fa1",
#       "client-request-id": "682c9cf2-eddc-4bf9-9ce1-a11418701fa1"
#     }
#   }
# }

msft_user_guid=`az ad user show --id "${MSFT_UPN}" --query objectId --output tsv`

az rest --url "https://graph.microsoft.com/beta/users/${msft_user_guid}?select=displayname,signinActivity,accountEnabled,userType,userPrincipalName" \
--query 'signInActivity.lastSignInDateTime' --output tsv
