#!/bin/bash

# 请根据自己的需要修改，或手动安装


SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"


./build-envs/java/install-java.sh
./build-envs/maven/install-maven.sh
./build-envs/node/install-node.sh


