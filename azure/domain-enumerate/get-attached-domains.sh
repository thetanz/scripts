#!/bin/bash

# credit to @DrAzureAD (Nestori Syynimaa)
# https://github.com/Gerenios/AADInternals/blob/fd6474e840f457c32a297cadbad051cabe2a019b/AccessToken_utils.ps1#L1682-L1684

if ! xq --help > /dev/null 2>&1; then
    echo "xq not found in path"
    echo "see https://kislyuk.github.io/yq/"
    exit 1
fi

if [[ -z "$1" ]]; then
  echo "usage: ./get-attached-domains.sh <target domain>"
  exit 1
fi

export TARGETDOMAIN=${1}
POST_DATA_XML=$(envsubst < ./template-post.xml)

curl -s -X POST \
-H 'Content-Type: text/xml; charset=utf-8' \
-H 'SOAPAction: http://schemas.microsoft.com/exchange/2010/Autodiscover/Autodiscover/GetFederationInformation' \
-H 'User-Agent: AutodiscoverClient' \
'https://autodiscover-s.outlook.com/autodiscover/autodiscover.svc' \
--data "${POST_DATA_XML}" \
| xq '."s:Envelope"."s:Body".GetFederationInformationResponseMessage.Response.Domains.Domain[]' -r
