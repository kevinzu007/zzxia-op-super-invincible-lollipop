#!/bin/bash

SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"


rm -rf /opt/apache-maven-*


if [[ ! $(ls -l *.gz | awk '{print $9}' | head -n 1) =~ apache-maven-.*-bin.tar.gz ]]; then
    echo -e "\n猪猪侠警告：未找到java安装文件【apache-maven-*-bin.tar.gz】，请自行下载到目录【${SH_PATH}】\n"
    exit 1
fi
cp -rf  apache-maven-*-bin.tar.gz  /opt/
cp -rf  maven-env.sh               /etc/profile.d/
cp -rf ./maven-conf/*    ~/
cp -rf ./maven-conf/.m2  ~/


cd "/opt"
[ -L maven ] && rm  -rf maven
tar zxf  apache-maven-*-bin.tar.gz
rm -f  apache-maven-*-bin.tar.gz
ln -s  apache-maven-*  maven

echo
echo  "你需要执行以生效： . /etc/profile"


