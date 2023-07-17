#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################



# echo颜色定义
export ECHO_CLOSE="\033[0m"
#
export ECHO_RED="\033[31;1m"
export ECHO_ERROR=${ECHO_RED}
#
export ECHO_GREEN="\033[32;1m"
export ECHO_SUCCESS=${ECHO_GREEN}
#
export ECHO_BLUE="\033[34;1m"
export ECHO_NORMAL=${ECHO_BLUE}
#
export ECHO_BLACK_GREEN="\033[30;42;1m"
export ECHO_BLACK_CYAN="\033[30;46;1m"
export ECHO_REPORT=${ECHO_BLACK_CYAN}



# 时间差计算函数
F_TimeDiff ()
{
    # 时间格式：2019-01-08T19:41:59
    FV_StartTime=$1
    FV_EndTime=$2
    #
    FV_ST=$(date -d "${FV_StartTime}" +%s)
    FV_ET=$(date -d "${FV_EndTime}"   +%s)
    #
    FV_SecondsDiff=$((FV_ET - FV_ST))
    #
    if [ ${FV_SecondsDiff} -ge 0 ];then
        #
        FV_Days=$(( FV_SecondsDiff / 86400 ))
        FV_Hours=$((FV_SecondsDiff/3600%24))
        FV_Minutes=$((FV_SecondsDiff/60%60))
        FV_Seconds=$((FV_SecondsDiff%60))

        echo "耗时: ${FV_Days} Days ${FV_Hours} Hours ${FV_Minutes} Minutes ${FV_Seconds} Seconds"
        return 0
    else
        echo "Error, 请检查。 ---可能原因：1、时间格式不合格； 2、date2小于date1 ！"
        return 1
    fi
}



# 搜索Gitlab用户名，返回主用户名
# F_SEARCH_GITLAB_USER  [gitlab用户名]
F_SEARCH_GITLAB_USER()
{
    F_GITLAB_USER_NAME=$1
    while read U_LINE
    do
        # 跳过以#开头的行或空行
        [[ "$U_LINE" =~ ^# ]] || [[ "$U_LINE" =~ ^[\ ]*$ ]] && continue
        #
        CURRENT_USER_NAME=`echo $U_LINE | cut -d '|' -f 3`
        CURRENT_USER_NAME=`echo ${CURRENT_USER_NAME}`
        CURRENT_GITLAB_USER_NAME=`echo $U_LINE | cut -d '|' -f 4`
        CURRENT_GITLAB_USER_NAME=`echo ${CURRENT_GITLAB_USER_NAME}`
        if [[ ${F_GITLAB_USER_NAME} == ${CURRENT_GITLAB_USER_NAME} ]]; then
            echo "0 | ${CURRENT_USER_NAME}"
            return 0
        fi
    done < "${USER_DB_FILE_APPEND_1}"
    #
    echo "3 | ${CURRENT_USER_NAME}"
    return 3
}



# 搜索用户，返回用户信息
# F_SEARCH_USER  [用户名|用户ID]
F_SEARCH_USER()
{
    F_USER_NAME=$1
    while read U_LINE
    do
        # 跳过以#开头的行或空行
        [[ "$U_LINE" =~ ^# ]] || [[ "$U_LINE" =~ ^[\ ]*$ ]] && continue
        #
        CURRENT_USER_ID=`echo $U_LINE | cut -d '|' -f 2`
        CURRENT_USER_ID=`echo ${CURRENT_USER_ID}`
        CURRENT_USER_NAME=`echo $U_LINE | cut -d '|' -f 3`
        CURRENT_USER_NAME=`echo ${CURRENT_USER_NAME}`
        CURRENT_USER_XINGMING=`echo $U_LINE | cut -d '|' -f 4`
        CURRENT_USER_XINGMING=`echo ${CURRENT_USER_XINGMING}`
        CURRENT_USER_EMAIL=`echo $U_LINE | cut -d '|' -f 5`
        CURRENT_USER_EMAIL=`echo ${CURRENT_USER_EMAIL}`
        if [ "${F_USER_NAME}" = "${CURRENT_USER_ID}"  -o  "${F_USER_NAME}" = "${CURRENT_USER_NAME}" ]; then
            # 获取append部分
            while read UA_LINE
            do
                CURRENT_USER_NAME_A=`echo $UA_LINE | cut -d '|' -f 3`
                CURRENT_USER_NAME_A=`echo ${CURRENT_USER_NAME_A}`
                CURRENT_GITLAB_USER_NAME_A=`echo $UA_LINE | cut -d '|' -f 4`
                CURRENT_GITLAB_USER_NAME_A=`echo ${CURRENT_GITLAB_USER_NAME_A}`
                CURRENT_USER_PRIVILEGES_A=`echo $UA_LINE | cut -d '|' -f 5`
                CURRENT_USER_PRIVILEGES_A=`echo ${CURRENT_USER_PRIVILEGES_A}`
                if [[ ${F_USER_NAME} == ${CURRENT_USER_NAME_A} ]]; then
                    # 获取权限字段
                    CURRENT_USER_PRIVILEGES_A=${CURRENT_USER_PRIVILEGES_A// /}      #-- 删除字符串中所有的空格
                    # 匹配，输出
                    echo "0 | ${F_USER_NAME} | ${CURRENT_USER_XINGMING} | ${CURRENT_USER_EMAIL} | ${CURRENT_GITLAB_USER_NAME_A} | ${CURRENT_USER_PRIVILEGES_A}"
                    return 0
                fi
            done < "${USER_DB_FILE_APPEND_1}"
        fi
    done < "${USER_DB_FILE}"
    #
    echo "3 | ${F_USER_NAME}"
    return 3
}



# 搜索用户，返回用户权限
# F_SEARCH_USER_PRIV  [用户名]  [权限]
F_SEARCH_USER_PRIV()
{
    F_USER_NAME=$1
    F_USER_PRIV=$2
    #
    # 获取append部分
    while read UA_LINE
    do
        CURRENT_USER_NAME_A=`echo $UA_LINE | cut -d '|' -f 3`
        CURRENT_USER_NAME_A=`echo ${CURRENT_USER_NAME_A}`
        CURRENT_USER_PRIVILEGES_A=`echo $UA_LINE | cut -d '|' -f 5`
        CURRENT_USER_PRIVILEGES_A=`echo ${CURRENT_USER_PRIVILEGES_A}`
        if [[ ${F_USER_NAME} == ${CURRENT_USER_NAME_A} ]]; then
            # 获取权限字段
            CURRENT_USER_PRIVILEGES_A=${CURRENT_USER_PRIVILEGES_A// /}      #-- 删除字符串中所有的空格
            PRIVILEGES_env_NUM=$(echo ${CURRENT_USER_PRIVILEGES_A} | grep -o ',' | wc -l)
            for ((i=PRIVILEGES_env_NUM; i>=0; i--))
            do
                # 为空
                if [[ -z ${CURRENT_USER_PRIVILEGES_A} ]]; then
                    break
                fi
                #
                FIELD=$((i+1))
                CURRENT_USER_PRIVILEGES_A_SET=`echo ${CURRENT_USER_PRIVILEGES_A} | cut -d ',' -f ${FIELD}`
                #
                CURRENT_USER_PRIVILEGES_A_SET_env=`echo ${CURRENT_USER_PRIVILEGES_A_SET} | cut -d ':' -f 1`
                CURRENT_USER_PRIVILEGES_A_SET_priv_SET=`echo ${CURRENT_USER_PRIVILEGES_A_SET} | cut -d ':' -f 2`
                if [[ ${CURRENT_USER_PRIVILEGES_A_SET_env} == ${RUN_ENV} ]] || [[ ${CURRENT_USER_PRIVILEGES_A_SET_env} == ALL ]]; then
                    # 获取具体权限
                    PRIVILEGES_env_priv_NUM=$(echo ${CURRENT_USER_PRIVILEGES_A_SET_priv_SET} | grep -o '&' | wc -l)
                    for ((j=PRIVILEGES_env_priv_NUM; j>=0; j--))
                    do
                        # 为空
                        if [[ -z ${CURRENT_USER_PRIVILEGES_A_SET_priv_SET} ]]; then
                            break
                        fi
                        #
                        FIELD_J=$((j+1))
                        CURRENT_USER_PRIVILEGES_A_SET_priv=`echo ${CURRENT_USER_PRIVILEGES_A_SET_priv_SET} | cut -d '&' -f ${FIELD_J}`
                        if [[ ${CURRENT_USER_PRIVILEGES_A_SET_priv} == ${F_USER_PRIV} ]] || [[ ${CURRENT_USER_PRIVILEGES_A_SET_priv} == ALL ]]; then
                            # 匹配，输出
                            echo "0 | PASS"
                            return 0
                        fi
                    done
                fi
            done
        fi
    done < "${USER_DB_FILE_APPEND_1}"
    #
    echo "3 | NOT_PASS"
    reutrn 3
}



