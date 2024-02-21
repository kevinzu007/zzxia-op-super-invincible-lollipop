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

# 引入env.sh
. ${SH_PATH}/env.sh
#DOCKER_IMAGE_DEFAULT_PRE_NAME=
# 来自 ${MY_PRIVATE_ENVS_DIR} 目录下的 *.sec
#DOCKER_REPO_USER=
#DOCKER_REPO_PASSWORD=
#DOCKER_REPO_SERVER=
#DOCKER_REPO_URL_BASE=

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
LOG_HOME="/tmp/${SH_NAME}"
SERVICE_LIST_FILE="${SH_PATH}/docker-cluster-service.list"
SERVICE_LIST_FILE_TMP="${LOG_HOME}/docker-cluster-service.tmp.list.$(date +%S)"
SEARCH_RESULT_PREFILE="${LOG_HOME}/result.txt"
SEARCH_RESULT_ERR_PREFILE="${LOG_HOME}/result-err.txt"
# sh
FORMAT_TABLE_SH="${SH_PATH}/../tools/format_table.sh"


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
    用途：查询服务docker镜像
    依赖：
        ${SH_PATH}/env.sh
        ${SERVICE_LIST_FILE}
    注意：
        * 输入命令时，参数顺序不分先后
    用法:
        $0 [-h|--help]
        $0 [-l|--list]
        $0  <-I|--image-pre-name {镜像前置名称}>  <-t|--tag {%镜像版本%}>  <-e|--exclude {%镜像版本%}>  <-A|--time-ago {时间}>  <-n|--newest {第几新版本}>  <-o|--output {路径/文件}>  <{服务1} ... {服务2} ...>
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
        -I|--image-pre-name  指定镜像前置名称【DOCKER_IMAGE_PRE_NAME】，默认来自env.sh。注：镜像完整名称：\${DOCKER_REPO_SERVER}/\${DOCKER_IMAGE_PRE_NAME}/\${DOCKER_IMAGE_NAME}:\${DOCKER_IMAGE_TAG}
        -t|--tag        镜像版本(tag)。支持模糊查找，支持正则
        -e|--exclude    排除指定镜像版本，支持模糊定义，支持正则，一般用于排除今天打包的镜像版本，用于部署回滚
        -A|--time-ago   输出指定时间之前的版本（一般用于回滚），比如1d、24h、30m、100s，有此参数时会剔除自定义tag版本（比如：v1.2），只保留基于时间自动标记的tag版本（比如：2023.05.11.090746）
        -n|--newest     取第几新的镜像版本，例如： -n 1 ：代表取最新的那个镜像版本，-n 2：代表第二新的镜像，有此参数时会剔除自定义tag版本（比如：v1.2），只保留基于时间自动标记的tag版本（比如：2023.05.11.090746）
        -o|--output     输出搜索结果不为空的服务名称 到 指定【路径/文件】，输出格式为：【服务名a 镜像名a tag版本1 tag版本2 ... tag版本n\n服务名b 镜像名b tag版本1 tag版本2 ... tag版本n\n...】
    示例：
        $0  -h
        $0  -l
        #
        $0                       #--- 返回所有服务所有镜像版本
        $0  服务1                #--- 返回服务名为【服务1】的所有镜像版本
        $0  -I aa/bb  服务1      #--- 返回服务名为【服务1】，且镜像前置名称为【aa/bb】的所有镜像版本
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
        #
        $0  -A 2h  -n 1  服务1   #--- 返回服务名为【服务1】，且 2小时前 最新的镜像tag版本
    "
}


# 搜索镜像名返回匹配条件的tag版本
# 用法：F_SEARCH  {镜像名}
F_SEARCH()
{
    F_DOCKER_IMAGE_NAME=$1
    F_SEARCH_RESULT_PREFILE="${LOG_HOME}/F_SEARCH-result.txt--${F_DOCKER_IMAGE_NAME}"
    F_SEARCH_RESULT_ERR_PREFILE="${LOG_HOME}/F_SEARCH-result-err.txt--${F_DOCKER_IMAGE_NAME}"
    #
    curl -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD} -s -X GET ${DOCKER_REPO_URL_BASE}/${DOCKER_IMAGE_PRE_NAME}/${F_DOCKER_IMAGE_NAME}/tags/list | jq .tags[] > ${F_SEARCH_RESULT_PREFILE}  2>${F_SEARCH_RESULT_ERR_PREFILE}
    if [[ $? -ne 0 ]] || [[ $(cat ${F_SEARCH_RESULT_ERR_PREFILE} | grep -q 'NAME_UNKNOWN'; echo $?) -eq 0 ]]; then
        echo -e "\n猪猪侠警告：项目镜像不存在，或者访问【${DOCKER_REPO_SERVER}】服务器异常\n" 1>&2
        return 53
    fi
    #
    # 删除引号
    sed -i 's/\"//g'   ${F_SEARCH_RESULT_PREFILE}
    # 去掉空行
    sed -i '/^\s*$/d'  ${F_SEARCH_RESULT_PREFILE}
    #
    # 倒排序sort
    cat  ${F_SEARCH_RESULT_PREFILE} | sort -n -r >  ${F_SEARCH_RESULT_PREFILE}.sort
    #
    # 过滤like
    if [[ -n ${LIKE_THIS_DOCKER_IMAGE_TAG} ]]; then
        cat ${F_SEARCH_RESULT_PREFILE}.sort  |  grep -E ${LIKE_THIS_DOCKER_IMAGE_TAG}
    else
        cat ${F_SEARCH_RESULT_PREFILE}.sort
    fi > ${F_SEARCH_RESULT_PREFILE}.sort.like
    #
    # 过滤not_like
    if [[ -n "${EXCLUDE_THIS_DOCKER_IMAGE_TAG}" ]]; then
        cat ${F_SEARCH_RESULT_PREFILE}.sort.like | grep -E -v ${EXCLUDE_THIS_DOCKER_IMAGE_TAG}
    else
        cat ${F_SEARCH_RESULT_PREFILE}.sort.like
    fi > ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like
    #
    # 过滤time ago
    if [[ -n ${TIME_AGO_S} ]]; then
        # 删除非标准版本的行，仅保留数字开头的自动标记版本
        # 注：只有自动标记的版本可以计算时间，示例：2023.05.11.090746
        cat ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like  |  sed -n -E '/[0-9]{4}\.[0-9]{2}\.[0-9]{2}\.[0-9]{4}/p'  > ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like.x_time_ago
        n=0
        MAX=$(cat ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like.x_time_ago | wc -l)
        while true
        do
            let n=${n}+1
            if [[ ${n} > ${MAX} ]]; then
                break
            fi
            LINE=$(sed -n "${n}p"  ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like.x_time_ago)
            LINE_DATE=$(echo ${LINE:0:4}-${LINE:5:2}-${LINE:8:2} ${LINE:11:2}:${LINE:13:2}:${LINE:15:2})
            LINE_S=$(date -d "${LINE_DATE}" +%s)
            NOW_S=$(date +%s)
            let LINE_S_ADD=${LINE_S}+${TIME_AGO_S}
            if [[ ${LINE_S_ADD} -lt ${NOW_S} ]]; then
                sed -n "${n}p"  ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like.x_time_ago
            fi
        done
    else
        cat ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like
    fi > ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like.time_ago
    #
    # 过滤第几新
    if [[ -n ${NUMBER_NEWEST} ]]; then
        # 删除非标准版本的行，仅保留数字开头的自动标记版本
        # 只有自动标记的版本取第几新才有意义，示例：2023.05.11.090746
        sed -i -n -E '/[0-9]{4}\.[0-9]{2}\.[0-9]{2}\.[0-9]{4}/p'  ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like.time_ago
        cat ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like.time_ago | sed -n ${NUMBER_NEWEST}p
    else
        cat ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like.time_ago
    fi > ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like.time_ago.newest
    #
    # 输出
    if [[ -s ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like.time_ago.newest ]]; then
        cat  ${F_SEARCH_RESULT_PREFILE}.sort.like.not_like.time_ago.newest
        return 0
    else
        echo  -e "\n猪猪侠警告：项目镜像tag搜索结果为空\n"  1>&2
        echo 55
    fi
}



# 参数检查
# 检查参数是否符合要求，会对参数进行重新排序，列出的参数会放在其他参数的前面，这样你在输入脚本参数时，不需要关注脚本参数的输入顺序，例如：'$0 aa bb -w wwww ccc'
# 但除了参数列表中指定的参数之外，脚本参数中不能出现以'-'开头的其他参数，例如按照下面的参数要求，这个命令是不能正常运行的：'$0 -w wwww  aaa --- bbb ccc'
# 如果想要在命令中正确运行上面以'-'开头的其他参数，你可以在'-'参数前加一个'--'参数，这个可以正确运行：'$0 -w wwww  aaa -- --- bbb ccc'
# 你可以通过'bash -x'方式运行脚本观察'--'的运行规律
#
TEMP=`getopt -o hlI:t:e:A:n:o:  -l help,list,image-pre-name:,tag:,exclude:,time-ago:,newest:,output: -- "$@"`
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
            cat  ${SERVICE_LIST_FILE} | grep -v '^ *$' | grep -v '^#' | awk  'BEGIN {FS="|"} {printf "%s | %s\n", $2,$3}'  >> /tmp/docker-image-search-for-list.txt
            ${FORMAT_TABLE_SH}  --delimeter '|'  --file /tmp/docker-image-search-for-list.txt
            exit
            ;;
        -I|--image-pre-name)
            IMAGE_PRE_NAME=$2
            IMAGE_PRE_NAME_ARG="--image-pre-name ${IMAGE_PRE_NAME}"
            shift 2
            ;;
        -t|--tag)
            LIKE_THIS_DOCKER_IMAGE_TAG=$2
            shift 2
            ;;
        -e|--exclude)
            EXCLUDE_THIS_DOCKER_IMAGE_TAG=$2
            shift 2
            ;;
        -A|--time_ago)
            TIME_AGO=$2
            shift 2
            grep -E -q '[1-9]+[0-9]*[dhms]$' <<< ${TIME_AGO}
            if [ $? -ne 0 ]; then
                echo -e "\n猪猪侠警告：参数【-A|--time_ago】参数不合法，请查看帮助【$0 --help】\n"
                exit 51
            fi
            TIME_AGO_UNIT=${TIME_AGO:0-1:1}
            TIME_AGO_NUM=${TIME_AGO:0:-1}
            case ${TIME_AGO_UNIT} in
                d)
                    let TIME_AGO_S=${TIME_AGO_NUM}*24*60*60
                    ;;
                h)
                    let TIME_AGO_S=${TIME_AGO_NUM}*60*60
                    ;;
                m)
                    let TIME_AGO_S=${TIME_AGO_NUM}*60
                    ;;
                s)
                    let TIME_AGO_S=${TIME_AGO_NUM}
                    ;;
            esac
            ;;
        -n|--newest)
            NUMBER_NEWEST=$2
            shift 2
            grep -q '^[[:digit:]]\+$' <<< ${NUMBER_NEWEST}
            if [ $? -ne 0 ]; then
                echo -e "\n猪猪侠警告：参数【-n|--newest】参数不合法，请查看帮助【$0 --help】\n"
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



# 建立base目录
[ -d "${LOG_HOME}" ] || mkdir -p  "${LOG_HOME}"


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



# 输出到指定文件目录准备
if [ -n "${OUTPUT_FILE}" ]; then
    echo  ${OUTPUT_FILE} | grep -q \/
    if [[ $? -eq 0 ]]; then
        if [ ! -d `echo ${OUTPUT_FILE%/*}` ]; then
            echo -e  "\n猪猪侠警告：文件目录【`echo ${OUTPUT_FILE%/*}`】不存在，请创建先。\n"
            exit 51
        fi
    fi
fi



# 开始
NUM=0
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    SERVICE_NAME=`echo ${LINE} | cut -d \| -f 2`
    SERVICE_NAME=`echo ${SERVICE_NAME}`
    #
    DOCKER_IMAGE_PRE_NAME=`echo ${LINE} | cut -d \| -f 3`
    DOCKER_IMAGE_PRE_NAME=`eval echo ${DOCKER_IMAGE_PRE_NAME}`    #--- 用eval将配置文件中项的变量转成值，下同
    # 命令行参数优先级最高（1 arg，2 listfile，3 env.sh）
    if [[ -n ${IMAGE_PRE_NAME} ]]; then
        DOCKER_IMAGE_PRE_NAME=${IMAGE_PRE_NAME}
    elif [[ -z ${DOCKER_IMAGE_PRE_NAME} ]]; then
        DOCKER_IMAGE_PRE_NAME=${DOCKER_IMAGE_DEFAULT_PRE_NAME}
    fi
    #
    DOCKER_IMAGE_NAME=`echo ${LINE} | cut -d \| -f 4`
    DOCKER_IMAGE_NAME=`eval echo ${DOCKER_IMAGE_NAME}`    #--- 用eval将配置文件中项的变量转成值，下同
    # 跳过服务名名或镜像名为空的行
    if [ "x${SERVICE_NAME}" = 'x' -o "x${DOCKER_IMAGE_NAME}" = 'x' ]; then
        continue
    fi
    #
    > ${SEARCH_RESULT_PREFILE}.${SERVICE_NAME}.tmp
    > ${SEARCH_RESULT_ERR_PREFILE}.${SERVICE_NAME}.tmp
    # 写入文件
    F_SEARCH ${DOCKER_IMAGE_NAME}  > ${SEARCH_RESULT_PREFILE}.${SERVICE_NAME}.tmp  2>${SEARCH_RESULT_ERR_PREFILE}.${SERVICE_NAME}.tmp
    r=$?
    #
    # 输出
    if [ -z "${OUTPUT_FILE}" ]; then
        # 输出到屏幕
        let NUM=${NUM}+1
        echo -e "${ECHO_NORMAL}# ---------------------------------------------------${ECHO_CLOSE}"
        echo -e "${ECHO_NORMAL}# ${NUM} - 服务名：${SERVICE_NAME} - 镜像名：${DOCKER_IMAGE_NAME} ${ECHO_CLOSE}"
        echo -e "${ECHO_NORMAL}# ---------------------------------------------------${ECHO_CLOSE}"
        cat  ${SEARCH_RESULT_PREFILE}.${SERVICE_NAME}.tmp
        cat  ${SEARCH_RESULT_ERR_PREFILE}.${SERVICE_NAME}.tmp  1>&2
        echo ''
        echo ''
    else
        # 输出到文件
        R=`cat ${SEARCH_RESULT_PREFILE}.${SERVICE_NAME}.tmp`
        echo ${SERVICE_NAME} ${DOCKER_IMAGE_NAME} $R >> ${OUTPUT_FILE}
        # 错误信息
        if [[ $r != 0 ]]; then
            E=$(cat ${SEARCH_RESULT_ERR_PREFILE}.${SERVICE_NAME}.tmp)
            echo "${SERVICE_NAME} ${DOCKER_IMAGE_NAME} $E"  1>&2
        fi
    fi
done < ${SERVICE_LIST_FILE_TMP}


