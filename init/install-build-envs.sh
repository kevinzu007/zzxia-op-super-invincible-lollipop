#!/bin/bash

SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"


./build-envs/java/install-java.sh
./build-envs/maven/install-maven.sh
./build-envs/node/install-node.sh


