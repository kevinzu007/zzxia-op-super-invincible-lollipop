#!/bin/bash


# 镜像名称与版本
IMAGE_NAME=neo4j
VER=5.1


# docker官方仓库（官方默认）
DOCKER_REPO=docker.io/library


# pull、tag并push
docker pull  ${DOCKER_REPO}/${IMAGE_NAME}:${VER}
docker tag   ${DOCKER_REPO}/${IMAGE_NAME}:${VER}   ${IMAGE_NAME##*/}:latest
./../deploy/docker-tag-push.sh  --tag ${VER}       ${IMAGE_NAME##*/}
./../deploy/docker-tag-push.sh                     ${IMAGE_NAME##*/}


