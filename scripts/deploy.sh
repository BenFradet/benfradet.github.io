#!/bin/bash

set -e

if [ -e favicon.ico ]
then
    git rm -f favicon.ico
fi
if [ -e _site/favicon.ico ]
then
    git rm -f _site/favicon.ico
fi

./scripts/grvToFav.sh -e benjamin.fradet@gmail.com -s 256

jekyll build --config _config.yml
git add -A
git commit -m "Publish `date -u`"
git push --force origin master
