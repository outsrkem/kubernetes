#!/bin/bash
SHHOME=$(cd `dirname $0`; pwd)
cd $SHHOME
git add .
git commit -m "`date +%Y-%m-%d\ %H:%M:%S`"
git fetch
git merge origin/master
git push origin master

