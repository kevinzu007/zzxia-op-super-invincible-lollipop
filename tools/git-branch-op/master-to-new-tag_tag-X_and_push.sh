#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7

set -e
set -o

GIT_SERVER='g.zj.lan'
GIT_GROUP='gc'


if [ x$1 = x -o x$1 = 'x-h'  -o x$1 = 'x--help' ]; then
    echo -e "\n用途：基于master分支创建新的tag。\n\n须提供版本号参数！\n例如： $0 v1.0，则新tag的名字为【tag-v1.0】\n"
    exit
fi
TAG_VER=$1



i=0
for PJ in `cat ./project.list`
do
    i=`expr $i + 1`
    echo ${i}: ============ ${PJ} ============
    [ -d ${PJ} ] && rm -rf  ${PJ}
    git clone -b master  git@${GIT_SERVER}:${GIT_GROUP}/${PJ}.git
    cd ${PJ}
    git tag tag-${TAG_VER}
    git push origin tag-${TAG_VER}
    cd ..
    echo
    echo
done



