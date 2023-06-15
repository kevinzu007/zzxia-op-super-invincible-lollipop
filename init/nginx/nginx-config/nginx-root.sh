#!/bin/bash


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 引入env
# 自动从/etc/profile.d/run-env.sh引入以下变量
#RUN_ENV=
#DOMAIN=
#WEBSITE_BASE=

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
WEB_PROJECT_LIST_FILE="${SH_PATH}/nginx.list"
WEB_PROJECT_LIST_FILE_TMP="/tmp/${SH_NAME}-nginx.tmp.list"
TMP_WEBSITE_BASE="/tmp/${SH_NAME}-web_sites"
[ -d ${TMP_WEBSITE_BASE} ] && rm -rf   ${TMP_WEBSITE_BASE}
mkdir -p ${TMP_WEBSITE_BASE}


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
    用途：用以在nginx服务器上生成项目站点目录结构
    依赖：
        /etc/profile.d/run-env.sh
        ${WEB_PROJECT_LIST_FILE}
    注意: 运行在deploy上
    用法:
        $0  [-h|--help]
        $0  [-l|--list]
        $0  <{项目1} {项目2} ... {项目n}>
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
    示例:
        #
        $0  -h     #--- 帮助
        $0  -l     #--- 列出项目清单
        #
        $0                 #--- 为所有项目建立项目目录
        $0  项目a 项目b    #--- 为【项目a、项目b】建立项目目录
    "
}



# 参数检查
TEMP=`getopt -o hl  -l help,list -- "$@"`
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



# 准备模板
[ -e "/tmp/${SH_NAME}/releases" ] && rm -rf "/tmp/${SH_NAME}/releases"
mkdir -p /tmp/${SH_NAME}/releases/00000000
cd /tmp/${SH_NAME}/releases/
ln -s 00000000 current
cd -


# go
cd  ${TMP_WEBSITE_BASE}
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    PJ=`echo $LINE | cut -f 2 -d \| `
    PJ=`echo $PJ`
    DOMAIN_A=`echo $LINE | cut -f 3 -d \| `
    DOMAIN_A=`echo $DOMAIN_A`
    MODE=`echo $LINE | cut -f 6 -d \| `
    MODE=`echo $MODE`
    # MODE目录
    [ ! -d "${MODE}" ] && mkdir "${MODE}"
    #
    if [ "x${RUN_ENV}" = "xprod" ]; then
        FQDN="${DOMAIN_A}.${DOMAIN}"
    else
        FQDN="${RUN_ENV}-${DOMAIN_A}.${DOMAIN}"
    fi
    # 目录
    if [ ! -d ${PJ} ]; then
        mkdir -p  ${PJ}
        cp -r  /tmp/${SH_NAME}/releases  ${PJ}/
        mv ${PJ} ./${MODE}/
        # 链接
        if [[ -n $DOMAIN_A ]]; then
            ln -s  ${PJ}/releases/current  ${FQDN}
            mv ${FQDN} ./${MODE}/
        fi
    else
        echo "项目【${PJ}】目录已存在，跳过"
    fi
done < ${WEB_PROJECT_LIST_FILE_TMP}
cd -

# copy to server
if [ -d "${TMP_WEBSITE_BASE}/realserver" ]; then
    ansible nginx_real  -m synchronize -a "src=${TMP_WEBSITE_BASE}/realserver/  dest=${WEBSITE_BASE}/  rsync_opts=--perms=yes,--times=yes"
fi
#
if [ -d "${TMP_WEBSITE_BASE}/proxyserver" ]; then
    ansible nginx_proxy -m synchronize -a "src=${TMP_WEBSITE_BASE}/proxyserver/ dest=${WEBSITE_BASE}/  rsync_opts=--perms=yes,--times=yes"
fi


# 删除模板
rm -rf /tmp/${SH_NAME}/releases
echo -e "\n\n"


