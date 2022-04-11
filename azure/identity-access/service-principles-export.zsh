#!/bin/zsh

# exports all azure ad service principles 'sp-export/YYYY-MM-DD/json'
# nd: we suppress all existing az cli warnings because, while it's deprecated, there's no alternative

## OUTPUT CSVs
# sp-review.csv: one line per service principle
# errors.log: service principles which failed to be parsed

## TODO
## expired-credentials.csv: one line per expired credential per application
## app-consents.csv: one line per consent provided to an application
## disabled-owners.csv: one line per disabled owner of an application
## excessive-duration-credentials.csv: one line per application credential with an expiry +2years away
## non-theta-owners.csv: one line per owner of an application which is not correctly domain owned
## admin-theta-owners.csv: one line per owner of an application which is using their ADASH account

## NOTES
## These are Tenant IDs for Microsoft Applications
# f8cdef31-a31e-4b4a-93e4-5f571e91255a	Microsoft Service	From MS AAD Service
# 72f988bf-86f1-41af-91ab-2d7cd011db47	Microsoft		From MS
# 9188040d-6c67-4c5b-b112-36a304b66dad	MSA Created		Not created through Azure AD


set -e
outdir="sp-export"
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
blue "azure ad serivce principles export"
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
echo "\"sp-name\",\"sp-id\",\"sp-object-id\",\"sp-tenant-id\",\"sp-type\",\"sp-owners\",\"sp-keys\",\"sp-passwords\",\"sp-roles\",\"sp-oauthperms\"" > "${reportdir}/sp-review.csv"


# check we have neccesary permissions to probe ms graph for audit timestamps
set +e
az rest --uri "https://graph.microsoft.com/beta/auditLogs/signIns?top=1" > "${jsondir}/last-ad-signin.json"
if [[ ! -s "${jsondir}/last-ad-signin.json" ]]; then
  error "missing permissions to fetch audit stamps from ms graph"
  error "ensure you have AuditLog.Read.All and Directory.Read.All"
  exit 1
fi
set -e


# fetch and count all service principles
blue "Fetching a list of all Service Principles..."
az ad sp list --all 2>/dev/null > "${reportdir}/all-sp.json"
if [[ -s "${reportdir}/all-sp.json" ]] ; then
appCount=`jq -r '. | length' "${reportdir}/all-sp.json"`
echo "Found ${appCount} service principles"
echo
else
echo "Could not export service principle list" >&2
exit 1
fi

counter=0
# for each sp
jq -c '.[]' "${reportdir}/all-sp.json" | while read sp ; do
  counter=$((counter+1))
  echo "appcounter: ${counter}/${appCount}"

  # check we can parse the response
  set +e
  canjson=$( echo -E "${sp}" | jq .)
  if [[ $? != 0 ]] ; then
    error "Failed parse this SP, saving to errors.log"
    echo "${sp}" >> "${reportdir}/errors.log"
    echo
    continue
  fi
  set -e

  # parse the relevant fields
  appname=`echo -E "${sp}" | jq -r ".appDisplayName"`
  # managed IDs seem to use displayName instead of appDisplayName
  if [[ "${appname}" == "null" ]] ; then
    appname=`echo -E "${sp}" | jq -r ".displayName"`
  fi
  appid=`echo -E "${sp}" | jq -r ".appId"`
  apptype=`echo -E "${sp}" | jq -r ".servicePrincipalType"`
  appobjectid=`echo -E "${sp}" | jq -r ".objectId"`
  apptenantid=`echo -E "${sp}" | jq -r ".appOwnerTenantId"`
  echo "appname: ${appname}"
  echo "appid: ${appid}"

  # count array fields of interest
  appkeycreds=`echo -E "${sp}" | jq -r ".keyCredentials | length"`
  apppasscreds=`echo -E "${sp}" | jq -r ".passwordCredentials | length"`
  approles=`echo -E "${sp}" | jq -r ".appRoles | length"`
  appoauthperms=`echo -E "${sp}" | jq -r ".oauth2Permissions | length"`

  # create a file for each app based on manifest
  echo -E "${sp}" | jq -c > "${jsondir}/${appid}.json"

  # fetch the owner UPN for the app
  appOwners=$( az ad sp owner list --id "${appobjectid}" 2>/dev/null | jq -c '.[] // empty' )
  ownerCount=$( echo -E "${appOwners}" | grep -v "^$" | wc -l | tr -d "[[:blank:]]" )
  ownerMailList=$( echo -E "${appOwners}" | jq -r '.mail // empty ' | grep -v "^$" | tr '\n' ' ' )

  echo "\"${appname}\",\"${appid}\",\"${appobjectid}\",\"${apptenantid}\",\"${apptype}\",\"${ownerCount}\",\"${appkeycreds}\",\"${apppasscreds}\",\"${approles}\",\"${appoauthperms}\"" >> "${reportdir}/sp-review.csv"

  # print space and increment app counter
  echo
done

