#!/bin/bash

printf 'domain:' && read domainname

if [ -z "$1" ]
  then
    printf "domain name required\n"
    exit 1
fi

dig NS $domainname +short | while read -r line ; do
  printf 'attempting zone txfr on '$domainname', nameserver '$line''
  dig axfr @$line $domainname \
  | grep --invert-match \
  --regexp='; Transfer failed.' \
  --regexp=';; global options: +cmd' \
  --regexp='; <<>> DiG ' \
  --regexp='servers found)'
done
