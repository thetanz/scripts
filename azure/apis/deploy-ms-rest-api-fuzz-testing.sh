#!/bin/bash

set -e

# review github.com/microsoft/rest-api-fuzz-testing/blob/main/docs/how-to-use-github-workflow.md
# ./deploy-ms-rest-api-fuzz-testing.sh <your subscription id> <instance-name> <environment-tag>

# you will need to add a policy exemption to bypass tagging requirements in some environments
# portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Exemptions

if [[ -z "${2}" ]] ; then
    printf 'subscription id: ' && read SUB_ID
    printf 'deployment name: ' && read PREFIX
    printf 'environment (dev/prod): ' && read TAG_ENVIRONMENT
    printf 'location: ' && read LOCATION
else
    SUB_ID="${1}"
    PREFIX="${2}"
    TAG_ENVIRONMENT="${3}"
    LOCATION="${4}"
fi

TAG_PURPOSE="Rest API Fuzzing Fuzzing - Microsoft RAFT"

gh repo clone microsoft/rest-api-fuzz-testing
echo '{
    "subscription": "'${SUB_ID}'",
    "deploymentName": "'${PREFIX}'",
    "region": "australiaeast",
    "metricsOptIn": false,
    "isDevelop": false,
    "isPrivateRegistry": false,
    "useAppInsights": true,
    "registry": "mcr.microsoft.com"
}' | tee rest-api-fuzz-testing/cli/defaults.json | jq

pip3 install -r rest-api-fuzz-testing/cli/requirements.txt

python3 rest-api-fuzz-testing/cli/raft.py \
--defaults-context-path rest-api-fuzz-testing/cli/defaults.json \
service deploy --sku B1

#get values for tags
TAG_OWNER=`az ad signed-in-user show --query mailNickname --output tsv`
TAG_REVIEWDATE=`date -v +1y '+%Y-%m'`
TAG_PRACTICE=`az ad signed-in-user show --query department --output tsv`

# get resource id's and iterate them patching on tags where possible
resourcegroupid=`az group show --name ${PREFIX}-raft --query id --output tsv`
resourceids=`az resource list --resource-group ${PREFIX}-raft --query '[].id' --output tsv`
resourcesToTag="${resourcegroupid}\n${resourceids}"

for resource in $resourcesToTag
do
    az tag create --resource-id "${GROUP_ID}" \
    --tags \
    Purpose="${TAG_PURPOSE}" \
    Practice="${TAG_PRACTICE}" \
    Owner="${TAG_OWNER}" \
    ReviewDate="${TAG_REVIEWDATE}" \
    Environment="${ENVIRONMENT}" \
    ProjectLink="github.com/microsoft/rest-api-fuzz-testing"
    | jq
done
