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

# 引入/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
#.  /etc/profile        #-- 非终端界面不会自动引入，必须主动引入
#RUN_ENV=
#DOMAIN=
#USER_DB_FILE=
#USER_DB_FILE_APPEND_1=
#DINGDING_WEBHOOK_API_deploy=

# 引入env.sh
. ${SH_PATH}/env.sh
#LOLLIPOP_PLATFORM_NAME=
#LOLLIPOP_DB_HOME=
#LOLLIPOP_LOG_BASE=
#BUILD_LOG_WEBSITE_DOMAIN_A=
#BUILD_SKIP_TEST=
#GIT_DEFAULT_BRANCH=
# 来自 ${MY_PRIVATE_ENVS_DIR} 目录下的 *.sec


# 本地env
GAN_WHAT_FUCK='P_Build'
NEED_PRIVILEGES='build'                   #-- 运行此程序需要的权限，如果需要多个权限，则用【&】分隔
export TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
DATE_TIME=`date -d "${TIME}" +%Y%m%dT%H%M%S`
#
LOG_HOME="${LOLLIPOP_LOG_BASE}/${DATE_TIME}"
#
DOCKER_IMAGE_TAG=$(date -d "${TIME}" +%Y.%m.%d.%H%M%S)
#
BUILD_FORCE='NO'
# 独有
N_proc=2    #--- 并行构建数量
PARA_PROJECT_LIST_FILE="${SH_PATH}/project.list"
PARA_PROJECT_LIST_FILE_TMP="${LOG_HOME}/${SH_NAME}-project.list.tmp"
PARA_BUILD_OK_LIST_FILE="${LOG_HOME}/${SH_NAME}-build-OK.list"
PARA_BUILD_HISTORY_CURRENT_FILE="${LOG_HOME}/${SH_NAME}-history.current"
# 来自webhook，传递给子脚本
export HOOK_USER_INFO_FROM
export HOOK_GAN_ENV
export HOOK_USER_NAME
export HOOK_USER_XINGMING
export HOOK_USER_EMAIL
# 传递给子脚本
BASE_PROJECT_LIST_FILE_TMP="${LOG_HOME}/${SH_NAME}-export-project.list.tmp"
export PROJECT_LIST_FILE_TMP=
BASE_BUILD_OK_LIST_FILE="${LOG_HOME}/${SH_NAME}-export-build-OK.list"
export BUILD_OK_LIST_FILE=
BASE_BUILD_OK_LIST_FILE_function="${LOG_HOME}/${SH_NAME}-export-build-OK.list.function"
export BUILD_OK_LIST_FILE_function=''
export USER_INFO_FROM=${HOOK_USER_INFO_FROM:-'local'}     #--【local|hook_hand|hook_gitlab】，默认：local
export MY_USER_NAME=''
export MY_USER_XINGMING=''
export MY_USER_EMAIL=''
# 公共
FUCK_HISTORY_FILE="${LOLLIPOP_DB_HOME}/fuck.history"
# LOG_DOWNLOAD_SERVER
if [ "x${RUN_ENV}" = "xprod" ]; then
    LOG_DOWNLOAD_SERVER="https://${BUILD_LOG_WEBSITE_DOMAIN_A}.${DOMAIN}"
else
    LOG_DOWNLOAD_SERVER="https://${RUN_ENV}-${BUILD_LOG_WEBSITE_DOMAIN_A}.${DOMAIN}"
fi
# sh
BUILD_SH="${SH_PATH}/build.sh"
DRAW_TABLE_SH="${SH_PATH}/../tools/draw_table.sh"
FORMAT_TABLE_SH="${SH_PATH}/../tools/format_table.sh"
DINGDING_SEND_DEPLOY_SH="/usr/local/bin/dingding_conver_to_markdown_list.sh  --webhook ${DINGDING_WEBHOOK_API_deploy}"
# 引入函数
.  ${SH_PATH}/function.sh



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
        /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
        ${SH_PATH}/env.sh
        ${PARA_PROJECT_LIST_FILE}
        ${BUILD_SH}
        ${FORMAT_TABLE_SH}
        ${DINGDING_SEND_DEPLOY_SH}
    注意：
        * 名称正则表达式完全匹配，会自动在正则表达式的头尾加上【^ $】，请规避
        * 输入命令时，参数顺序不分先后
    用法:
        $0  [-h|--help]
        $0  [-l|--list]
        $0  <-n|--number>  <-c [dockerfile|java|node|自定义]>  <-b {代码分支}>  <-I|--image-pre-name {镜像前置名称}>  <-e|--email {邮件地址}>  <-s|--skiptest>  <-f|--force>  <{项目1}  {项目2} ... {项目n}> ... {项目名称正则表达式完全匹配}>
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
        -b|--branch    指定代码分支，默认来自env.sh
        -I|--image-pre-name  指定镜像前置名称【DOCKER_IMAGE_PRE_NAME】，默认来自env.sh。注：镜像完整名称：\${DOCKER_REPO_SERVER}/\${DOCKER_IMAGE_PRE_NAME}/\${DOCKER_IMAGE_NAME}:\${DOCKER_IMAGE_TAG}
        -e|--email     发送日志到指定邮件地址，如果与【-U|--user-name】同时存在，则将会被替代
        -s|--skiptest  跳过测试，默认来自env.sh
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
        $0  -I aaa/bbb  项目1  项目2  #--- 构建项目【项目1、项目2】，用默认分支，同时构建默认个，生成的镜像前置名称为【DOCKER_IMAGE_PRE_NAME='aaa/bbb'】，默认来自env.sh。注：镜像完整名称："\${DOCKER_REPO_SERVER}/\${DOCKER_IMAGE_PRE_NAME}/\${DOCKER_IMAGE_NAME}:\${DOCKER_IMAGE_TAG}"
        # 更多示例请参考【build.sh】
    "
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



# 参数检查
# 检查参数是否符合要求，会对参数进行重新排序，列出的参数会放在其他参数的前面，这样你在输入脚本参数时，不需要关注脚本参数的输入顺序，例如：'$0 aa bb -w wwww ccc'
# 但除了参数列表中指定的参数之外，脚本参数中不能出现以'-'开头的其他参数，例如按照下面的参数要求，这个命令是不能正常运行的：'$0 -w wwww  aaa --- bbb ccc'
# 如果想要在命令中正确运行上面以'-'开头的其他参数，你可以在'-'参数前加一个'--'参数，这个可以正确运行：'$0 -w wwww  aaa -- --- bbb ccc'
# 你可以通过'bash -x'方式运行脚本观察'--'的运行规律
#
TEMP=`getopt -o hln:c:b:I:e:sf  -l help,list,number:,category:,branch:,image-pre-name:,email:,skiptest,force -- "$@"`
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
        -I|--image-pre-name)
            IMAGE_PRE_NAME=$2
            IMAGE_PRE_NAME_ARG="--image-pre-name ${IMAGE_PRE_NAME}"
            shift 2
            ;;
        -e|--email)
            MY_USER_EMAIL=$2
            shift 2
            export MY_USER_EMAIL
            EMAIL_REGULAR='^[a-zA-Z0-9]+[a-zA-Z0-9_\.]*@([a-zA-Z0-9]+[a-zA-Z0-9\-]*[a-zA-Z0-9]\.)*[a-z]+$'
            if [[ ! "${MY_USER_EMAIL}" =~ ${EMAIL_REGULAR} ]]; then
                echo -e "\n猪猪侠警告：【${MY_USER_EMAIL}】邮件地址不合法\n"
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



# 默认ENV
GIT_BRANCH=${GIT_BRANCH:-"${GIT_DEFAULT_BRANCH}"}


# 建立base目录
[ -d "${LOG_HOME}" ] || mkdir -p  ${LOG_HOME}



# 运行环境匹配for Hook
if [[ -n ${HOOK_GAN_ENV} ]] && [[ ${HOOK_GAN_ENV} != 'NOT_CHECK' ]] && [[ ${HOOK_GAN_ENV} != ${RUN_ENV} ]]; then
    echo -e "\n猪猪侠警告：运行环境不匹配，跳过（这是正常情况）\n"
    exit
fi



# 获取用户信息
F_get_user_info
r=$?
if [[ $r != 0 ]]; then
    exit $r
fi


# 检查用户权限
F_check_user_priv
r=$?
if [[ $r != 0 ]]; then
    exit $r
fi



# 待搜索的项目清单
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
                PJ_NAME=`echo $LINE | awk -F '|' '{print $3}'`
                PJ_NAME=`echo ${PJ_NAME}`
                if [[ ${PJ_NAME} =~ ^$i$ ]]; then
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
            echo -e "\n${ECHO_ERROR}猪猪侠警告：【${LOLLIPOP_PLATFORM_NAME}】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目，请检查！${ECHO_CLOSE}\n"
            ${DINGDING_SEND_DEPLOY_SH}  "【Info:${LOLLIPOP_PLATFORM_NAME}:${RUN_ENV}】" "猪猪侠警告：【${LOLLIPOP_PLATFORM_NAME}】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目，请检查！" > /dev/null
            exit 51
        fi
    else
        # 仅构建指定类别指定项目
        for i in $@; do
            # 查找
            F_FIND_PROJECT ${THIS_LANGUAGE_CATEGORY} $i >> ${PARA_PROJECT_LIST_FILE_TMP}
            if [[ $? -ne 0 ]]; then
                echo -e "\n${ECHO_ERROR}猪猪侠警告：【${LOLLIPOP_PLATFORM_NAME}】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目【$i】，请检查！${ECHO_CLOSE}\n"
                ${DINGDING_SEND_DEPLOY_SH}  "【Info:${LOLLIPOP_PLATFORM_NAME}:${RUN_ENV}】" "猪猪侠警告：【${LOLLIPOP_PLATFORM_NAME}】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目【$i】，请检查！" > /dev/null
                exit 51
            fi
        done
    fi
fi
# 删除无关行
#sed  -i  -E  -e '/^\s*$/d'  -e '/^#.*$/d'  -e 's/[ \t]*//g'  ${PARA_PROJECT_LIST_FILE_TMP}
sed  -i  -E  -e '/^\s*$/d'  -e '/^#.*$/d'  ${PARA_PROJECT_LIST_FILE_TMP}
# 优先级排序
> ${PARA_PROJECT_LIST_FILE_TMP}.sort
for i in  `awk -F '|' '{split($8,a," ");print NR,a[1]}' ${PARA_PROJECT_LIST_FILE_TMP}  |  sort -n -k 2 |  awk '{print $1}'`
do
    awk "NR=="$i'{print}' ${PARA_PROJECT_LIST_FILE_TMP}  >> ${PARA_PROJECT_LIST_FILE_TMP}.sort
done
cp  ${PARA_PROJECT_LIST_FILE_TMP}.sort  ${PARA_PROJECT_LIST_FILE_TMP}
# 加表头
sed -i  '1i#| **类别** | **项目名** | **GIT命令空间** | **构建方法** | **输出方法** | **GOGOGO发布方式** | **优先级** | **备注** |'  ${PARA_PROJECT_LIST_FILE_TMP}
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
TOTAL_PARA_PJS=$(cat ${PARA_PROJECT_LIST_FILE_TMP} | grep '^|' | wc -l)
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
    BUILD_CHECK_COUNT=`expr ${BUILD_CHECK_COUNT} + 1`
    echo -e "${ECHO_BLACK_GREEN}++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++${ECHO_CLOSE}"   #--- 70 (80-70-60)
    echo -e "${ECHO_NORMAL}${BUILD_CHECK_COUNT}/${TOTAL_PARA_PJS} - ${PJ} :${ECHO_CLOSE}"
    echo ""
    # build
    export PROJECT_LIST_FILE_TMP="${BASE_PROJECT_LIST_FILE_TMP}.${PJ}"
    export BUILD_OK_LIST_FILE="${BASE_BUILD_OK_LIST_FILE}.${PJ}"
    export BUILD_OK_LIST_FILE_function="${BASE_BUILD_OK_LIST_FILE_function}.${PJ}"
    > ${BUILD_OK_LIST_FILE_function}
    #
    read -u 6       # 获取令牌。从命名管道fd6中读取一行，模拟领取一个令牌。由于FIFO特殊的读写机制，若没有空余的行可以读取，则进程会等待直至有可以读取的空余行
    {
        ${BUILD_SH}  --mode function  --category ${LANGUAGE_CATEGORY}  --branch="${GIT_BRANCH}"  ${IMAGE_PRE_NAME_ARG}  ${BUILD_SKIP_TEST_OPT}  ${BUILD_FORCE_OPT}  ${PJ}  > /dev/null 2>&1
        if [[ `cat ${BUILD_OK_LIST_FILE_function} | wc -l` -eq 1 ]]; then
            cat  ${BUILD_OK_LIST_FILE_function} >> ${PARA_BUILD_OK_LIST_FILE}
        else
            echo  "${PJ} : 失败，非预期错误" >> ${PARA_BUILD_OK_LIST_FILE}
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
#
# build.sh
# 54  "失败，Git Clone 出错"
# 54  "失败，Git Checkout 出错"
# 54  "失败，Git Pull 出错"
# 55  "跳过，Git 分支无更新"
# 53  "失败，其他用户正在构建中"
# 54(52)  "失败"
# 50  "成功"
# 56  "跳过，无需构建"
#
# build-parallel.sh
# 0   "失败，非预期错误"
#
BUILD_SUCCESS_COUNT=`cat ${PARA_BUILD_OK_LIST_FILE} | grep -o '成功' | wc -l`
BUILD_ERROR_COUNT=`cat ${PARA_BUILD_OK_LIST_FILE} | grep -o '失败' | wc -l`
BUILD_NOCHANGE_COUNT=`cat ${PARA_BUILD_OK_LIST_FILE} | grep -o '跳过，Git 分支无更新' | wc -l`
BUILD_NOTNEED_COUNT=`cat ${BUILD_OK_LIST_FILE} | grep -o '跳过，无需构建' | wc -l`
let NOT_BUILD_COUNT=${TOTAL_PARA_PJS}-${BUILD_CHECK_COUNT}
#
TIME_END=`date +%Y-%m-%dT%H:%M:%S`
MESSAGE_END="项目构建已完成！ 共企图构建${TOTAL_PARA_PJS}个项目，成功构建${BUILD_SUCCESS_COUNT}个项目，${BUILD_NOCHANGE_COUNT}个项目无更新，${BUILD_NOTNEED_COUNT}个项目无需构建，${BUILD_ERROR_COUNT}个项目出错，${NOT_BUILD_COUNT}各项目因其他原因退出构建。"
# 消息回显拼接
>  ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "干：**${GAN_WHAT_FUCK}**" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "====== 并行构建报告 ======" >> ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo -e "${ECHO_REPORT}################################# 并行构建报告 #################################${ECHO_CLOSE}"    #--- 80 (80-70-60)
#
echo "所在环境：${RUN_ENV}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "造 浪 者：${MY_USER_XINGMING}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "造浪账号：${MY_USER_NAME}@${USER_INFO_FROM}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "发送邮箱：${MY_USER_EMAIL}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "开始时间：${TIME}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "结束时间：${TIME_END}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "代码分支：${GIT_BRANCH}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "镜像TAG ：${DOCKER_IMAGE_TAG}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
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
echo "日志Web地址：${LOG_DOWNLOAD_SERVER}/file/${DATE_TIME}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
echo "日志Local地址：${LOG_HOME}" | tee -a ${PARA_BUILD_HISTORY_CURRENT_FILE}
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
${DINGDING_SEND_DEPLOY_SH}  "【Info:${LOLLIPOP_PLATFORM_NAME}:${RUN_ENV}】" "${MSG[@]}" > /dev/null



