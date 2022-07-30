#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7

# 从A仓库克隆项目，清除提交历史及git服务器信息，然后设置、创建、推送新项目在服务器B上


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
    git clone  git@${HOSTA}:${HOSTA_GROUP}/${PJ}.git
    cd ${PJ}
    git checkout master
    rm -rf .git
    git init
    # 这样就能在服务器端创建不存在的新项目
    git remote add origin  git@${HOSTA}:${HOSTA_GROUP}/${PJ}.git
    git add -A
    git commit -m "init and first commit"
    git push origin master
    cd ..
    echo
    echo
done



