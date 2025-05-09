#!/bin/bash

# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 自动引入/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
.  /etc/profile        #-- 非终端界面不会自动引入，必须主动引入
#RUN_ENV=
#DOMAIN=
#EMAIL=
#WEBSITE_BASE=

# 引入env.sh

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
WEB_PROJECT_LIST_FILE="${SH_PATH}/nginx.list"
WEB_PROJECT_LIST_FILE_TMP="/tmp/${SH_NAME}-nginx.tmp.list"
#
SUCCESS_MSG='Successfully received certificate'
EXISTING_MSG='You have an existing certificate'
#
[ -d "./log" ] || mkdir log
rm -f ./log/*


# 删除空行（以及只有tab、空格的行）
#sed -i '/^\s*$/d'  ${WEB_PROJECT_LIST_FILE}
# 删除行中的空格
#sed -i 's/[ \t]*//g'  ${WEB_PROJECT_LIST_FILE}


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



# 用法：
F_HELP()
{
    echo "
    用途：从letsencrypt申请普通单域名证书
    依赖：
        /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
        ${WEB_PROJECT_LIST_FILE}
        certbot
    注意：运行在nginx上
    用法:
        $0  [-h|--help]
        $0  [-l|--list]      #--- 列出所有项目域名
        $0  [-r|--request|-u|--update]  <{项目1}> <{项目2}> ... <{项目n}>    #--- 为项目申请或renew证书
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -r|--request   申请证书
        -u|--update    renew证书
    示例:
        #
        $0  -l                     #--- 列出所有项目域名
        $0  -r                     #--- 为所有项目域名申请证书
        $0  -r  项目a 项目b        #--- 为【项目a、项目b】申请证书
        $0  -u                     #--- 为所有现有域名证书renew证书
        $0  -u  项目a 项目b        #--- 目前certbot renew只支持renew所有证书！！！故此命令无实际意义！！！等同-u
    "
}


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




# 参数检查
TEMP=`getopt -o hlru  -l help,list,request,update -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 51
fi
#
eval set -- "${TEMP}"


# 获取参数
while true
do
    #
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -l|--list)
            awk -F "|"  \
                '$1 !~ /[ ]*#[ ]*/ && $3 !~ /^[ ]*$/ {print $0}'  \
                "${WEB_PROJECT_LIST_FILE}"  \
                | awk -F "|"  \
                '{sub(/^[[:blank:]]*/,"",$3)  \
                 ; sub(/[[:blank:]]*$/,"",$3)  \
                 ; printf "%2d  %-32s  %-s.'"${DOMAIN}"'\n",NR,$2,$3}'
            exit
            ;;
        -r|--request)
            WORK='request'
            shift
            ;;
        -u|--update)
            WORK='update'
            shift
            ;;
        #-t|--test)
        #    CERTBOT_OPT=" --dry-run"
        #    shift
        #    ;;
        --)
            shift
            break
            ;;
        *)
            echo -e "\n猪猪侠警告：未知参数，请查看帮助【$0 --help】\n"
            exit 51
            ;;
    esac
done

# 操作变量 WORK 不能为空
if [[ -z ${WORK} ]]; then
    echo -e "\n猪猪侠警告：必要参数缺失，请查看帮助【$0 --help】\n"
    exit 51
fi


# 待搜索的WEB项目清单
> ${WEB_PROJECT_LIST_FILE_TMP}
## 参数个数
if [[ $# -eq 0 ]]; then
    cp  ${WEB_PROJECT_LIST_FILE}  ${WEB_PROJECT_LIST_FILE_TMP}
else
    # 指定项目
    echo '#| **项目名** | **域名A记录** | **http端口** | **https端口** | **方式** | **后端协议端口** | **附加项** | **域名A记录IP** |' > ${WEB_PROJECT_LIST_FILE_TMP}
    for i in "$@"
    do
        #
        GET_IT='N'
        while read LINE
        do
            # 跳过以#开头的行或空行
            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
            #
            WEB_PROJECT_NAME=`echo $LINE | awk -F '|' '{print $2}'`
            WEB_PROJECT_NAME=`echo ${WEB_PROJECT_NAME}`
            if [ "x${WEB_PROJECT_NAME}" = x$i ]; then
                echo $LINE >> ${WEB_PROJECT_LIST_FILE_TMP}
                GET_IT='Y'
                break
            fi
        done < ${WEB_PROJECT_LIST_FILE}
        #
        if [ $GET_IT = 'N' ]; then
            echo -e "\n猪猪侠警告：项目【${i}】不在WEB项目列表【${WEB_PROJECT_LIST_FILE}】中，请检查！\n"
            exit 51
        fi
    done
fi


# do
case ${WORK} in
    request)
        # 申请证书
        EXIST_CERT_OUTPUT=${SH_PATH}/all_exist_cert.txt
        certbot certificates  >  ${EXIST_CERT_OUTPUT}
        i=0
        while read LINE
        do
            # 跳过以#开头的行或空行
            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
            #
            PJ=`echo $LINE | cut -f 2 -d \| `
            PJ=`echo $PJ`
            DOMAIN_A=`echo $LINE | cut -f 3 -d \| `
            DOMAIN_A=`echo $DOMAIN_A`
            #
            if [ "x${RUN_ENV}" = "xprod" ]; then
                FQDN="${DOMAIN_A}.${DOMAIN}"
            else
                FQDN="${RUN_ENV}-${DOMAIN_A}.${DOMAIN}"
            fi
            #
            REQUEST_LOG_FILE="./log/cert-only-${FQDN}.log"
            #
            # go
            i=`expr $i + 1`
            echo
            echo '-------------------------------------------------'
            echo "$i - ${PJ} - ${FQDN}"
            echo '-------------------------------------------------'
            # 空
            if [[ -z $DOMAIN_A ]]; then
                echo -e "项目【${PJ}】的【主机A】为空，跳过！"
                continue
            fi
            # 检查现有
            cat ${EXIST_CERT_OUTPUT} | grep "${FQDN}"  > /dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                echo  "证书【${FQDN}】已经存在，跳过！"
                echo
                continue
            fi
            # 申请
            echo  "certbot  certonly  ${CERTBOT_OPT}  \
                -m ${EMAIL}  \
                --agree-tos  \
                --webroot  \
                -w ${WEBSITE_BASE}/${FQDN}  \
                -d ${FQDN} 2>&1  \
                | tee -a ${REQUEST_LOG_FILE}"
            #
            certbot  certonly  ${CERTBOT_OPT}  \
                -m ${EMAIL}  \
                --agree-tos  \
                --webroot  \
                -w ${WEBSITE_BASE}/${FQDN}  \
                -d ${FQDN} 2>&1  \
                | tee -a ${REQUEST_LOG_FILE}
            #
            # 检查日志文件是否存在
            if [ ! -f "${REQUEST_LOG_FILE}" ]; then
                echo -e "${ECHO_ERROR}证书【${FQDN}】日志文件 ${REQUEST_LOG_FILE} 不存在，请检查！${ECHO_CLOSE}" >&2
                continue
            fi
            #
            # 检查证书申请结果
            if grep -q "$SUCCESS_MSG" "${REQUEST_LOG_FILE}" || grep -q "$EXISTING_MSG" "${REQUEST_LOG_FILE}"; then
                echo "OK"
                echo
            else
                echo -e "${ECHO_ERROR}证书【${FQDN}】申请失败，请检查！${ECHO_CLOSE}" >&2
                echo
                continue
            fi
        done < "${WEB_PROJECT_LIST_FILE_TMP}"
        exit
        ;;
    update)
        # renew
        /usr/bin/certbot renew  ${CERTBOT_OPT}
        if [[ $? -eq 0 ]]; then
            echo  "OK，证书全部更新成功"
            exit 0
        else
            echo -e "${ECHO_ERROR}证书更新失败${ECHO_CLOSE}"  >&2
            exit 54
        fi
        ;;
esac

