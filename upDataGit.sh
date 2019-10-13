#!/bin/bash
# Sun Oct 13 15:42:19 CST 2019
# 把本地文件推送到git 仓库
export LANG=en_US.UTF-8
SHHOME=$(cd `dirname $0`; pwd)
cd $SHHOME
echo -e "\033[32m----> `pwd` \033[0m"
git add -A
git status
echo -e "\033[32m----> git commit -m "`date +%Y-%m-%d\ %H:%M:%S`"\033[0m"
git commit -m "`date +%Y-%m-%d\ %H:%M:%S`"
echo -e "\033[32m----> git fetch \033[0m"
git fetch
echo -e "\033[32m----> git merge origin/master\033[0m"
git merge origin/master
echo -e "\033[32m----> git push origin master\033[0m"
git push origin master

