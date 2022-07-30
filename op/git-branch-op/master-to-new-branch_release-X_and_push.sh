#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7

set -e
set -o


GIT_SERVER='g.zj.lan'
GIT_GROUP='gc'




if [ x$1 = x -o x$1 = 'x-h'  -o x$1 = 'x--help' ]; then
    echo -e "\n用途：基于master分支创建新的release分支。\n\n须提供版本号参数！\n例如： $0 v1.0.190101，则新分支的名字为【release-v1.0.190101】\n"
    exit
fi
VER=$1


i=0
for PJ in `cat ./project.list`
do
    i=`expr $i + 1`
    echo ============ ${PJ} ============
    [ -d ${PJ} ] && rm -rf  ${PJ}
    git clone -b master  git@${GIT_SERVER}:${GIT_GROUP}/${PJ}.git
    cd ${PJ}
    # 如果存在远程分支，则退出
    if [ `git branch -r | grep "origin/release-${VER}"` > /dev/null 2>&1 ]; then
        echo "分支release-${VER}已存在，请检查"
        exit 1
    fi
    git checkout -b release-${VER}
    git push  --set-upstream origin release-${VER}
    cd ..
    echo
    echo
done


