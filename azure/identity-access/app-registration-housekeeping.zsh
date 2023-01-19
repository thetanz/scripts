#!/bin/zsh

# exports all azure ad application registrations to 'app-export/YYYY-MM-DD/json'
# reviews all exports to create actionable CSVs of problematic applications in 'app-export/YYYY-MM-DD'
# nb: the auditLogs endpoint has a 30 days rolling retention window (regardless of p1/2 sku)

## OUTPUT CSVs
# expired-credentials.csv: one line per expired credential per application
# no-owners.csv: one line per application without any owners
# app-consents.csv: one line per consent provided to an application
# disabled-owners.csv: one line per disabled owner of an application
# excessive-duration-credentials.csv: one line per application credential with an expiry +2years away
# non-theta-owners.csv: one line per owner of an application which is not correctly domain owned
# admin-theta-owners.csv: one line per owner of an application which is using their ADASH account

set -e

outdir="app-export"
mkdir -p "${outdir}" ||:

# set the threshold for what is defined as an 'excessive' expiration period
futureDate=`gdate +%s -d +2years`

# logtail helpers
autoload colors; colors
error() { echo "${fg[red]}$@${reset_color}" >&2 }
warn() { echo "${fg[yellow]}$@${reset_color}" >&2 }
good() { echo "${fg[green]}$@${reset_color}" >&2 }
blue() { echo "${fg[blue]}$@${reset_color}" >&2 }
audit() { echo "${fg[cyan]}🚨 $@ 🧨${reset_color}" >&2 }
echo
blue "azure ad enterprise applications export"
good "theta.co.nz/cyber 🤖 🔑 🖥️"
echo

# pre-flight local env checks
if ! command -v jq >/dev/null 2>&1; then
  error "jq is required for this script to run"
  green "https://stedolan.github.io/jq/download"
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  error "azure cli is required for this script to run"
  green "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit 1
else
  accountcontext=`az account show`
  domain=`echo -E "${accountcontext}" | jq -r .user.name | cut -d@ -f2`
  tenant_id=`echo -E "${accountcontext}" | jq -r .tenantId`
  echo "context tenant domain: ${domain}"
  echo "context tenant id: ${tenant_id}"
  echo
fi

# if not running on macos warn user this is untested
if [[ "$(uname)" != "Darwin" ]]; then
  warn "this script has only been tested on macos, quitting"
  exit 1
fi

# get date as DD-MM-YYYY
today=`gdate +%Y-%m-%d`
reportdir="${outdir}/${today}"
jsondir="${reportdir}/json/"

# if the report dir already exists, delete it and recreate it
if [[ -d "${reportdir}" ]]; then
  rm -rf "${reportdir}"
fi
mkdir -p "${reportdir}" ||:
mkdir -p "${jsondir}" ||:
echo "saving findings within ${reportdir}"
echo

# pre-populdate CSV headers
echo "\"appname\",\"appid\",\"ownermail\",\"ownerObjectId\",\"upnState\",\"ownerMailList\"" > "${reportdir}/disabled-owners.csv"
echo "\"appname\",\"appid\"" > "${reportdir}/no-owners.csv"
echo "\"appname\",\"appid\",\"ownermail\"" > "${reportdir}/non-theta-owners.csv"
echo "\"appname\",\"appid\",\"ownermail\"" > "${reportdir}/admin-theta-owners.csv"
echo "\"appname\",\"appid\",\"credExpiry\",\"credName\",\"ownerMailList\"" > "${reportdir}/expired-credentials.csv"
echo "\"appname\",\"appid\",\"consentPurpose\",\"consentType\",\"consentValue\",\"ownerMailList\"" > "${reportdir}/app-consents.csv"
echo "\"appname\",\"appid\",\"credName\",\"credExpiry\",\"ownerMailList\"" > "${reportdir}/excessive-duration-credentials.csv"


# check we have neccesary permissions to probe ms graph for audit timestamps
set +e
az rest --uri "https://graph.microsoft.com/beta/auditLogs/signIns?top=1" > "${jsondir}/last-ad-signin.json"
if [[ ! -s "${jsondir}/last-ad-signin.json" ]]; then
  error "missing permissions to fetch audit stamps from ms graph"
  error "ensure you have AuditLog.Read.All and Directory.Read.All"
  exit 1
fi
set -e

# fetch and count all app registrations
az ad app list --all > "${jsondir}/apps.json"
if [[ -s "${jsondir}/apps.json" ]] ; then
appCount=`jq -r '. | length' "${jsondir}/apps.json"`
blue "found ${appCount} app registrations"
else
echo "Could not export application list" >&2
exit 1
fi

counter=1
# for each app
jq -c '.[]' "${jsondir}/apps.json" | while read app ; do

  # parse the relevant fields
  appname=`echo -E "${app}" | jq -r ".displayName"`
  appid=`echo -E "${app}" | jq -r ".appId"`
  appPassCreds=`echo -E "${app}" | jq -c ".passwordCredentials[]"`
  appKeyCreds=`echo -E "${app}" | jq -c ".keyCredentials[]"`
  appConsents=`echo -E "${app}" | jq -c ".api.oauth2PermissionScopes[]"`
  echo "appcounter: ${counter}/${appCount}"
  echo "appname: ${appname}"
  echo "appid: ${appid}"

  # create a file for each app based on manifest
  echo -E "${app}" | jq -c > "${jsondir}/${appid}.json"

  # try fetch a timestamp for the last signin
  last_use_tz=`timeout 30s az rest --uri "https://graph.microsoft.com/beta/auditLogs/signIns?filter=appId eq '"${appid}"'&top=1" | jq -r '.value[].createdDateTime' ||:`
  # if last_use_tz exists
  if [ -z "${last_use_tz}" ]; then
    warn "last signin: unknown"
  else
    good "last signin: "${last_use_tz}""
  fi

  # fetch the owner UPN for the app
  appOwners=$( az ad app owner list --id "${appid}" | jq -c '.[] // empty' )
  ownerCount=$( echo -E "${appOwners}" | grep -v "^$" | wc -l | tr -d "[[:blank:]]" )
  ownerMailList=$( echo -E "${appOwners}" | jq -r '.mail // empty ' | grep -v "^$" | tr '\n' ' ' )

  # if no owners:
  if [[ ${ownerCount} == 0 ]] ; then
    error "no owners associated with this app"
    echo "\"${appname}\",\"${appid}\"" >> "${reportdir}/no-owners.csv"

  # owners exist, so check em:
  else
    echo "found "${ownerCount}" owner(s)"
    # for each owner check if account is disabled in AAD
    echo -E "${appOwners}" | jq -r '.mail' | while read owner ; do

      # if the owner does not end with context domain, warn
      if [[ "$owner" != *"@${domain}" ]] ; then
        warn "owner email '${owner}' does not end with context domain, '${domain}'"
        echo "\"${appname}\",\"${appid}\",\"${owner}\"" >> "${reportdir}/non-theta-owners.csv"
      else

        # check valid domain owner is enabled
        upnState=`az ad user show --id "${owner}" --query accountEnabled`
        if [[ $upnState == "false" ]] ; then
          error "owner email '${owner}' is a disabled azure ad upn"
          ownerObjectId=`az ad user show --id "${owner}" | jq -r ".objectId"`
          echo "\"${appname}\",\"${appid}\",\"${owner}\",\"${ownerObjectId}\",\"${upnState}\",\"${ownerMailList}\"" >> "${reportdir}/disabled-owners.csv"
        else
          good "owner '${owner}' is enabled"
        fi
      fi

      # check if the owner is a-XYZ account
      if [[ "$owner" == "a-"* ]] || [[ "$owner" == "admin-"* ]] || [[ "$owner" == "csp-"* ]] ; then
        warn "owner email '${owner}' is domain admin of '${domain}'"
        echo "\"${appname}\",\"${appid}\",\"${owner}\"" >> "${reportdir}/admin-theta-owners.csv"
      fi

    done

  fi

  # check certs & creds
  credCount=`echo "${appPassCreds}\n${appKeyCreds}" | grep -v "^$" | wc -l | tr -d "[[:blank:]]"`
  if [[ $credCount == 0 ]] ; then
    good "app uses no credentials"
  else
    appPass_count=`echo "${appPassCreds}" | grep -v "^$" | wc -l | tr -d "[[:blank:]]"`
    appKey_count=`echo "${appKeyCreds}" | grep -v "^$" | wc -l | tr -d "[[:blank:]]"`
    echo "found "${credCount}" credential(s) - "${appPass_count}" password(s) and "${appKey_count}" certificate(s)"

    # loop over all app creds, checking expiry dates
    echo "${appPassCreds}\n${appKeyCreds}" | grep -v "^$" | while read cred ; do
      credName=`echo -E "${cred}" | jq -r '.keyId'`
      credExpiry=`echo -E "${cred}" | jq -r '.endDateTime'`
      expDate=`gdate +%s -d "${credExpiry}"`

      # if app is already expired
      if [[ "$(gdate +%s)" -gt "${expDate}" ]] ; then
        error "expired: "${credExpiry}" on "${credName}""
        echo "\"${appname}\",\"${appid}\",\"${credExpiry}\",\"${credName}\",\"${ownerMailList}\"" >> "${reportdir}/expired-credentials.csv"

      # if app expiration is unreasonably long
      elif [[ ${expDate} -gt ${futureDate} ]] ; then
        warn "excessive expiration of "${credExpiry}" on credID "${credName}""
        echo "\"${appname}\",\"${appid}\",\"${credName}\",\"${credExpiry}\",\"${ownerMailList}\"" >> "${reportdir}/excessive-duration-credentials.csv"
      else
        good "credential "${credName}" expires "${credExpiry}""
      fi
    done
  fi

  # check oauth consents
  consentCount=`echo "${appConsents}" | grep -v "^$" | wc -l | tr -d "[[:blank:]]"`
  if [[ $consentCount == 0 ]] ; then
    good "app has no explicit oauth scopes"
  else
    echo "found "${consentCount}" oauth scope(s)"
    echo "${appConsents}" | grep -v "^$" | while read consent ; do
      consentPurpose=`echo -E "${consent}" | jq -r '.adminConsentDescription' | awk '{print tolower($0)}'`
      consentType=`echo -E "${consent}" | jq -r '.type' | awk '{print tolower($0)}'`
      consentValue=`echo -E "${consent}" | jq -r '.value' | awk '{print tolower($0)}'`
      echo "purpose: ${consentPurpose}"
      echo "type: ${consentType}:${consentValue}"
      echo "\"${appname}\",\"${appid}\",\"${consentPurpose}\",\"${consentType}\",\"${consentValue}\",\"${ownerMailList}\"" >> "${reportdir}/app-consents.csv"
    done
  fi

  # print space and increment app counter
  echo
  counter=$((counter+1))
done
