#!/bin/bash

#https://command-not-found.com/prips

#intended usage
#./cidr-to-ip [input] [output]
#./cidr-to-ip cidr_list.txt ip_list.txt

#given an input list of IP's in CIDR format,
#this will output individual IP addresses

#services such as ip2location provide free,
#downloadable lists of CIDR's by country. (IPv4 & IPv6)
#https://www.ip2location.com/free/visitor-blocker

# ensure $1 and $2
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "usage: $0 [input cidrs] [output file]"
    exit 1
fi

#if $1 not a file
if [ ! -f "$1" ]; then
    echo "input 1 must be a file file"
    exit 1
fi

# ensure prips in path
if ! which prips > /dev/null; then
    echo "prips not found in path"
    exit 1
fi

while read line; do
    prips $line >> $2
done < $1
