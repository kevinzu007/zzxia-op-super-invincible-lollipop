#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 引入/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
# 检测 MY_PRIVATE_ENVS_DIR 是否存在，不存在则主动加载环境变量（非终端界面不会自动引入）
if [ -z "${RUN_ENV}" ]; then
    if [ -f /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh ]; then
        . /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
    fi
fi
# 引入使用：
#MY_PRIVATE_ENVS_DIR=

# 引入env
. ${SH_PATH}/env.sh
# 来自 ${MY_PRIVATE_ENVS_DIR} 目录下的 *.sec
#DOCKER_REPO_SERVER=
#DOCKER_REPO_USER=
#DOCKER_REPO_PASSWORD=

# 本地env
TIME=${TIME:-`date +%Y-%m-%dT%H:%M:%S`}
TIME_START=${TIME}


# login
#echo "${DOCKER_REPO_PASSWORD}" | docker login -u "$DOCKER_REPO_USER" --password-stdin  ${DOCKER_REPO_SERVER}
ansible  docker  -m shell  -a "echo ${DOCKER_REPO_PASSWORD} | docker login -u ${DOCKER_REPO_USER} --password-stdin  ${DOCKER_REPO_SERVER}"



