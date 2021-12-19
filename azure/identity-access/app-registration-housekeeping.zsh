#!/bin/zsh

# list all azure ad application registrations
# identify those created by disabled accounts
# track & delete those with expired credentials or certificates
# identify those with directory scopes
# the /beta/auditLogs/signIns endpoint is used in attempt to determine if the application is active
# nb: the auditLogs endpoint has a 30 days rolling retention window (regardless of p1/2 sku)

set -e #-x
outdir="out-audits"
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

echo "=================================================================================================="
blue "azure ad application housekeeping"
good "theta.co.nz/cyber 🤖 🔑 🖥️"
echo "=================================================================================================="

if [[ $1 != "audit" && $1 != "kaboom" ]]; then
  echo "usage: $0 audit|kaboom"
  good "audit: dry run, produces report with no changes made"
  warn "kaboom: will delete expired credentials, remove disabled users & delete apps with no valid secrets"
  echo "=================================================================================================="
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  error "jq is required for this script to run"
  green "https://stedolan.github.io/jq/download"
  echo "=================================================================================================="
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  error "azure cli is required for this script to run"
  green "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
  echo "=================================================================================================="
  exit 1
else
  accountcontext=`az account show`
  domain=`echo "${accountcontext}" | jq -r .user.name | cut -d@ -f2`
  tenant_id=`echo "${accountcontext}" | jq -r .tenantId`
  echo "context tenant domain: ${domain}"
  echo "context tenant id: ${tenant_id}"
  echo "=================================================================================================="
fi

# if not running on macos warn user this is untested
if [[ "$(uname)" != "Darwin" ]]; then
  warn "this script has only been tested on macos, proceed with caution"
  echo "=================================================================================================="
fi

if [[ $1 == "kaboom" ]]; then
  if read -q "choice?kaboom mode will delete things r u sure: " &&; then
  demolition=true
  echo
  echo "=================================================================================================="
  else
    echo
    error 'u said no'
    echo "=================================================================================================="
    exit 1
  fi
elif [[ $1 == "audit" ]]; then
  demolition=false
  #exec 1>> log.log
  # get date as DD-MM-YYYY
  today=`gdate +%d-%m-%Y`
  reportdir="${outdir}/${today}"
  # if the report dir already exists, delete it and recreate it
  if [[ -d "${reportdir}" ]]; then
    rm -rf "${reportdir}"
  fi
  mkdir -p "${reportdir}" ||:
  echo "saving findings within ${reportdir}"
  echo "=================================================================================================="
fi

# check we have neccesary permissions to probe ms graph for audit timestamps
set +e
test_fetch_aad_signin_data=`az rest --uri "https://graph.microsoft.com/beta/auditLogs/signIns?top=1" 2> /dev/null`
if [[ $? -eq 1 ]]; then
  error "missing permissions to fetch audit stamps from ms graph"
  error "ensure you have AuditLog.Read.All and Directory.Read.All"
  echo "=================================================================================================="
  exit 1
else
  set -e
fi
# fetch all app registrations
appList=`az ad app list --all`
# count number of apps
appCount=`echo "${appList}" | jq -r '. | length'`
blue "found ${appCount} app registrations"
blue "commencing housekeeping in ${1} mode"
echo "=================================================================================================="
# convert the above json into compact json
appJson=`echo "${appList}" | jq -c '.[]'`
# for each app
counter=1
echo "${appJson}" | grep -v "^$" | while read app ; do
  # parse the relevant fields
  appname=`echo "${app}" | jq -r ".displayName"`
  appid=`echo "${app}" | jq -r ".appId"`
  appPassCreds=`echo "${app}" | jq -c ".passwordCredentials[]"`
  appKeyCreds=`echo "${app}" | jq -c ".keyCredentials[]"`
  appConsents=`echo "${app}" | jq -c ".oauth2Permissions[]"`
  # create a file for each app based on manifest
  # echo "${app}" | jq -c > "${outdir}/${appid}.json"
  echo "job: ${counter}/${appCount}"
  echo "name: "${appname}""
  echo "id: "${appid}""
  # try fetch a timestamp for the last signin
  last_use_tz=`az rest --uri "https://graph.microsoft.com/beta/auditLogs/signIns?filter=appId eq '"${appid}"'&top=1" | jq -r '.value[].createdDateTime'`
  # if last_use_tz exists
  if [ -z "${last_use_tz}" ]; then
    warn "last signin: unknown"
  else
    good "last signin: "${last_use_tz}""
  fi
  # fetch the owner UPN for the app
  appOwners=`az ad app owner list --id "${appid}" | jq -r '.[].mail'`
  # if the owners list contains null (no owner) - remove it
  appOwners=`echo "${appOwners}" | sed -e 's/null//g'`
  # count the number of owners identified above - do not include null
  ownerCount=`echo "${appOwners}" | grep -v "^$" | wc -l | tr -d "[[:blank:]]"`
  if [[ ${ownerCount} == 0 ]] ; then
    error "no owners associated with this app"
    if [[ ! -f "${reportdir}/no-owners.csv" ]] ; then
      echo "app,id" > "${reportdir}/no-owners.csv"
    fi
    echo "\"${appname}\",\"${appid}\"" >> "${reportdir}/no-owners.csv"
  else
    echo "found "${ownerCount}" owner(s)"
    # for each owner check if account is disabled in AAD
    echo "${appOwners}" | grep -v "^$" | while read owner ; do
    # if the owner does not end with context domain, warn
    if [[ $owner != *"@${domain}" ]] ; then
      warn "owner "${owner}" does not end with context domain, ${domain}"
    else
      upnState=`az ad user show --id "${owner}" --query accountEnabled`
      if [[ $upnState == "false" ]] ; then
        error "owner "${owner}" is a disabled azure ad upn"
        ownerObjectId=`az ad user show --id ${owner} | jq -r ".objectId"`
        if [[ $demolition == true ]] ; then
          # remove the owner from the app
          warn "removing owner "${owner}" from app "${appname}" (${appid})..."
          # we have to fetch the object id of the owner from the upn
          az ad app owner remove --id "${appid}" --owner-object-id "${ownerObjectId}"
        else
          audit "audit mode - skipping owner removal"
          if [[ ! -f "${reportdir}/disabled-owners.csv" ]] ; then
            echo "app,appid,owner,objectId,accountEnabled" > "${reportdir}/disabled-owners.csv"
          fi
          echo "\"${appname}\",\"${appid}\",\"${owner}\",\"${ownerObjectId}\",\"${upnState}\"" >> "${reportdir}/disabled-owners.csv"
        fi
      else
        good "owner "${owner}" is enabled"
      fi
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
    echo "${appPassCreds}\n${appKeyCreds}" | grep -v "^$" | while read cred ; do
      all_credentials_expired=true
      credName=`echo "${cred}" | jq -r '.keyId'`
      credExpiry=`echo "${cred}" | jq -r '.endDate'`
      expDate=`gdate +%s -d "${credExpiry}"`
      if [[ "$(gdate +%s)" -gt "${expDate}" ]] ; then
        error "expired: "${credExpiry}" on "${credName}""
        if [[ $demolition == true ]] ; then
          warn "removing expired credential "${credName}" from app "${appname}" (${appid})..."
          az ad app credential delete --id "${appid}" --key-id "${credName}"
        else
          audit "audit mode - skipping credential removal"
          if [[ ! -f "${reportdir}/expired-credentials.csv" ]] ; then
            echo "app,appid,expiry,credential" > "${reportdir}/expired-credentials.csv"
          fi
          echo "\"${appname}\",\"${appid}\",\"${credExpiry}\",\"${credName}\"" >> "${reportdir}/expired-credentials.csv"
        fi
      elif [[ ${expDate} -gt ${futureDate} ]] ; then
        warn "excessive expiration of "${credExpiry}" on credID "${credName}""
        all_credentials_expired=false
        if [[ ! -f "${reportdir}/excessive-duration-credentials.csv" ]] ; then
          echo "app,appid,credential,expiry" > "${reportdir}/excessive-duration-credentials.csv"
        fi
        echo "\"${appname}\",\"${appid}\",\"${credName}\",\"${credExpiry}\"" >> "${reportdir}/excessive-duration-credentials.csv"
      else
        good "credential "${credName}" expires "${credExpiry}""
        all_credentials_expired=false
      fi
      if [[ $all_credentials_expired == true ]] ; then
        error "all credentials are expired"
        if [[ $demolition == true ]] ; then
          error "deleting app "${appname}" with ID "${appid}""
          az ad app delete --id $appid ||:
        else
          audit "audit mode - skipping app deletion"
          if [[ ! -f "${reportdir}/expired-apps.csv" ]] ; then
            echo "app,appid,expiry,keyId" > "${reportdir}/expired-apps.csv"
          fi
          echo "\"${appname}\",\"${appid}\",\"${credExpiry}\",\"${credName}\"" >> "${reportdir}/expired-apps.csv"
        fi
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
      # consentName=`echo "${consent}" | jq -r '.adminConsentDisplayName' | awk '{print tolower($0)}'`
      consentPurpose=`echo "${consent}" | jq -r '.adminConsentDescription' | awk '{print tolower($0)}'`
      consentType=`echo "${consent}" | jq -r '.type' | awk '{print tolower($0)}'`
      consentValue=`echo "${consent}" | jq -r '.value' | awk '{print tolower($0)}'`
      echo "purpose: ${consentPurpose}"
      echo "type: ${consentType}:${consentValue}"
    done
  fi
  echo "=================================================================================================="
  counter=$((counter+1))
done
