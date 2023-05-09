#!/bin/bash

# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
DOCKER_IMAGE_TAG=$(date -d "${TIME}" +%Y.%m.%d.%H%M%S)
DOCKER_IMAGE_NAME='fluentd-gcl'

#
echo "开始构建"
docker build -t ${DOCKER_IMAGE_NAME} ./
if [[ $? -ne 0 ]]; then
    echo "猪猪侠警告：镜像【${DOCKER_IMAGE_NAME}】构建失败，请检查！"
    exit 1
fi

#
echo "开始推送到仓库"
bash ../../../deploy/docker-tag-push.sh  --pre-name public  --tag ${DOCKER_IMAGE_TAG}  ${DOCKER_IMAGE_NAME}
if [[ $? -ne 0 ]]; then
    echo "猪猪侠警告：镜像【${DOCKER_IMAGE_NAME}】推送失败，请检查！"
    exit 1
fi

#
echo -e "搞定！\n"


