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

# 自动从/etc/profile.d/run-env.sh引入以下变量
RUN_ENV=${RUN_ENV:-'dev'}
DOMAIN=${DOMAIN:-"xxx.lan"}

# 引入env
. ${SH_PATH}/deploy.env
DINGDING_API=${DINGDING_API:-"请定义"}
BUILD_SKIP_TEST=${BUILD_SKIP_TEST:-'NO'}  #--- 跳过测试
#USER_DB=

# 本地env
export TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
DATE_TIME=`date -d "${TIME}" +%Y%m%dt%H%M%S`
#
LOG_BASE="${SH_PATH}/tmp/log"
LOG_HOME="${LOG_BASE}/${DATE_TIME}"
#
DOCKER_IMAGE_VER=$(date -d "${TIME}" +%Y.%m.%d.%H%M%S)
#
BUILD_FORCE='NO'
# 独有
N_proc=2    #--- 并行构建数量
PARA_PROJECT_LIST_FILE="${SH_PATH}/project.list"
PARA_PROJECT_LIST_FILE_TMP="${LOG_HOME}/${SH_NAME}-project.list.tmp"
PARA_BUILD_OK_LIST_FILE="${LOG_HOME}/${SH_NAME}-build-OK.list"
PARA_BUILD_HISTORY_CURRENT_FILE="${LOG_HOME}/${SH_NAME}-history.current"
# 子脚本参数
BASE_PROJECT_LIST_FILE_TMP="${LOG_HOME}/${SH_NAME}-export-project.list.tmp"
export PROJECT_LIST_FILE_TMP=
BASE_BUILD_OK_LIST_FILE="${LOG_HOME}/${SH_NAME}-export-build-OK.list"
export BUILD_OK_LIST_FILE=
BASE_BUILD_OK_LIST_FILE_function="${LOG_HOME}/${SH_NAME}-export-build-OK.list.function"
export BUILD_OK_LIST_FILE_function=''
export MY_EMAIL=''
export MY_XINGMING=''
# 公共
FUCK_HISTORY_FILE="${LOG_BASE}/fuck.history"
# LOG_DOWNLOAD_SERVER
BUILD_LOG_PJ_NAME="build-log"
if [ "x${RUN_ENV}" = "xprod" ]; then
    LOG_DOWNLOAD_SERVER="https://${BUILD_LOG_PJ_NAME}.${DOMAIN}"
else
    LOG_DOWNLOAD_SERVER="https://${RUN_ENV}-${BUILD_LOG_PJ_NAME}.${DOMAIN}"
fi
# sh
BUILD_SH="${SH_PATH}/build.sh"
DRAW_TABLE_SH="${SH_PATH}/../op/draw_table.sh"
FORMAT_TABLE_SH="${SH_PATH}/../op/format_table.sh"
DINGDING_MARKDOWN_PY="${SH_PATH}/../op/dingding_conver_to_markdown_list-deploy.py"

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



# 删除空行（以及只有tab、空格的行）
#sed -i '/^\s*$/d'  ${PARA_PROJECT_LIST_FILE}
## 删除行中的空格,markdown文件不要这样
#sed -i 's/[ \t]*//g'  ${PARA_PROJECT_LIST_FILE}



# 用法：
F_HELP()
{
    echo "
    用途：以并行的方式运行构建脚本，以加快构建速度
    依赖：
        /etc/profile.d/run-env.sh
        ${SH_PATH}/deploy.env
        ${PARA_PROJECT_LIST_FILE}
        ${BUILD_SH}
        ${FORMAT_TABLE_SH}
        ${DINGDING_MARKDOWN_PY}
    注意：
        * 名称正则表达式完全匹配，会自动在正则表达式的头尾加上【^ $】，请规避
        * 输入命令时，参数顺序不分先后
    用法:
        $0  [-h|--help]
        $0  [-l|--list]
        $0  <-n|--number>  <-c [dockerfile|java|node|自定义]>  <-b {代码分支}>  <-e|--email {邮件地址}>  <-s|--skiptest>  <-f|--force>  <{项目1}  {项目2} ... {项目n}> ... {项目名称正则表达式完全匹配}>
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
        -n|--number    并行构建项目的数量，默认为2个
        -c|--category  指定构建项目语言类别：【dockerfile|java|node|自定义】，参考：${PARA_PROJECT_LIST_FILE}
        -b|--branch    指定代码分支，默认来自deploy.env
        -e|--email     发送日志到指定邮件地址，如果与【-U|--user-name】同时存在，则将会被替代
        -s|--skiptest  跳过测试，默认来自deploy.env
        -f|--force     强制重新构建（无论是否有更新）
    示例:
        #
        $0  -l     #--- 列出可构建的项目清单
        # 在build.sh的用法基础上选择是否加上【-n】参数即可
        $0                            #--- 构建所有项目，用默认分支，同时构建默认个
        $0  -n 4                      #--- 构建所有项目，用默认分支，同时构建4个
        $0  -n 4  -b 分支a            #--- 构建所有项目，用【分支a】，同时构建4个
        $0  -n 4  -c java             #--- 构建所有java项目，用默认分支，同时构建4个
        $0  项目1 项目2                        #--- 构建【项目1、项目2】，用默认分支，同时构建默认个
        $0  --email xm@xxx.com  项目1 项目2    #--- 构建【项目1、项目2】，用默认分支，同时构建默认个，将错误日志发送到邮箱【xm@xxx.com】
        $0  -s -f  项目1 项目2                 #--- 构建【项目1、项目2】，用默认分支，同时构建默认个，跳过测试，强制重新构建（无论是否有更新）
        $0  sss                       #--- 构建项目名称正则匹配【^sss$】的项目，用默认分支，同时构建默认个
        # 更多示例请参考【build.sh】
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



# 查找项目语言类别与项目名称，并追加到临时文件
# 用法：F_FIND_PROJECT  [F_THIS_LANGUAGE_CATEGORY]  <F_THIS_PROJECT>
F_FIND_PROJECT ()
{
    F_THIS_LANGUAGE_CATEGORY="$1"
    F_THIS_PROJECT="$2"
    F_GET_IT="N"
    #
    if [[ -z "${F_THIS_PROJECT}" ]]; then
        # 匹配类别
        while read LINE
        do
            # 跳过以#开头的行或空行
            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
            #
            F_C=`echo ${LINE} | awk -F '|' '{print $2}'`
            F_C=`echo ${F_C}`
            if [[ "x${F_C}" == "x${F_THIS_LANGUAGE_CATEGORY}" ]]; then
                echo "${LINE}"
                F_GET_IT="YES"
            fi
        done < "${PARA_PROJECT_LIST_FILE}"
        #
    else
        # 匹配类别与项目名称
        grep -v '^#' ${PARA_PROJECT_LIST_FILE} | grep ${F_THIS_LANGUAGE_CATEGORY}  | grep ${F_THIS_PROJECT} > "${LOG_HOME}/F_FIND_PROJECT-search.txt"
        # 空列表也ok
        while read LINE
        do
            # 跳过以#开头的行或空行
            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
            #
            F_C=`echo ${LINE} | awk -F '|' '{print $2}'`
            F_C=`echo ${F_C}`
            F_P=`echo ${LINE} | awk -F '|' '{print $3}'`
            F_P=`echo ${F_P}`
            if [[ ${F_C} == ${F_THIS_LANGUAGE_CATEGORY} ]]  &&  [[ ${F_P} =~ ^${F_THIS_PROJECT}$ ]]; then
                echo "${LINE}"
                # 仅匹配一次
                #F_GET_IT="YES"
                #break
                # 匹配多次次
                F_GET_IT='YES'
            fi
        done < ${LOG_HOME}/F_FIND_PROJECT-search.txt
    fi
    # 函数返回
    if [[ ${F_GET_IT} != "YES" ]]; then
        return 1
    else
        return 0
    fi
}



# 用户搜索
F_USER_SEARCH()
{
    F_USER_NAME=$1
    while read LINE
    do
        CURRENT_USER_ID=`echo $LINE | cut -d '|' -f 2`
        CURRENT_USER_ID=`echo ${CURRENT_USER_ID}`
        CURRENT_USER_NAME=`echo $LINE | cut -d '|' -f 3`
        CURRENT_USER_NAME=`echo ${CURRENT_USER_NAME}`
        CURRENT_USER_XINGMING=`echo $LINE | cut -d '|' -f 4`
        CURRENT_USER_XINGMING=`echo ${CURRENT_USER_XINGMING}`
        CURRENT_USER_EMAIL=`echo $LINE | cut -d '|' -f 5`
        CURRENT_USER_EMAIL=`echo ${CURRENT_USER_EMAIL}`
        if [ "${F_USER_NAME}" = "${CURRENT_USER_ID}"  -o  "${F_USER_NAME}" = "${CURRENT_USER_NAME}" ]; then
            echo "${CURRENT_USER_XINGMING} ${CURRENT_USER_EMAIL}"
            return 0
        fi
    done < "${USER_DB}"
    return 1
}



# 参数检查
TEMP=`getopt -o hln:c:b:e:sf  -l help,list,number:,category:,branch:,email:,skiptest,force -- "$@"`
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
            exit 0
            ;;
        -l|--list)
            #awk 'BEGIN {FS="|"} { if ($3 !~ /^ *$/) {sub(/^[[:blank:]]*/,"",$3); sub(/[[:blank:]]*$/,"",$3); printf "%2d %5s  %s\n",NR,$2,$3} }'  ${PARA_PROJECT_LIST_FILE}
            sed  -E  -e '/^\s*$/d'  -e '/^##.*$/d'  -e '/---/d'  -e '/^#.*PRIORITY/d'  ${PARA_PROJECT_LIST_FILE}  > /tmp/para-project-for-list.txt
            ${FORMAT_TABLE_SH}  --delimeter '|'  --file /tmp/para-project-for-list.txt
            exit 0
            ;;
        -n|--number)
            N_proc=$2
            shift 2
            grep -q '^[[:digit:]]\+$' <<< ${N_proc}
            if [ $? -ne 0 ]; then
                echo -e "\n猪猪侠警告：参数【-n <并行数量>】必须为整数！\n"
                exit 51
            fi
            ;;
        -c|--category)
            THIS_LANGUAGE_CATEGORY=$2
            shift 2
            ;;
        -b|--branch)
            GIT_BRANCH=$2
            shift 2
            ;;
        -e|--email)
            MY_EMAIL=$2
            shift 2
            export MY_EMAIL
            EMAIL_REGULAR='^[a-zA-Z0-9]+[a-zA-Z0-9_\.]*@([a-zA-Z0-9]+[a-zA-Z0-9\-]*[a-zA-Z0-9]\.)*[a-z]+$'
            if [[ ! "${MY_EMAIL}" =~ ${EMAIL_REGULAR} ]]; then
                echo -e "\n猪猪侠警告：【${MY_EMAIL}】邮件地址不合法\n"
                exit 51
            fi
            ;;
        -s|--skiptest)
            BUILD_SKIP_TEST="YES"
            shift
            ;;
        -f|--force)
            BUILD_FORCE='YES'
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


# 用户信息
# if sudo -i 取${SUDO_USER}；
# if sudo cmd 取${LOGNAME}
LOGIN_USER_NAME=${SUDO_USER:-"${LOGNAME}"}
F_USER_SEARCH ${LOGIN_USER_NAME} > /dev/null
if [ $? -eq 0 ]; then
    R=`F_USER_SEARCH ${LOGIN_USER_NAME}`
    export MY_XINGMING=`echo $R | cut -d ' ' -f 1`
    export MY_EMAIL=${MY_EMAIL:-"`echo $R | cut -d ' ' -f 2`"}
else
    export MY_XINGMING='X-Man'
fi



# 建立base目录
[ -d "${LOG_HOME}" ] || mkdir -p  ${LOG_HOME}



# 待搜索的服务清单
> ${PARA_PROJECT_LIST_FILE_TMP}
## 类别
if [[ -z "${THIS_LANGUAGE_CATEGORY}" ]]; then
    # 参数个数
    if [[ $# -eq 0 ]]; then
        cp  ${PARA_PROJECT_LIST_FILE}  ${PARA_PROJECT_LIST_FILE_TMP}
    else
        # 指定项目
        for i in $@
        do
            #
            GET_IT='N'
            while read LINE
            do
                # 跳过以#开头的行或空行
                [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
                #
                PROJECT_NAME=`echo $LINE | awk -F '|' '{print $3}'`
                PROJECT_NAME=`echo ${PROJECT_NAME}`
                if [[ ${PROJECT_NAME} =~ ^$i$ ]]; then
                    echo $LINE >> ${PARA_PROJECT_LIST_FILE_TMP}
                    # 仅匹配一次
                    #GET_IT='YES'
                    #break
                    # 匹配多次
                    GET_IT='YES'
                fi
            done < ${PARA_PROJECT_LIST_FILE}
            #
            if [[ $GET_IT != 'YES' ]]; then
                echo -e "\n猪猪侠警告：项目【${i}】不在项目列表【${PARA_PROJECT_LIST_FILE}】中，请检查！\n"
                exit 51
            fi
        done
    fi
else
    #
    if [[ "${THIS_LANGUAGE_CATEGORY}" == "all" ]]; then
        # 所有项目
        cp  ${PARA_PROJECT_LIST_FILE}  ${PARA_PROJECT_LIST_FILE_TMP}
        # 忽略
        if [[ $# -ne 0 ]]; then
            echo -e "\n猪猪侠警告：这些参数将会被忽略【 $@ 】\n"
        fi
    elif [[ $# -eq 0 ]]; then
        # 仅构建指定类别项目
        # 查找
        F_FIND_PROJECT ${THIS_LANGUAGE_CATEGORY} >> ${PARA_PROJECT_LIST_FILE_TMP}
        if [[ $? -ne 0 ]]; then
            echo -e "\n猪猪侠警告：没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目，请检查！\n"
            ${DINGDING_MARKDOWN_PY}  "【Info:Build:${RUN_ENV}】" "猪猪侠警告：没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目，请检查！" > /dev/null
            exit 51
        fi
    else
        # 仅构建指定类别指定项目
        for i in "$@"; do
            # 查找
            F_FIND_PROJECT ${THIS_LANGUAGE_CATEGORY} $i >> ${PARA_PROJECT_LIST_FILE_TMP}
            if [[ $? -ne 0 ]]; then
                echo -e "\n猪猪侠警告：没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目【$i】，请检查！\n"
                ${DINGDING_MARKDOWN_PY}  "【Info:Build:${RUN_ENV}】" "猪猪侠警告：没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目【$i】，请检查！" > /dev/null
                exit 51
            fi
        done
    fi
fi
# 删除无关行
#sed  -i  -E  -e '/^\s*$/d'  -e '/^#.*$/d'  -e 's/[ \t]*//g'  ${PARA_PROJECT_LIST_FILE_TMP}
sed  -i  -E  -e '/^\s*$/d'  -e '/^##.*$/d'  -e '/---/d'  -e '/^#.*PRIORITY/d'  ${PARA_PROJECT_LIST_FILE_TMP}
# 优先级排序
> ${PARA_PROJECT_LIST_FILE_TMP}.sort
for i in  `awk -F '|' '{split($9,a," ");print NR,a[1]}' ${PARA_PROJECT_LIST_FILE_TMP}  |  sort -n -k 2 |  awk '{print $1}'`
do
    awk "NR=="$i'{print}' ${PARA_PROJECT_LIST_FILE_TMP}  >> ${PARA_PROJECT_LIST_FILE_TMP}.sort
done
cp  ${PARA_PROJECT_LIST_FILE_TMP}.sort  ${PARA_PROJECT_LIST_FILE_TMP}
# 加表头
sed -i  '1i#| **类别** | **项目名** | **构建方法** | **输出方法** | **镜像名** | **链接node_project** | **GOGOGO发布方式** | **优先级** |'  ${PARA_PROJECT_LIST_FILE_TMP}
# 屏显
echo -e "${ECHO_NORMAL}############################ 开始并行构建 ############################${ECHO_CLOSE}"   #--- 80 (80-70-60)
echo -e "\n【${SH_NAME}】待并行构建项目清单："
${FORMAT_TABLE_SH}  --delimeter '|'  --file ${PARA_PROJECT_LIST_FILE_TMP}
#echo -e "\n"



# 初始化命名管道
# 参考：https://blog.csdn.net/yjn03151111/article/details/41244713
# 命名管道也被称为FIFO文件，它是一种特殊类型的文件，它在文件系统中以文件名的形式存在
#N_proc=2                # 设定同时执行的进程数上限
P_fifo="/tmp/$$.fifo"    # 以PID作为文件名，避免重名
mkfifo $P_fifo           # 创建fifo命名管道, 以上面的文件名创建
exec 6<> $P_fifo         # 以读写方式打开命名管道，并设置文件标识符fd为6。 >为写入 <为读取 <>为读写
rm -f $P_fifo            # 删除FIFO文件，可有可无
#
for((i=1; i<=N_proc; i++)); do
    echo           # 往命名管道中写入N_proc个空行，用来模拟N_proc个令牌
done >&6           # 写入文件标识符fd为6的命名管道，初始化命名管道



# 开始
# 强制构建
BUILD_FORCE_OPT=""
if [ "x${BUILD_FORCE}" = "xYES" ]; then
    BUILD_FORCE_OPT="--force"
fi
# 跳过测试
BUILD_SKIP_TEST_OPT=""
if [[ ${BUILD_SKIP_TEST} == 'YES' ]]; then
    BUILD_SKIP_TEST_OPT="--skiptest"
fi
#
BUILD_CHECK_COUNT=0
BUILD_SUCCESS_COUNT=0
BUILD_NOCHANGE_COUNT=0
BUILD_NOTNEED_COUNT=0
BUILD_ERROR_COUNT=0
> ${PARA_BUILD_OK_LIST_FILE}
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    LANGUAGE_CATEGORY=`echo ${LINE} | cut -d \| -f 2`
    LANGUAGE_CATEGORY=`echo ${LANGUAGE_CATEGORY}`
    #
    PJ=`echo ${LINE} | cut -d \| -f 3`
    PJ=`echo ${PJ}`
    #
    BUILD_METHOD=`echo ${LINE} | cut -d \| -f 4`
    BUILD_METHOD=`echo ${BUILD_METHOD}`
    #
    BUILD_CHECK_COUNT=`expr ${BUILD_CHECK_COUNT} + 1`
    echo -e "${ECHO_NORMAL}++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++${ECHO_CLOSE}"   #--- 70 (80-70-60)
    echo -e "${ECHO_NORMAL}${BUILD_CHECK_COUNT} - ${PJ} :${ECHO_CLOSE}"
    echo ""
    # build
    export PROJECT_LIST_FILE_TMP="${BASE_PROJECT_LIST_FILE_TMP}.${PJ}"
    export BUILD_OK_LIST_FILE="${BASE_BUILD_OK_LIST_FILE}.${PJ}"
    export BUILD_OK_LIST_FILE_function="${BASE_BUILD_OK_LIST_FILE_function}.${PJ}"
    > ${BUILD_OK_LIST_FILE_function}
    #
    read -u 6       # 获取令牌。从命名管道fd6中读取一行，模拟领取一个令牌。由于FIFO特殊的读写机制，若没有空余的行可以读取，则进程会等待直至有可以读取的空余行
    {
        ${BUILD_SH}  --mode function  --category ${LANGUAGE_CATEGORY}  --branch="${GIT_BRANCH}"  ${BUILD_SKIP_TEST_OPT}  ${BUILD_FORCE_OPT}  ${PJ}  > /dev/null 2>&1
        if [[ `cat ${BUILD_OK_LIST_FILE_function} | wc -l` -eq 1 ]]; then
            cat  ${BUILD_OK_LIST_FILE_function} >> ${PARA_BUILD_OK_LIST_FILE}
        else
            echo  "${PJ} : 非预期错误" >> ${PARA_BUILD_OK_LIST_FILE}
        fi
        echo >&6    # 归还令牌。完成后往命名管道写入一行，模拟归还令牌操作
    } &             # 后台运行，故加上 & 命令
done < ${PARA_PROJECT_LIST_FILE_TMP}
#
wait          # 等待所有后台进程完成
exec 6>&-     # 释放文件标识符
#
echo -e "\nParallel Build 完成！\n"


# 输出结果
BUILD_SUCCESS_COUNT=`cat ${PARA_BUILD_OK_LIST_FILE} | grep -o 'Build 成功' | wc -l`
BUILD_NOCHANGE_COUNT=`cat ${PARA_BUILD_OK_LIST_FILE} | grep -o '无更新' | wc -l`
BUILD_NOTNEED_COUNT=`cat ${BUILD_OK_LIST_FILE} | grep -o '无需 Build' | wc -l`
let BUILD_ERROR_COUNT=${BUILD_CHECK_COUNT}-${BUILD_SUCCESS_COUNT}-${BUILD_NOCHANGE_COUNT}-${BUILD_NOTNEED_COUNT}
TIME_END=`date +%Y-%m-%dT%H:%M:%S`
MESSAGE_END="项目构建已完成！ 共企图构建${BUILD_CHECK_COUNT}个项目，成功构建${BUILD_SUCCESS_COUNT}个项目，${BUILD_NOCHANGE_COUNT}个项目无更新，${BUILD_NOTNEED_COUNT}个项目无需 Build，${BUILD_ERROR_COUNT}个项目出错。"
# 消息回显拼接
>  ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "====== 并行构建报告 ======" >> ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo -e "${ECHO_REPORT}################################# 并行构建报告 #################################${ECHO_CLOSE}"    #--- 80 (80-70-60)
#
echo "所在环境：${RUN_ENV}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "造 浪 者：${MY_XINGMING}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "开始时间：${TIME}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "结束时间：${TIME_END}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "代码分支：${GIT_BRANCH}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "Docker镜像版本：${DOCKER_IMAGE_VER}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "并行数量：${N_proc}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "构建清单：" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
# 输出到文件
echo "----------------------------------------------------------------------" >> ${PARA_BUILD_HISTORY_CURRENT_FILE}    #--- 70 (80-70-60)
cat  ${PARA_BUILD_OK_LIST_FILE}            >> ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "----------------------------------------------------------------------" >> ${PARA_BUILD_HISTORY_CURRENT_FILE}    #--- 70 (80-70-60)
# 输出屏幕
${FORMAT_TABLE_SH}  --delimeter ':'  --title '**项目名称**:**构建**'  --file ${PARA_BUILD_OK_LIST_FILE}
#
F_TimeDiff  "${TIME_START}" "${TIME_END}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "日志下载地址：${LOG_DOWNLOAD_SERVER}/file/${DATE_TIME}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
#
echo "${MESSAGE_END}" >> ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo -e "${ECHO_REPORT}${MESSAGE_END}${ECHO_CLOSE}"
# 保存历史
cat ${PARA_BUILD_HISTORY_CURRENT_FILE} >> ${FUCK_HISTORY_FILE}
echo -e "\n\n\n"  >> ${FUCK_HISTORY_FILE}

# markdown
# 删除空行（以及只有tab、空格的行）
sed -i '/^\s*$/d'  ${PARA_BUILD_HISTORY_CURRENT_FILE}
t=1
while read LINE
do
    MSG[$t]=$LINE
    #echo ${MSG[$t]}
    let  t=$t+1
done < ${PARA_BUILD_HISTORY_CURRENT_FILE}
${DINGDING_MARKDOWN_PY}  "【Info:Build:${RUN_ENV}】" "${MSG[@]}" > /dev/null



