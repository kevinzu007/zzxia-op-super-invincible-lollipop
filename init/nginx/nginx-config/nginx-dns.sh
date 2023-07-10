#!/bin/bash


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 自动引入/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
.  /etc/profile        #-- 非终端界面不会自动引入，必须主动引入
#RUN_ENV=
#DOMAIN=

# 引入env.sh

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
#
WEB_PROJECT_LIST_FILE="${SH_PATH}/nginx.list"
WEB_PROJECT_LIST_FILE_TMP="/tmp/${SH_NAME}-nginx.tmp.list"
#
ALIYUN_DNS_SH="${ZZXIA_OP_SUPER_INVINCIBLE_LOLLIPOP_HOME}/op/aliyun-dns.sh"
GODADDY_DNS_SH="${ZZXIA_OP_SUPER_INVINCIBLE_LOLLIPOP_HOME}/op/godaddy-dns.sh"


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
    用途：根据${WEB_PROJECT_LIST_FILE}，在deploy服务器上添加修改域名A记录
    依赖：
        /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
        ${WEB_PROJECT_LIST_FILE}
        ${ALIYUN_DNS_SH}
        ${GODADDY_DNS_SH}
    注意: 运行在deploy上
    用法:
        $0  [-h|--help]
        $0  [-l|--list]
        $0  [ -p|--provider aliyun|godaddy|你自定义 ]  <{项目1} {项目2} ... {项目n}>
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -l|--list      列出可构建的项目清单
        -p|--provider  指定你的域名解析提供商，可选择aliyun|godaddy，也可以自己添加，毕竟供应商那么多，我也给不全
    示例:
        #
        $0  -h     #--- 帮助
        $0  -l     #--- 列出项目清单
        #
        $0  -p aliyun                 #--- 为所有项目添加域名记录，域名解析为阿里云
        $0  -p aliyun  项目a 项目b    #--- 为【项目a、项目b】添加域名记录，域名解析为阿里云
    "
}



# 参数检查
TEMP=`getopt -o hlp:  -l help,list,provider: -- "$@"`
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
            cat  "${WEB_PROJECT_LIST_FILE}"
            exit
            ;;
        -p|--provider)
            DNS_PROVIDER=$2
            case "${DNS_PROVIDER}" in
                aliyun)
                    DNS_PROVIDER_SH="${ALIYUN_DNS_SH}"
                    ;;
                godaddy)
                    DNS_PROVIDER_SH="${GODADDY_DNS_SH}"
                    ;;
                *)
                    echo -e "\n猪猪侠警告：这个域名解析商【${DNS_PROVIDER}】是你自定义的，你自己搞下！\n"
                    exit 51
            esac
            #
            shift 2
            ;;
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


#
if [[ -z ${DNS_PROVIDER} ]]; then
    echo -e "\n猪猪侠警告：参数【-p|--provider】不能为空，请查看帮助【$0 --help】\n"
    exit 51
fi


# 待搜索的WEB项目清单
> ${WEB_PROJECT_LIST_FILE_TMP}
## 参数个数
if [[ $# -eq 0 ]]; then
    cp  ${WEB_PROJECT_LIST_FILE}  ${WEB_PROJECT_LIST_FILE_TMP}
else
    # 指定项目
    echo '#| **项目名** | **域名A记录** | **http端口** | **https端口** | **方式** | **后端协议端口** | **附加项** | **域名A记录IP** |'  > ${WEB_PROJECT_LIST_FILE_TMP}
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
                # 既做proxy，又做real，所以项目名可能重名，故：
                #break
            fi
        done < ${WEB_PROJECT_LIST_FILE}
        #
        if [ $GET_IT = 'N' ]; then
            echo -e "\n猪猪侠警告：项目【${i}】不在WEB项目列表【${WEB_PROJECT_LIST_FILE}】中，请检查！\n"
            exit 51
        fi
    done
fi



# go
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    PJ=`echo $LINE | cut -f 2 -d \| `
    PJ=`echo $PJ`
    #
    DOMAIN_A=`echo $LINE | cut -f 3 -d \| `
    DOMAIN_A=`echo $DOMAIN_A`
    #
    DOMAIN_IPS=`echo $LINE | cut -f 9 -d \| `
    DOMAIN_IPS=`echo $DOMAIN_IPS`
    #
    DOMAIN_IPS_NUM=`echo ${DOMAIN_IPS} | grep -o , | wc -l`
    for ((i=0; i<=DOMAIN_IPS_NUM; i++))
    do
        if [ "x${DOMAIN_IPS}" = 'x' ]; then
            break
        fi
        FIELD=$((i+1))
        DOMAIN_IPS_SET=`echo ${DOMAIN_IPS} | cut -d , -f ${FIELD}`
        DOMAIN_IPS_SET=`echo ${DOMAIN_IPS_SET}`
        #
        case "$i" in
            0)
                # 第一个用替换的方式（他一般会删除所有匹配的DOMAIN_A记录，然后追加）
                ${DNS_PROVIDER_SH}  --Action replace  --domain ${DOMAIN}  --type A  --name ${RUN_ENV}-${DOMAIN_A}  --value ${DOMAIN_IPS_SET}
                ;;
            *)
                # 多个则后面的用追加方式
                ${DNS_PROVIDER_SH}  --Action append   --domain ${DOMAIN}  --type A  --name ${RUN_ENV}-${DOMAIN_A}  --value ${DOMAIN_IPS_SET}
                ;;
        esac
    done
done < ${WEB_PROJECT_LIST_FILE_TMP}
# 本来就会返回，这里只是为了引起你的注意，其他地方可能会用
exit $?


