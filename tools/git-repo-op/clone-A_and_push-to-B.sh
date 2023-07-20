#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7


# 从A仓库克隆项目，然后创建、推送新项目到服务器B上


set -e
set -o

# A
HOSTA='g.zj.lan'
HOSTA_GROUP='gc'

# B
HOSTB='g.th.cn'
HOSTB_GROUP='c1801'


for PJ in `cat ./project.list`
do
    echo ============ ${PJ} ============
    git clone --mirror  git@${HOSTA}:${HOSTA_GROUP}/${PJ}.git
    cd ${PJ}.git/
    # 换名字
    #PJ=`echo ${PJ/gce/pufi}`
    # 如果没有目标项目仓库，自动创建目标仓库
    git push --mirror  git@${HOSTB}:${HOSTB_GROUP}/${PJ}.git
    cd ..
    echo
    echo
done



