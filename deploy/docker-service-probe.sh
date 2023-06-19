#!/bin/bash

# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 自动从/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh引入以下变量
RUN_ENV=${RUN_ENV:-'dev'}

# 引入env
. ${SH_PATH}/env.sh

# 本地env
GAN_WHAT_FUCK='Docker_Deploy'
TIME=${TIME:-`date +%Y-%m-%dT%H:%M:%S`}
TIME_START=${TIME}
DATE_TIME=`date -d "${TIME}" +%Y%m%dT%H%M%S`
#
LOG_BASE="${SH_PATH}/tmp/log"
LOG_HOME="${LOG_BASE}/${DATE_TIME}"
#
SERVICE_LIST="${SH_PATH}/docker-cluster-service.list"
HEALTH_STATUS_JSON="${LOG_HOME}/health.json"
HEALTH_URI='/actuator/health'


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



# 建立base目录
[ -d "${LOG_HOME}" ] || mkdir -p "${LOG_HOME}"


while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    SERVICE_NAME=`echo $LINE | cut -d \| -f 2`
    SERVICE_NAME=`echo ${SERVICE_NAME}`
    #
    CONTAINER_PORTS=`echo ${LINE} | cut -d \| -f 6`
    CONTAINER_PORTS=`eval echo ${CONTAINER_PORTS}`
    #
    echo -e "${ECHO_NORMAL}==================================================${ECHO_CLOSE}"
    echo "服务名：${SERVICE_NAME}"
    #
    CONTAINER_PORTS_NUM=`echo ${CONTAINER_PORTS} | grep -o ',' | wc -l`
    for ((i=CONTAINER_PORTS_NUM; i>=0; i--))
    do
        # 无端口
        if [[ -z ${CONTAINER_PORTS} ]]; then
            echo "端口为空，跳过"
            continue
        fi
        #
        FIELD=$((i+1))
        CONTAINER_PORTS_SET=`echo ${CONTAINER_PORTS} | cut -d ',' -f ${FIELD}`
        #CONTAINER_PORTS_SET_outside=`echo ${CONTAINER_PORTS} | cut -d ',' -f ${FIELD} | cut -d : -f 1`
        #CONTAINER_PORTS_SET_outside=`echo ${CONTAINER_PORTS_SET_outside}`
        CONTAINER_PORTS_SET_inside=`echo ${CONTAINER_PORTS} | cut -d ',' -f ${FIELD} | cut -d : -f 2`
        CONTAINER_PORTS_SET_inside=`echo ${CONTAINER_PORTS_SET_inside}`
        #
        if [[ -z ${CONTAINER_PORTS_SET_inside} ]]; then
            echo -e "\n猪猪侠警告：配置文件错误，请检查【CONTAINER_PORTS】。inside端口不能为空\n"
            exit 52
        fi
        #
        SERVICE_NAME='192.168.11.74'
        curl -s http://${SERVICE_NAME}:${CONTAINER_PORTS_SET_inside}${HEALTH_URI}  >  ${HEALTH_STATUS_JSON}---${SERVICE_NAME}
        if [[ $? -ne 0 ]]; then
            echo -e "${CONTAINER_PORTS_SET_inside} : ${ECHO_ERROR}探测异常${ECHO_CLOSE}"
            continue
        fi
        #
        SERVICE_STATUS=$(cat  ${HEALTH_STATUS_JSON}---${SERVICE_NAME} | jq .status | sed 's/\"//g')
        if [[ ${SERVICE_STATUS} == UP ]]; then
            echo -e "${ECHO_SUCCESS}${SERVICE_STATUS}${ECHO_CLOSE} : ${CONTAINER_PORTS_SET_inside}"
        else
            echo -e "${ECHO_ERROR}${SERVICE_STATUS}${ECHO_CLOSE} : ${CONTAINER_PORTS_SET_inside}"
        fi
        #
        SERVICE_COMPONENTS=$(cat ${HEALTH_STATUS_JSON}---${SERVICE_NAME} | jq .components | jq 'keys'[] | sed 's/\"//g')
        for SERVICE_SUB_COMP in ${SERVICE_COMPONENTS}
        do
            [[ ${SERVICE_SUB_COMP} == sentinel ]] && continue
            SERVICE_SUB_COMP_STATUS=$(cat ${HEALTH_STATUS_JSON}---${SERVICE_NAME} | jq .components.${SERVICE_SUB_COMP}.status | sed 's/\"//g')
            if [[ ${SERVICE_SUB_COMP_STATUS} == UP ]]; then
                echo -e "    ${ECHO_SUCCESS}${SERVICE_SUB_COMP_STATUS}${ECHO_CLOSE} : ${SERVICE_SUB_COMP}"
            else
                echo -e "    ${ECHO_ERROR}${SERVICE_SUB_COMP_STATUS}${ECHO_CLOSE} : ${SERVICE_SUB_COMP}"
            fi
        done
        #
    done
done < ${SERVICE_LIST}


