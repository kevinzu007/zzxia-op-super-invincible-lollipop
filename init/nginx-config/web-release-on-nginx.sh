#!/bin/bash


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"

# 引入env

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
TODAY=$(date +%Y%m%d)
WEB_PROJECT_LIST_FILE="${SH_PATH}/nginx.list"
WEB_PROJECT_LIST_FILE_TMP="/tmp/${SH_NAME}-nginx.tmp.list"
WEBSITE_BASE='/srv/www'
HISTORY_RELEASE_NUM=4     #---保留历史版本数
ERROR_CODE=''     #--- 程序最终返回值


# 删除空行（以及只有tab、空格的行）
#sed -i '/^\s*$/d'  "${WEB_PROJECT_LIST_FILE}"
# 删除行中的空格
#sed -i 's/[ \t]*//g'  "${WEB_PROJECT_LIST_FILE}"


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


#
if [ -d "${WEBSITE_BASE}" ]; then
    cd "${WEBSITE_BASE}"
else
    echo -e "\n猪猪侠警告：项目根目录【${WEBSITE_BASE}】不存在，请检查！\n"
    exit 53
fi



# 用法：
F_HELP()
{
    echo "
    用途：web站点发布上线
    依赖：
        ${WEB_PROJECT_LIST_FILE}
    注意：运行在nginx节点上
        【上线（ship）】流程包含以下四个子流程【构建】、【测试（test）】、【部署（deploy）】、【发布（release）】。原地发布（即部署 == 发布）
        * 名称正则表达式完全匹配，会自动在正则表达式的头尾加上【^ $】，请规避
        * 输入命令时，参数顺序不分先后
    用法:
        $0  [-h|--help]
        $0  [-l|--list]                                         #--- 列出项目
        $0  [-r|--release]   <{项目1}  {项目2} ... {项目n} ... {项目名称正则表达式完全匹配}>     #--- 发布上线今天的版本
        $0  [-b|--rollback]  <{项目1}  {项目2} ... {项目n} ... {项目名称正则表达式完全匹配}>     #--- 回滚到上一个版本
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help        此帮助
        -l|--list        项目列表
        -r|--release     发布
        -b|--rollback    回滚
    示例:
        $0  -l                 #--- 列出所有项目
        #
        $0  -r                 #--- 发布所有项目
        $0  -r  项目a 项目b    #--- 发布【项目a、项目b】
        #
        $0  -b                 #--- 回滚所有项目
        $0  -b  项目a 项目b    #--- 回滚【项目a、项目b】
        # 服务名称用正则完全匹配
        $0  -r  .*xxx.*           #--- 发布项目名称正则完全匹配【^.*xxx.*$】的第一个项目
        $0  -b  [.]*xxx           #--- 回滚项目名称正则完全匹配【^[.]*xxx$】的第一个项目
    "
}



# 发布
# 用法：F_RELEASE {项目名}
F_RELEASE()
{
    F_PJ=$1
    cd "${F_PJ}/releases"
    # 清理旧的
    #while [ $(ls -l ./ | grep ^d | wc -l) -ge ${HISTORY_RELEASE_NUM} ]
    while [ $(ls -l ./ | grep -c ^d) -ge ${HISTORY_RELEASE_NUM} ]
    do
        # 删除最旧的
        rm -rf  $(ls -l ./ | grep ^d | awk '{print $9}' | sort -g | sed -n '1p')
    done
    #
    RELE_DATE_LATEST=$(ls -l ./ | grep ^d | awk '{print $9}' | sort -gr | sed -n '1p')
    if [ "${RELE_DATE_LATEST}" != "${TODAY}" ]; then
        ERROR_CODE=55
        printf  "%-32s  %s\n"  "${F_PJ}"   "无需发布，今日无部署"
    else
        [ -L ./current ] && rm -f ./current
        ln -s  ./"${RELE_DATE_LATEST}"  ./current
        ERROR_CODE=50
        printf  "%-32s  %s\n"  "${F_PJ}"   "发布成功"
    fi
    #
    cd ../..
    return ${ERROR_CODE}
}



# 回滚
# 用法：F_ROLLBACK {项目名}
F_ROLLBACK()
{
    F_PJ=$1
    cd "${F_PJ}/releases"
    #
    RELE_DATE_LATEST=$(ls -l ./ | grep ^d | awk '{print $9}' | sort -gr | sed -n '1p')
    # 今天有部署才需要回滚
    if [ "${RELE_DATE_LATEST}" != "${TODAY}" ]; then
        ERROR_CODE=55
        printf  "%-32s  %s\n"  "${F_PJ}"   "无需回滚，今日无部署"
    else
        RELE_DATE_NEAR=$(ls -l ./ | grep ^d | awk '{print $9}' | sort -gr | sed -n '2p')
        [ -L ./current ] && rm -f ./current
        ln -s  ./"${RELE_DATE_NEAR}"  ./current
        ERROR_CODE=50
        printf  "%-32s  %s\n"  "${F_PJ}"   "回滚成功*版本：${RELE_DATE_NEAR}"
    fi
    #
    cd ../..
    return ${ERROR_CODE}
}



# 参数检查
TEMP=`getopt -o hlrb  -l help,list,release,rollback -- "$@"`
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
        -r|--release)
            WORK='release'
            shift
            ;;
        -b|--rollback)
            WORK='rollback'
            shift
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
> "${WEB_PROJECT_LIST_FILE_TMP}"
## 参数个数
if [[ $# -eq 0 ]]; then
    cp  "${WEB_PROJECT_LIST_FILE}"  "${WEB_PROJECT_LIST_FILE_TMP}"
else
    # 指定项目
    for i in "$@"
    do
        #
        GET_IT='N'
        while read LINE
        do
            # 跳过以#开头的行或空行
            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
            #
            PJ=`echo $LINE | awk -F '|' '{print $2}'`
            PJ=`echo ${PJ}`
            if [[ ${PJ} =~ ^$i$ ]]; then
                echo $LINE >> "${WEB_PROJECT_LIST_FILE_TMP}"
                GET_IT='YES'
                break
            fi
        done < "${WEB_PROJECT_LIST_FILE}"
        #
        if [[ $GET_IT != 'YES' ]]; then
            echo -e "\n猪猪侠警告：项目【${i}】不在WEB项目列表【${WEB_PROJECT_LIST_FILE}】中，请检查！\n"
            exit 51
        fi
    done
fi
# 删除无关行
#sed  -i  -e '/^\s*$/d'  -e '/^#.*$/d'  -e 's/[ \t]*//g'  ${WEB_PROJECT_LIST_FILE_TMP}
sed  -i  -E  -e '/^\s*$/d'  -e '/^##.*$/d'  -e '/---/d'  -e '/^#.*PRIORITY/d'  ${WEB_PROJECT_LIST_FILE_TMP}
# 优先级排序
> ${WEB_PROJECT_LIST_FILE_TMP}.sort
for i in  `awk -F '|' '{split($10,a," ");print NR,a[1]}' ${WEB_PROJECT_LIST_FILE_TMP}  |  sort -n -k 2 |  awk '{print $1}'`
do
    awk "NR=="$i'{print}' ${WEB_PROJECT_LIST_FILE_TMP}  >> ${WEB_PROJECT_LIST_FILE_TMP}.sort
done
cp  ${WEB_PROJECT_LIST_FILE_TMP}.sort  ${WEB_PROJECT_LIST_FILE_TMP}
# 加表头
sed -i  '1i#| **项目名** | **域名A记录** | **http端口** | **https端口** | **方式** | **后端协议端口** | **附加项** | **域名A记录IP** | **优先级** |'  ${WEB_PROJECT_LIST_FILE_TMP}
# 屏显
#echo -e "${ECHO_NORMAL}========================= 开始发布 =========================${ECHO_CLOSE}"  #--- 60 (60-50-40)
#echo -e "\n【${SH_NAME}】待发布项目清单："
#${FORMAT_TABLE_SH}  --delimeter '|'  --file ${WEB_PROJECT_LIST_FILE_TMP}
##echo -e "\n"


# go
cd  "${WEBSITE_BASE}"
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    PJ=`echo $LINE | cut -f 2 -d \| `
    PJ=`echo $PJ`
    MODE=`echo $LINE | cut -f 6 -d \| `
    MODE=`echo $MODE`
    #
    if [[ "$MODE" == 'proxyserver' ]]; then
        printf  "%-32s  %s\n"  "${PJ}"   "无需发布或回滚"
        ERROR_CODE=56
        continue
    fi
    # 目录
    if [ ! -d "${PJ}/releases" ]; then
        printf  "%-32s  %s\n"  "${PJ}"   "发布或回滚失败，项目目录不存在"
        ERROR_CODE=53
        continue
    else
        case "${WORK}" in
            release)
                #
                F_RELEASE  "${PJ}"
                ;;
            rollback)
                #
                F_ROLLBACK  "${PJ}"
                ;;
        esac
    fi
done < "${WEB_PROJECT_LIST_FILE_TMP}"
# 被调用时需要
#return ${ERROR_CODE}

