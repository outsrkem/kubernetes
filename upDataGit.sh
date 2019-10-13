#!/bin/bash
# Sun Oct 13 15:42:19 CST 2019
# 把本地文件推送到git 仓库
export LANG=en_US.UTF-8
SHHOME=$(cd `dirname $0`; pwd)
cd $SHHOME
echo --------------
git add -A
echo --------------
git status
echo --------------
git commit -m "`date +%Y-%m-%d\ %H:%M:%S`"
echo --------------
git fetch
echo --------------
git merge origin/master
echo --------------
git push origin master

