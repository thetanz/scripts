#!/bin/bash

# ./test-website-speed.sh theta.co.nz

if [ -z "${1}" ]
  then
    printf "domain name required\n"
    echo ''${0}' theta.co.nz'
    exit 1
fi

curl -s -w \
'Testing Website Response Time for :%{url_effective}\n
Lookup Time:\t\t%{time_namelookup}
Connect Time:\t\t%{time_connect}
AppCon Time:\t\t%{time_appconnect}
Redirect Time:\t\t%{time_redirect}
Pre-transfer Time:\t%{time_pretransfer}
Start-transfer Time:\t%{time_starttransfer}\n
Total Time:\t\t%{time_total}\n' \
-o /dev/null ${1}
