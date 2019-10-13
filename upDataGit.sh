#!/bin/bash -v
git add .
git commit -m "更新说明"
git fetch
git merge origin/master
git merge
git pull origin master --allow-unrelated-histories
git push origin master
git push origin HEAD:master
