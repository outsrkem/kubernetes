#!/bin/bash -v
git add .
git commit -m "更新说明"
git fetch
git merge origin/master
git push origin master

