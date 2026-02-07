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


# 本地env
USER_DB_FILE="./user.db"


# 用法：
F_HELP()
{
    echo "
    用途：用于生成或更新用户密码
    特征码：
        ${GAN_WHAT_FUCK:-'未命名'}
    权限要求：
        ${NEED_PRIVILEGES:-'未指定'}
    依赖：
    注意：请使用编辑器手动添加用户基本信息后，再使用本程序！也可以使用fuckingdoit/user-maname.sh实现。
    用法:
        $0  [-h|--help]
        $0  <用户名>
    参数规范：
        无包围符号 ：-a                : 必选【选项】
                   ：val               : 必选【参数值】
                   ：val1 val2 -a -b   : 必选【选项或参数值】，且不分先后顺序
        []         ：[-a]              : 可选【选项】
                   ：[val]             : 可选【参数值】
        <>         ：<val>             : 需替换的具体值（用户必须提供）
        %%         ：%val%             : 通配符（包含匹配，如%error%匹配error_code）
        |          ：val1|val2|<valn>  : 多选一
        {}         ：{-a <val>}        : 必须成组出现【选项+参数值】
                   ：{val1 val2}       : 必须成组的【参数值组合】，且必须按顺序提供
    参数说明：
        \$0   : 代表脚本本身
        -h|--help        此帮助
    示例:
        #
        $0  --help
        $0  jack      #--- 更新用户【jack】的密码
        "
}


#
if [[ $# == 0 ]] || [[ $1 == '-h' ]] || [[ $1 == '--help' ]]; then
    F_HELP
    echo -e "\n猪猪侠提醒：请参考帮助使用！\n"
    exit
fi


# db
if [[ ! -f ${USER_DB_FILE} ]]; then
    echo -e  "\n猪猪侠警告：USER_DB_FILE 文件不存在，请先参考模板创建！\n"
    exit 1
fi


USER_NAME=$1
read  -s -p "请输入用户【${USER_NAME}】新密码："  USER_PASSWORD
echo
read  -s -p "请再次输入新密码："  USER_PASSWORD_2
echo
if [[ ${USER_PASSWORD} != ${USER_PASSWORD_2} ]]; then
    echo -e  "\n猪猪侠警告：两次输入的密码不一致！\n"
    exit 1
fi


# do
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
        USER_SALT=$(echo ${RANDOM} | md5sum | cut -c 1-10)     #--- 取10，即1-10
        #
        USER_SECRET_sha1=$(echo -n "${USER_NAME}${USER_PASSWORD}" | sha1sum | awk '{print $1}')
        USER_SECRET_sha1_30=${USER_SECRET_sha1:2:30}                             #--- 与webhook-server.py保持一致，从第3位开始，取30位，即3-32
        USER_SECRET_sha256=$(echo -n "${USER_SALT}${USER_SECRET_sha1_30}" | sha256sum | awk '{print $1}')
        USER_SECRET_sha256_50=${USER_SECRET_sha256:3:50}                         #--- 与webhook-server.py保持一致，从第4位开始，取50位，即4-53
        USER_SECRET=${USER_SECRET_sha256_50}
        #
        sed -i -E "s/(\|[ ]*[0-9]+[ ]*\|[ ]*${USER_NAME}[ ]*\|.+\|.+\|).+\|.+\|(.+\|)$/\1 ${USER_SALT} \| ${USER_SECRET} \|\2/"  ${USER_DB_FILE}
        UPDATE_1=$?
        if [[ ${UPDATE_1} -eq 0 ]]; then
            echo -e "\n猪猪侠提醒：用户【${USER_NAME}】密码更新成功\n"
        else
            echo -e "\n猪猪侠警告：用户【${USER_NAME}】密码更新失败\n"
        fi
        GET_IT='Y'
        break
    fi
done < "${USER_DB_FILE}"


if [[ ${GET_IT} != 'Y' ]]; then
    echo -e "\n猪猪侠警告：【${USER_DB_FILE}】中用户【${USER_NAME}】不存在，请使用编辑器手动添加基本信息，然后再用此脚本添加用户盐和密码！\n"
fi


