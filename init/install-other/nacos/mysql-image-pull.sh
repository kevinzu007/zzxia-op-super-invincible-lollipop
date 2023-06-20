#!/bin/bash


# 镜像名称与版本
DOCKER_REPO_SERVER=''
DOCKER_IMAGE_NAMESPACE=''
DOCKER_IMAGE_NAME=mysql
DOCKER_IMAGE_TAG='5.7'



# Docker官方默认
DOCKER_REPO_NAME="${DOCKER_IMAGE_NAME}"

# 命名空间
if [[ -n ${DOCKER_IMAGE_NAMESPACE} ]]; then
    DOCKER_REPO_NAME="${DOCKER_IMAGE_NAMESPACE}/${DOCKER_REPO_NAME}"
fi

# 镜像服务器
if [[ -n ${DOCKER_REPO_SERVER} ]]; then
    DOCKER_REPO_NAME="${DOCKER_REPO_SERVER}/${DOCKER_REPO_NAME}"
fi

# 版本
if [[ -z ${DOCKER_IMAGE_TAG} ]]; then
    DOCKER_IMAGE_TAG='latest'
fi



# pull、tag
docker pull  ${DOCKER_REPO_NAME}:${DOCKER_IMAGE_TAG}
docker tag   ${DOCKER_REPO_NAME}:${DOCKER_IMAGE_TAG}   ${DOCKER_IMAGE_NAME##*/}:latest

# push
echo  "push tag: latest AND ${DOCKER_IMAGE_TAG} ......"
../../deploy/docker-tag-push.sh  --tag ${DOCKER_IMAGE_TAG}  ${DOCKER_IMAGE_NAME##*/}
echo  "push tag: latest AND 默认（当前时间）......"
../../deploy/docker-tag-push.sh                             ${DOCKER_IMAGE_NAME##*/}


