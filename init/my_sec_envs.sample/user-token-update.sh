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
USER_TOKEN_FILE="./user.db.token"



# 用法：
F_HELP()
{
    echo "
    用途：用于生成或更新用户token
    依赖：
    注意：请在生成用户之后再使用本程序！
    用法:
        $0  [-h|--help]
        $0  [-u|--update]  <{用户名}>     #-- 更新全部用户或指定用户的token
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
        $0  --update          #-- 更新所有用户token
        $0  --update zzxia    #-- 更新用户【zzxia】的token
        #
        "
}


case $1 in
    -h|--help)
        F_HELP
        echo -e "\n猪猪侠提醒：请参考帮助使用！\n"
        exit
        ;;
    -u|--update)
        A_USER_NAME=$2
        ;;
    *)
        echo -e "\n猪猪侠警告：参数错误，请看帮助【$0 --help】\n"
        exit 1
        ;;
esac


#
if [[ ! -f ${USER_DB_FILE} ]]; then
    echo -e  "\n猪猪侠警告：【${USER_DB_FILE}】用户文件不存在，请先参考模板创建！\n"
fi

#
if [[ ! -f ${USER_TOKEN_FILE} ]]; then
    touch  ${USER_TOKEN_FILE}
fi



F_UPDATE()
{
    #
    #sed -i -E "s/^${USER_NAME} .*$/${USER_NAME} ${USER_TOKEN}/"  ${USER_TOKEN_FILE}
    sed -i -E "/^${USER_NAME} .*$/d"  ${USER_TOKEN_FILE}
    echo "${USER_NAME} ${USER_TOKEN}"  >>  ${USER_TOKEN_FILE}
    UPDATE_2=$?
    if [[ ${UPDATE_2} -ne 0 ]]; then
        echo -e "\n猪猪侠警告：用户【${USER_NAME}】token更新失败\n"
    fi
    return ${UPDATE_2}
}


GET_IT='N'
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    F_USER_NAME=`echo ${LINE} | awk -F '|' '{print $3}'`
    F_USER_NAME=`echo ${F_USER_NAME}`
    #
    # token
    USER_NAME=${F_USER_NAME}
    USER_TOKEN=$(echo ${RANDOM} | sha1sum | awk '{print $1}')
    #
    # 更新某用户
    if [[ ! -z ${A_USER_NAME} ]]; then
       if [[ ${F_USER_NAME} == ${A_USER_NAME} ]]; then
           GET_IT='Y'
           F_UPDATE
           break
       else
           continue
       fi
    fi
    #
    # 更新所有
    F_UPDATE
    #
done < "${USER_DB_FILE}"


# 更新某用户
if [[ ! -z ${A_USER_NAME} ]] && [[ ${GET_IT} != Y ]]; then
    echo  -e "\n猪猪侠警告：用户【${A_USER_NAME}】在【${USER_DB_FILE}】中未找到\n"
fi


