#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


set -e

if [[ $# = 0 ]]; then
    echo -e "\n用法：$0  [用户]  [密码]  [主机列表文件] \n"
    exit
fi
#
if [[ $1 == -h || $1 == --help ]]; then
    echo -e "\n用法：$0  [用户]  [密码]  [主机列表文件] \n"
    exit
fi

#
export USER=$1
export SSHPASS=$2
HOST_FILE=$3
#
if [ ! -f ${HOST_FILE} ]; then
    echo -e "\n文件【${HOST_FILE}】不存在\n"
    exit
fi


cat ${HOST_FILE} | while read HOST ; do
    sshpass -e  ssh-copy-id  -o StrictHostKeyChecking=no  ${USER}@${HOST}
    #sshpass -p ${SSHPASS}  ssh-copy-id  -o StrictHostKeyChecking=no  ${USER}@${HOST}
done



