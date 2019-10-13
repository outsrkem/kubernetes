#!/bin/bash
export LANG=en_US.UTF-8
SHHOME=$(cd `dirname $0`; pwd)
cd $SHHOME
git add -A
git status
git commit -m "`date +%Y-%m-%d\ %H:%M:%S`"
git fetch
git merge origin/master
git push origin master

