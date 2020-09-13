#!/bin/bash
# Sun Oct 13 15:42:19 CST 2019
# 把本地文件推送到git 仓库
SHHOME=$(cd `dirname $0`; pwd)
cd $SHHOME
echo "shell run PID : $$"
cat > README.md << EOF
# kubernetes

#### 介绍
kubernetes 资源清单文件

#### git创建ssh通道，避免每次都输密码

https://blog.csdn.net/lvdepeng123/article/details/79215882

\`\`\`
`tree -N`
\`\`\`
EOF

export LANG=en_US.UTF-8
SHHOME=$(cd `dirname $0`; pwd)
cd $SHHOME
echo -e "\033[32m----> `pwd` \033[0m"
git add .
git status

echo -e "\033[32m----> git commit -m "`date +%Y-%m-%d\ %H:%M:%S`"\033[0m"
git commit -m "`date +%Y-%m-%d\ %H:%M:%S`"

echo -e "\033[32m----> git push origin master \033[0m"
git push origin master
