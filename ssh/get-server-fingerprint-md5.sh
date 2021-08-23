#!/bin/bash

#####################################################################################
# generating a fingerprint client-side is inherently risky!
# where possible the server operator should provide this to you!
#####################################################################################
# logic apps & power platform only support MD5 fingerprints for host verification
# yes, the rest of the world stopped using md5 fingerprints quite some time ago
# https://docs.microsoft.com/en-us/azure/connectors/connectors-sftp-ssh#prerequisites
#####################################################################################

# source: https://gist.github.com/parsa/b37dd02033718729304ff33af261a67f
# ./ssh-server-fingerprint-md5.sh sftp.uber.com 2222

if [ -z "$1" ]
  then
    printf "fqdn required\nusage: ${0} domain port\n"
    exit 1
fi

if [ -z "$2" ]
  then
    printf "port required\nusage: ${0} domain port\n"
    exit 1
fi

ssh-keyscan -p $2 -t rsa \
$1 2>/dev/null \
| awk '{ print $3 }' \
| base64 -d \
| md5sum \
| awk '{ print $1 }' \
| fold -w2 \
| paste -sd':' -
