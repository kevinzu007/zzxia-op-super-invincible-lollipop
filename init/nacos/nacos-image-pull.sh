#!/bin/bash


# 镜像名称与版本
IMAGE_NAME=nacos/nacos-server
VER=v2.1.2


# pull、tag
docker pull  ${IMAGE_NAME}:${VER}
docker tag   ${IMAGE_NAME}:${VER}   ${IMAGE_NAME##*/}:latest
# push
./../../deploy/docker-tag-push.sh  --tag ${VER}  ${IMAGE_NAME##*/}
./../../deploy/docker-tag-push.sh                ${IMAGE_NAME##*/}


