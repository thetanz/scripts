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

while read line; do
    prips $line >> $2
done < $1
