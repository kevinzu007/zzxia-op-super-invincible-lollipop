#/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 引入env
. ${SH_PATH}/env.sh
#DOCKER_REPO=
#DOCKER_REPO_USER=
#DOCKER_REPO_PASSWORD=

# 本地env
TIME=${TIME:-`date +%Y-%m-%dT%H:%M:%S`}
TIME_START=${TIME}


# login
#echo "${DOCKER_REPO_PASSWORD}" | docker login -u "$DOCKER_REPO_USER" --password-stdin  ${DOCKER_REPO}
ansible  docker  -m shell  -a "echo ${DOCKER_REPO_PASSWORD} | docker login -u $DOCKER_REPO_USER --password-stdin  ${DOCKER_REPO}"



