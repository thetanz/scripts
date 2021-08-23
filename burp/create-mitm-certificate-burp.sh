#!/bin/bash

openssl genrsa -aes256 \
-out newCAburp.key 4096

openssl req -new -x509 \
-days 300 -key newCAburp.key \
-out newCAroot.crt -subj \
/C=CA/O=Burp/OU=Certification Services/CN=MyBURPRootCA/

openssl pkcs12 -export \
-out newCAroot.pfx \
-inkey newCAburp.key \
-in newCAroot.crt
