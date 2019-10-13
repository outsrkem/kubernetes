#!/bin/bash
git add .
git commit -m "更新说明-`date +%Y-%m-%d\ %H:%M:%S`"
git fetch
git merge origin/master
git push origin master

