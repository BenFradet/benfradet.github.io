#!/bin/bash

set -e

grvToFav.sh benjamin.fradet@gmail.com 256

jekyll build --config _config.yml
git add -f _site/
git diff --cached --exit-code _site/ > /dev/null ||
    git commit -m "Publish `date -u`" _site/
git push --force origin master
