#!/bin/bash


# 镜像名称与版本
IMAGE_SERVER=''
NAME_SPACE='styletang'
IMAGE_NAME='rocketmq-console-ng'
VER='1.0.0'


# 命名空间
if [[ -n ${NAME_SPACE} ]]; then
    IMAGE_NAME="${NAME_SPACE}/${IMAGE_NAME}"
fi

# 镜像服务器
if [[ -n ${IMAGE_SERVER} ]]; then
    IMAGE_NAME="${IMAGE_SERVER}/${IMAGE_NAME}"
fi

# 版本
if [[ -z ${VER} ]]; then
    VER=latest
fi


# pull、tag
docker pull  ${IMAGE_NAME}:${VER}
docker tag   ${IMAGE_NAME}:${VER}   ${IMAGE_NAME##*/}:latest
# push
../../deploy/docker-tag-push.sh  --tag ${VER}  ${IMAGE_NAME##*/}
../../deploy/docker-tag-push.sh                ${IMAGE_NAME##*/}

