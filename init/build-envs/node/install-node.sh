#!/bin/bash

SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"


rm -rf /opt/node-v*


if [[ ! $(ll *.xz | awk '{print $9}' | head -n 1) =~ node-v.*-linux-x64.tar.xz ]]; then
    echo -e "\n猪猪侠警告：未找到java安装文件【node-v*-linux-x64.tar.xz】，请自行下载到目录【${SH_PATH}】\n"
    exit 1
fi
cp -r  node-v*-linux-x64.tar.xz  /opt/
cp -r  node-env.sh               /etc/profile.d/


cd "/opt"
[ -L node ] && rm  -rf node
tar Jxf node-v*-linux-x64.tar.xz
rm -f  node-v*-linux-x64.tar.xz
ln -s  node-v*-linux-x64  node

echo
echo  "你需要执行以生效： . /etc/profile"


