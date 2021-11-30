#!/bin/bash
# create a README.md with scripts definitions

set -e

scriptsdir=`git rev-parse --show-toplevel`/sbin
cd ${scriptsdir}

echo '''# setup

save this repo to `~/scripts`  

```shell
git clone https://github.com/thetanz/scripts.git
```

run `scripts/sbin/paths.sh` to add `scripts/sbin` to your `~./zshrc`

# doco
''' > README.md

for file in *
do
  if [ "${file}" != "README.md" ]; then
    filetype=`file ${file} | cut -d ' ' -f 2`
    if [ "${filetype}" == "Bourne-Again" ]; then
      definition=`cat $file | sed -n '2p'`
      echo "## ${file}" >> README.md
      echo "" >> README.md
      description=`echo ${definition} | sed 's/# //g'` >> README.md
      echo "_${description}_" >> README.md
      echo "" >> README.md
    fi
  fi
done
