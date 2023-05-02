#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 引入env
. ${SH_PATH}/env.sh
#DOCKER_REPO=
#DOCKER_REPO_USER=
#DOCKER_REPO_PASSWORD=
#DOCKER_REPO_PROTOCOL=
#DOCKER_REPO_URL_BASE=

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
SERVICE_LIST_FILE="${SH_PATH}/docker-cluster-service.list"
SERVICE_LIST_FILE_TMP="/tmp/${SH_NAME}-docker-cluster-service.tmp.list.$(date +%S)"
SEARCH_RESULT_FILE="/tmp/${SH_NAME}-result.txt"
# sh
FORMAT_TABLE_SH="${SH_PATH}/../op/format_table.sh"


# 删除空行（以及只有tab、空格的行）
#sed -i '/^\s*$/d'  ${SERVICE_LIST_FILE}
## 删除行中的空格
#sed -i 's/[ \t]*//g'  ${SERVICE_LIST_FILE}


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
    用途：查询仓库清单、tag清单，删除仓库或tag
    依赖：
        ${SH_PATH}/env.sh
        ${SERVICE_LIST_FILE}
    注意：
        * 输入命令时，参数顺序不分先后
    用法:
        $0 [-h|--help]
        $0 [-l|--list]
        $0 [-l|--list]
        $0  <-e|--exclude {%镜像版本%}>  <-t|--tag {%镜像版本%}>  <-n|--newest {第几新版本}>  <-o|--output {路径/文件}>  <{服务1} ... {服务2} ...>
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help       此帮助
        -l|--list       清单
        -e|--exclude    排除指定镜像版本，支持模糊定义，一般用于排除今天打包的镜像版本，用于部署回滚
        -t|--tag        镜像版本(tag)。支持模糊查找
        -n|--newest     取第几新的镜像版本，例如： -n 1 ：代表取最新的那个镜像版本，-n 2：代表第二新的镜像，有-n参数时输出格式为：【服务名  tag版本 tag版本2 ...】；无-n参数时输出为服务名 \ntag版本 \ntag版本2 \n...
        -o|--output     输出搜索结果不为空的服务名称 到 指定【路径/文件】
    示例：
        $0  -h
        $0  -l
        #
        $0                       #--- 返回所有服务所有镜像版本
        $0  服务1                #--- 返回服务名为【服务1】的所有镜像版本
        #
        $0  -e 2021  服务1       #--- 返回服务名为服务1，且tag版本不包含【2021】的所有版本
        $0  -t 2021  服务1       #--- 返回服务名为服务1，且tag版本包含【2021】的所有版本
        $0  -n 1     服务1       #--- 返回服务名为服务1，且最新的镜像tag版本
        $0  -n 2     服务1       #--- 返回服务名为服务1，且次新的镜像tag版本（第二新）
        #
        $0  -t 2021        -n 2            #--- 返回所有服务，且tag名包含【2021】，且次新的镜像tag版本
        $0  -t 2021        -n 2   服务1    #--- 返回服务名为【服务1】，且tag版本包含【2021】，且次新的镜像tag版本
        $0  -e 2021.01.22  -n 1   服务1    #--- 返回服务名为【服务1】，且除tag版本包含【2021.01.22】的镜像外，最新的镜像tag版本，一般用于排除今天【2021.01.22】的版本以回滚
        $0  -e 2021.01.22  -t 20  服务1    #--- 返回服务名为【服务1】，且除tag版本包含【2021.01.22】的镜像外，且tag版本包含【20】的镜像tag版本，返回最新的是个
        #
        $0  -e 2021.01.22  -t 2021.01.01.01  -n 1   #--- 返回所有服务，且tag版本不包含【2021.01.22】，且包含【2021.01.01.01】，最新的tag版本
        # 今日发布与回滚：
        $0  -t 2021.01.22  -n 1  -o /root/1.txt     #--- 返回所有服务，且tag名称包含【2021.01.22】(今天)，最新的镜像tag版本，将服务清单输出到文件/root/1.txt，一般用于发布今天打包的服务清单
        $0  -e 2021.01.22  -n 1  -o /root/1.txt     #--- 返回所有服务，且tag名称不包含【2021.01.22】(今天)，最新的镜像tag版本，将服务清单输出到文件/root/1.txt，一般用于今日发布失败后的回滚
    "
}


# 搜索
# 用法：F_SEARCH 镜像名
F_SEARCH()
{
    F_SEARCH_RESULT_FILE="/tmp/${SH_NAME}-F_SEARCH-result.txt"
    F_SEARCH_RESULT_ERR_FILE="/tmp/${SH_NAME}-F_SEARCH-result-err.txt"
    F_IMAGE_NAME=$1
    curl -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD} -s -X GET ${DOCKER_REPO_URL_BASE}/${F_IMAGE_NAME}/tags/list | jq .tags[] > ${F_SEARCH_RESULT_FILE}  2>${F_SEARCH_RESULT_ERR_FILE}
    if [[ $? -ne 0 ]] || [[ $(cat ${F_SEARCH_RESULT_ERR_FILE} | grep -q 'NAME_UNKNOWN'; echo $?) -eq 0 ]]; then
        echo -e "\n猪猪侠警告：项目镜像不存在，或者访问【${DOCKER_REPO}】服务器异常\n" 1>&2
        return 53
    fi
    sed -i 's/\"//g'    ${F_SEARCH_RESULT_FILE}
    # latest
    if [[ "x${LIKE_THIS_IMAGE_TAG}" = 'xlatest' ]]; then
        cat ${F_SEARCH_RESULT_FILE}  | grep ${LIKE_THIS_IMAGE_TAG}
        return 0
    fi
    # 倒排序，数字开头的自动标记版本
    sed -i '/latest/d'  ${F_SEARCH_RESULT_FILE}
    cat  ${F_SEARCH_RESULT_FILE} | sort -n -r >  ${F_SEARCH_RESULT_FILE}.sort
    #
    if [[ -z ${NUMBER_NEWEST} ]]; then
        # 无第几新
        if [[ -z ${LIKE_THIS_IMAGE_TAG} ]]; then
            if [[ -z "${EXCLUDE_THIS_IMAGE_TAG}" ]]; then
                cat ${F_SEARCH_RESULT_FILE}.sort
            else
                cat ${F_SEARCH_RESULT_FILE}.sort | grep -v ${EXCLUDE_THIS_IMAGE_TAG}
            fi
        else
            if [[ -z "${EXCLUDE_THIS_IMAGE_TAG}" ]]; then
                cat ${F_SEARCH_RESULT_FILE}.sort   | grep ${LIKE_THIS_IMAGE_TAG}
            else
                cat ${F_SEARCH_RESULT_FILE}.sort   | grep ${LIKE_THIS_IMAGE_TAG} | grep -v ${EXCLUDE_THIS_IMAGE_TAG}
            fi
        fi
    else
        # 第几新
        if [[ -z "${LIKE_THIS_IMAGE_TAG}" ]]; then
            if [[ -z "${EXCLUDE_THIS_IMAGE_TAG}" ]]; then
                cat ${F_SEARCH_RESULT_FILE}.sort | sed -n ${NUMBER_NEWEST}p
            else
                cat ${F_SEARCH_RESULT_FILE}.sort | grep -v ${EXCLUDE_THIS_IMAGE_TAG} | sed -n ${NUMBER_NEWEST}p
            fi
        else
            if [[ -z "${EXCLUDE_THIS_IMAGE_TAG}" ]]; then
                cat ${F_SEARCH_RESULT_FILE}.sort   | grep ${LIKE_THIS_IMAGE_TAG} | sed -n ${NUMBER_NEWEST}p
            else
                cat ${F_SEARCH_RESULT_FILE}.sort   | grep ${LIKE_THIS_IMAGE_TAG} | grep -v ${EXCLUDE_THIS_IMAGE_TAG} | sed -n ${NUMBER_NEWEST}p
            fi
        fi
    fi
    return 0
}



# 参数检查
TEMP=`getopt -o hle:t:n:o:  -l help,list,exclude:,tag:,newest:,output: -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 51
fi
#
eval set -- "${TEMP}"



# 获取参数
while true
do
    #echo 当前第一个参数是：$1
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -l|--list)
            #awk 'BEGIN {FS="|"; printf "%2d %-32s %-s\n",0,"Docker服务名","Docker镜像名"} { if ($3 !~ /^ *$/ && $1 !~ /^#/) {sub(/^[[:blank:]]*/,"",$2); sub(/[[:blank:]]*$/,"",$2); sub(/^[[:blank:]]*/,"",$3); sub(/[[:blank:]]*$/,"",$3); printf "%2d %-32s %-s\n",NR,$2,$3} }'  ${SERVICE_LIST_FILE}
            echo '**服务名名** | **镜像名**'  > /tmp/docker-image-search-for-list.txt
            cat  ${SERVICE_LIST_FILE} | grep -v '^#' | awk  'BEGIN {FS="|"} {printf "%s | %s\n", $2,$3}'  >> /tmp/docker-image-search-for-list.txt
            ${FORMAT_TABLE_SH}  --delimeter '|'  --file /tmp/docker-image-search-for-list.txt
            exit
            ;;
        -e|--exclude)
            EXCLUDE_THIS_IMAGE_TAG=$2
            shift 2
            ;;
        -t|--tag)
            LIKE_THIS_IMAGE_TAG=$2
            shift 2
            ;;
        -n|--newest)
            NUMBER_NEWEST=$2
            shift 2
            grep -q '^[[:digit:]]\+$' <<< ${NUMBER_NEWEST}
            if [ $? -ne 0 ]; then
                echo '参数：{第几新版本} 必须为整数！当前值为：${NUMBER_NEWEST}'
                exit 51
            fi
            ;;
        -o|--output)
            OUTPUT_FILE=$2
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



# 待搜索的服务清单
> ${SERVICE_LIST_FILE_TMP}
# 参数个数为
if [[ $# -eq 0 ]]; then
    cp ${SERVICE_LIST_FILE}  ${SERVICE_LIST_FILE_TMP}
else
    for i in $@
    do
        #
        GET_IT='N'
        while read LINE
        do
            # 跳过以#开头的行或空行
            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
            #
            SERVICE_NAME=`echo $LINE | awk -F '|' '{print $2}'`
            SERVICE_NAME=`echo ${SERVICE_NAME}`
            if [ "x${SERVICE_NAME}" = "x$i" ]; then
                echo $LINE >> ${SERVICE_LIST_FILE_TMP}
                GET_IT='YES'
                break
            fi
        done < ${SERVICE_LIST_FILE}
        #
        if [[ $GET_IT != 'YES' ]]; then
            echo -e "\n猪猪侠警告：服务【${i}】不在服务列表【${SERVICE_LIST_FILE}】中，请检查！\n"
            exit 51
        fi
    done
fi



# 开始
> ${SEARCH_RESULT_FILE}
NUM=0
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    SERVICE_NAME=`echo ${LINE} | cut -d \| -f 2`
    SERVICE_NAME=`echo ${SERVICE_NAME}`
    #
    IMAGE_NAME=`echo ${LINE} | cut -d \| -f 3`
    IMAGE_NAME=`eval echo ${IMAGE_NAME}`    #--- 用eval将配置文件中项的变量转成值，下同
    # 跳过服务名名或镜像名为空的行
    if [ "x${SERVICE_NAME}" = 'x' -o "x${IMAGE_NAME}" = 'x' ]; then
        continue
    fi
    #
    > ${SEARCH_RESULT_FILE}.${SERVICE_NAME}.tmp
    # 写入文件
    F_SEARCH ${IMAGE_NAME}  > ${SEARCH_RESULT_FILE}.${SERVICE_NAME}.tmp  2>/tmp/${SH_NAME}-error.txt
    #if [ $? -eq 53 ]; then
    #    echo -e "\n猪猪侠警告：项目镜像不存在\n"
    #fi
    # 显示输出
    if [ -z "${OUTPUT_FILE}" ]; then
        let NUM=${NUM}+1
        echo -e "${ECHO_NORMAL}# ---------------------------------------------------${ECHO_CLOSE}"
        echo -e "${ECHO_NORMAL}# ${NUM} - 服务名：${SERVICE_NAME} - 镜像名：${IMAGE_NAME} ${ECHO_CLOSE}"
        echo -e "${ECHO_NORMAL}# ---------------------------------------------------${ECHO_CLOSE}"
        cat  ${SEARCH_RESULT_FILE}.${SERVICE_NAME}.tmp
        cat  /tmp/${SH_NAME}-error.txt
        echo ''
        echo ''
    else
        # 错误信息
        cat  /tmp/${SH_NAME}-error.txt
    fi
    # 文件输出
    if [ `cat ${SEARCH_RESULT_FILE}.${SERVICE_NAME}.tmp | wc -l` -ne 0 ]; then
        R=`cat ${SEARCH_RESULT_FILE}.${SERVICE_NAME}.tmp`
        echo ${SERVICE_NAME} ${IMAGE_NAME} $R >> ${SEARCH_RESULT_FILE}
    fi
done < ${SERVICE_LIST_FILE_TMP}



# 输出到指定文件
if [ ! -z "${OUTPUT_FILE}" ]; then
    echo  ${OUTPUT_FILE} | grep -q \/
    if [ $? -ne 0 ]; then
        cp  ${SEARCH_RESULT_FILE}  ${OUTPUT_FILE}
    else
        if [ -d `echo ${OUTPUT_FILE%/*}` ]; then
            cp  ${SEARCH_RESULT_FILE}  ${OUTPUT_FILE}
        else
            echo -e  "\n猪猪侠警告：文件目录【`echo ${OUTPUT_FILE%/*}`】不存在，请创建先。\n"
        fi
    fi
fi

