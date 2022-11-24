#!/bin/bash


# 镜像名称与版本
IMAGE_NAME=rabbitmq
VER=3.11-management


# pull、tag
docker pull  ${IMAGE_NAME}:${VER}
docker tag   ${IMAGE_NAME}:${VER}   ${IMAGE_NAME##*/}:latest
# push
./../deploy/docker-tag-push.sh  --tag ${VER}  ${IMAGE_NAME##*/}
./../deploy/docker-tag-push.sh                ${IMAGE_NAME##*/}

