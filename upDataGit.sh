#!/bin/bash -v
# Sun Oct 13 15:42:19 CST 2019
# 把本地文件推送到git 仓库
export LANG=en_US.UTF-8
SHHOME=$(cd `dirname $0`; pwd)
cd $SHHOME
git add -A
git status
git commit -m "`date +%Y-%m-%d\ %H:%M:%S`"
git fetch
git merge origin/master
git push origin master

