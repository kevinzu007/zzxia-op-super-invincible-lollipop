#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7

set -e
set -o

GIT_SERVER='g.zj.lan'
GIT_GROUP='gc'



if [ x$1 = 'x-h' -o x$1 = 'x--help' ]; then
    echo -e "\n用途：将dev分支合并到master分支。\n\n用法：直接运行即可！\n例如： $0 \n"
    exit
fi


i=0
for PJ in `cat ./project.list`
do
    i=`expr $i + 1`
    echo ${i}: ============ ${PJ} ============
    [ -d ${PJ} ] && rm -rf  ${PJ}
    git clone -b dev  git@${GIT_SERVER}:${GIT_GROUP}/${PJ}.git
    cd ${PJ}
    git checkout master
    git merge --no-ff -m "batch合并分支：from dev to master"  dev
    git push
    cd ..
    echo
    echo
done



