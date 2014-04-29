#!/bin/bash

set -e

./scripts/grvToFav.sh -e benjamin.fradet@gmail.com -s 256

jekyll build --config _config.yml
git add -f _site/
git diff --cached --exit-code _site/ > /dev/null ||
    git commit -m "Publish `date -u`" _site/
git push --force origin master
