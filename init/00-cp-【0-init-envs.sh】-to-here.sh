#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7


# 此文件请根据你自己环境需要的文件进行增删



TIME=`date +%Y-%m-%dT%H:%M%S`
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}


# 默认运行环境相关文件所在目录
ENVS_FILE_DIR="${SH_PATH}/envs.sample"



# 用法：
F_HELP()
{
    echo "
    用法:
    sh $0  [-h|--help]
    sh $0  {Path-To-envs文件目录}    #--- 拷贝envs目录中的【0-init-envs.sh】到当前目录
    "
}



# 参数检查
if [[ $# -eq 0 ]]; then
    echo -e "\n猪猪侠警告：参数缺失，请查看帮助【$0 --help】\n"
    exit 1
fi


# help
if [[ $1 == '-h' ]] || [[ $1 == '--help' ]]; then
    F_HELP
    exit 0
fi


# go
ENVS_FILE_DIR=$1
ENVS_FILE_DIR=${ENVS_FILE_DIR%*/}
if [[ ! -f ${ENVS_FILE_DIR}/0-init-envs.sh ]]; then
    echo -e "\n猪猪侠警告：目录【${ENVS_FILE_DIR}】不存在，或目录下不存在文件【0-init-envs.sh】，请检查\n"
    exit 1
fi
#
# cp到init目录
cp -f ${ENVS_FILE_DIR}/0-init-envs.sh  ./0-init-envs.sh
if [[ $? -ne 0 ]]; then
    echo  -e "\n拷贝失败，请检查\n"
    exit 1
else
    echo  -e "\nOK，你现在可以运行【0-init-envs.sh】以实现对环境变量的初始化\n"
fi

