#!/bin/bash

# https://cli.github.com
# https://github.com/cli/cli

if ! [ "$(id -u)" = 0 ]; then
  printf "needs root!"
  exit 0
fi

VERSION=`curl -s "https://api.github.com/repos/cli/cli/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c2-`
wget https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_amd64.tar.gz
tar xvf gh_${VERSION}_linux_amd64.tar.gz
sudo cp gh_${VERSION}_linux_amd64/bin/gh /usr/local/bin/
