#!/bin/bash

SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"


rm -rf /opt/jdk*


if [[ ! $(ll *.gz | awk '{print $9}' | head -n 1) =~ jdk-.*-linux-x64.tar.gz ]]; then
    echo -e "\n猪猪侠警告：未找到java安装文件【jdk-*-linux-x64.tar.gz】，请自行下载到目录【${SH_PATH}】\n"
    exit 1
fi
cp -f  jdk-*-linux-x64.tar.gz  /opt/
cp -f  java-env.sh             /etc/profile.d/


cd "/opt"
[ -L java ] && rm  -rf java
tar zxf  jdk-*-linux-x64.tar.gz
rm -f jdk-*-linux-x64.tar.gz
ln -s  jdk*  java


echo
echo  "你需要执行以生效： . /etc/profile"


