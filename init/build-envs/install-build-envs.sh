#!/bin/bash

# 请根据自己的需要修改，或手动安装


SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"


./java/install-java.sh
./maven/install-maven.sh
./node/install-node.sh


