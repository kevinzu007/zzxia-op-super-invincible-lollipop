#!/bin/bash

#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"



# 引入env
.  ./user.env.sec



if [[ ! -f ${USER_DB_FILE} ]]; then
    echo -e  "\n猪猪侠警告：USER_DB_FILE 文件不存在，请先参考模板创建！\n"
fi
#
if [[ ! -f ${USER_TOKEN_FILE} ]]; then
    touch  ${USER_TOKEN_FILE}
fi


# 用法：
F_HELP()
{
    echo "
    用途：用于生成并更新用户密码列。
    依赖：
    注意：请使用编辑器手动添加用户基本信息后，再使用本程序！
    用法:
        $0  [-h|--help]
        $0  [{用户名}]  [{用户口令}]
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
    示例:
        #
        $0  --help
        $0  jack  jackpasswd        #--- 用生成用户密码
        #
        "
}



if [[ $# -le 1 ]] || [[ $1 == '-h' ]] || [[ $1 == '--help' ]]; then
    F_HELP
    echo -e "\n猪猪侠提醒：请参考帮助使用！\n"
    exit
fi


USER_NAME=$1
USER_PASSWORD=$2


GET_IT='N'
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    F_USER_NAME=`echo ${LINE} | awk -F '|' '{print $3}'`
    F_USER_NAME=`echo ${F_USER_NAME}`
    #
    F_USER_SALT=`echo ${LINE} | awk -F '|' '{print $6}'`
    F_USER_SALT=`echo ${F_USER_SALT}`
    #
    if [[ ${F_USER_NAME} == ${USER_NAME} ]]; then
        # secret
        #
        USER_SALT=$(echo ${RANDOM} | md5sum | cut -c 1-10)
        #
        USER_SECRET_sha1=$(echo -n "${USER_NAME}${USER_PASSWORD}" | sha1sum | awk '{print $1}')
        USER_SECRET_sha1_30=${USER_SECRET_sha1:2:30}                             #--- 与webhook-server.py保持一致
        USER_SECRET_sha256=$(echo -n "${USER_SALT}${USER_SECRET_sha_30}" | sha256sum | awk '{print $1}')
        USER_SECRET_sha256_50=${USER_SECRET_sha256:3:50}                         #--- 与webhook-server.py保持一致
        USER_SECRET=${USER_SECRET_sha256_50}
        #
        #sed -i -E "s/(\|[ ]*[0-9]+[ ]*\|[ ]*${USER_NAME}[ ]*\|.+\|.+\|).+\|.+\|$/\1 ${USER_SALT} \| ${USER_SECRET} \|/"  ${USER_DB_FILE}
        sed -i -E "s/(\|[ ]*[0-9]+[ ]*\|[ ]*${USER_NAME}[ ]*\|.+\|.+\|).+\|.+\|$/\1 ${USER_SALT} \| ${USER_SECRET} \|/"  ${USER_DB_FILE}
        UPDATE_1=$?
        #
        # token
        #
        USER_TOKEN=$(echo ${RANDOM} | sha1sum | awk '{print $1}')
        #
        #sed -i -E "s/^${USER_NAME} .*$/${USER_NAME} ${USER_TOKEN}/"  ${USER_TOKEN_FILE}
        sed -i -E "/^${USER_NAME} .*$/d"  ${USER_TOKEN_FILE}
        echo "${USER_NAME} ${USER_TOKEN}"  >>  ${USER_TOKEN_FILE}
        UPDATE_2=$?
        if [[ ${UPDATE_1} -eq 0 ]] && [[ ${UPDATE_2} -eq 0 ]]; then
            echo -e "\n猪猪侠提醒：【${USER_DB_FILE}】和【 ${USER_TOKEN_FILE}】更新成功\n"
        else
            echo -e "\n猪猪侠警告：【${USER_DB_FILE}】或【${USER_TOKEN_FILE}】更新失败\n"
        fi
        GET_IT='Y'
        break
    fi
done < "${USER_DB_FILE}"


if [[ ${GET_IT} != 'Y' ]]; then
    echo -e "\n猪猪侠警告：【${USER_DB_FILE}】中用户不存在，请使用编辑器手动添加基本信息，然后再用此脚本添加盐和密码！\n"
fi


