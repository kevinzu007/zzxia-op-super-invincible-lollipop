#!/bin/bash


VER=v2.1.2


docker pull  nacos/nacos-server:${VER}
docker tag  nacos/nacos-server:${VER}  nacos-server:latest
../../deploy/docker-tag-push.sh  --tag ${VER}  nacos-server
../../deploy/docker-tag-push.sh  nacos-server



