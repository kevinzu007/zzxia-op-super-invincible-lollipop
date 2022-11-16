#!/bin/bash


# 镜像名称与版本
IMAGE_NAME=rabbitmq
VER=3.11-management


# docker官方仓库（默认，一般不用改）
DOCKER_REPO=docker.io/library


# pull、tag并push
docker pull  ${DOCKER_REPO}/${IMAGE_NAME}:${VER}
docker tag   ${DOCKER_REPO}/${IMAGE_NAME}:${VER}   ${IMAGE_NAME##*/}:latest
./../deploy/docker-tag-push.sh  --tag ${VER}       ${IMAGE_NAME##*/}
./../deploy/docker-tag-push.sh                     ${IMAGE_NAME##*/}


