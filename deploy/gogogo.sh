#/bin/bash
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
. ${SH_PATH}/env.sh
GAN_PLATFORM_NAME="${GAN_PLATFORM_NAME:-'超甜B&D系统'}"
BUILD_LOG_WEBSITE_DOMAIN_A=${BUILD_LOG_WEBSITE_DOMAIN_A:-"build-log"}         #--- 这个需要与【nginx.list】中【项目名】为【build-log】的【域名A记录】保持一致
DINGDING_API=${DINGDING_API:-"请定义"}
BUILD_SKIP_TEST=${BUILD_SKIP_TEST:-'NO'}  #--- 跳过测试（YES|NO）
#USER_DB_FILE=
#GIT_DEFAULT_BRANCH=

# 本地env
GAN_WHAT_FUCK='Gogogo'
export TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
DATE_TIME=`date -d "${TIME}" +%Y%m%dT%H%M%S`
#
RELEASE_VERSION=''
# 灰度
GRAY_TAG="normal"
#
LOG_BASE="${SH_PATH}/tmp/log"
LOG_HOME="${LOG_BASE}/${DATE_TIME}"
#
DOCKER_IMAGE_TAG=$(date -d "${TIME}" +%Y.%m.%d.%H%M%S)
# 子脚本参数
export BUILD_OK_LIST_FILE_function="${LOG_HOME}/${SH_NAME}-export-build-OK.list.function"
export DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE_function="${LOG_HOME}/${SH_NAME}-export-docker_deploy-OK.list.function"
export WEB_RELEASE_OK_LIST_FILE_function="${LOG_HOME}/${SH_NAME}-export-web_release-OK.list.function"
export MY_USER_NAME=''
export MY_EMAIL=''
export HOOK_GAN_ENV=${HOOK_GAN_ENV:-''}
export HOOK_USER=${HOOK_USER:-''}
# 独有
BUILD_QUIET='YES'
BUILD_FORCE='NO'
GOGOGO_PROJECT_LIST_FILE="${SH_PATH}/project.list"
GOGOGO_PROJECT_LIST_FILE_TMP="${LOG_HOME}/${SH_NAME}-project.list.tmp"
GOGOGO_PROJECT_LIST_FILE_APPEND_1="${SH_PATH}/project.list.append.1"
GOGOGO_SERVICE_LIST_FILE="${SH_PATH}/docker-cluster-service.list"
GOGOGO_SERVICE_LIST_FILE_APPEND_1="${SH_PATH}/docker-cluster-service.list.append.1"
GOGOGO_SERVICE_LIST_FILE_APPEND_2="${SH_PATH}/docker-cluster-service.list.append.2"
GOGOGO_RELEASE_WEB_OK_LIST_FILE="${LOG_HOME}/${SH_NAME}-web_release-OK.list"
GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE="${LOG_HOME}/${SH_NAME}-build_and_release-OK.list"
GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE="${LOG_HOME}/${SH_NAME}.history.current"
GOGOGO_PROJECT_BUILD_RESULT="${LOG_HOME}/${SH_NAME}-build.result"
GOGOGO_PROJECT_BUILD_DURATION_FILE="${SH_PATH}/db/${SH_NAME}-build_duration.last.db"      #--- db目录下的文件不建议删除
# 公共
FUCK_HISTORY_FILE="${SH_PATH}/db/fuck.history"
# LOG_DOWNLOAD_SERVER
if [ "x${RUN_ENV}" = "xprod" ]; then
    LOG_DOWNLOAD_SERVER="https://${BUILD_LOG_WEBSITE_DOMAIN_A}.${DOMAIN}"
else
    LOG_DOWNLOAD_SERVER="https://${RUN_ENV}-${BUILD_LOG_WEBSITE_DOMAIN_A}.${DOMAIN}"
fi

BUILD_SH="${SH_PATH}/build.sh"
DOCKER_CLUSTER_SERVICE_DEPLOY_SH="${SH_PATH}/docker-cluster-service-deploy.sh"
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
#sed -i '/^\s*$/d'  ${GOGOGO_PROJECT_LIST_FILE}
## 删除行中的空格,markdown文件不要这样
#sed -i 's/[ \t]*//g'  ${GOGOGO_PROJECT_LIST_FILE}



# 用法：
F_HELP()
{
    echo "
    用途：用于项目构建并发布
    依赖脚本：
        /etc/profile.d/run-env.sh
        ${SH_PATH}/env.sh
        ${GOGOGO_PROJECT_LIST_FILE}
        ${GOGOGO_PROJECT_LIST_FILE_APPEND_1}
        ${BUILD_SH}
        ${GOGOGO_SERVICE_LIST_FILE}
        ${GOGOGO_SERVICE_LIST_FILE_APPEND_1}
        ${GOGOGO_SERVICE_LIST_FILE_APPEND_2}
        ${DOCKER_CLUSTER_SERVICE_DEPLOY_SH}
        ${FORMAT_TABLE_SH}
        ${DINGDING_MARKDOWN_PY}
    注意：
        - 构建完成后的发布：如果目标服务不在运行中，则执行【create】；如果已经存在，则执行【update】。如果是以【create】方式执行，则【-G|--gray】参数有效
    用法:
        $0  [-h|--help]
        $0  [-l|--list]
        $0  <-c [dockerfile|java|node|自定义]>  <-b|--branch {代码分支}>  <-I|--image-pre-name {镜像前置名称}>  <-e|--email {邮件地址}>  <-s|--skiptest>  <-f|--force>  <-v|--verbose>  <-V|--release-version>  <-G|--gray>  <{项目1}  {项目2} ... {项目n}> ... {项目名称正则匹配}>
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
        -c|--category  指定构建项目语言类别：【dockerfile|java|node|自定义】，参考：${GOGOGO_PROJECT_LIST_FILE}
        -b|--branch    指定代码分支，默认来自env.sh
        -I|--image-pre-name  指定镜像前置名称【DOCKER_IMAGE_PRE_NAME】，默认来自env.sh。注：镜像完整名称：\${DOCKER_REPO_SERVER}/\${DOCKER_IMAGE_PRE_NAME}/\${DOCKER_IMAGE_NAME}:\${DOCKER_IMAGE_TAG}
        -e|--email     发送日志到指定邮件地址，如果与【-U|--user-name】同时存在，则将会被替代
        -s|--skiptest  跳过测试，默认来自env.sh
        -f|--force     强制重新构建（无论是否有更新）
        -v|--verbose   显示更多过程信息
        -G|--gray            : 设置灰度标志为：【gray】，默认：【normal】
        -V|--release-version : 发布版本号
    示例:
        #
        $0  -l             #--- 列出可构建发布的项目清单
        # 类别
        $0  -c java                           #--- 构建发布所有java项目，用默认分支
        $0  -c java  -b 分支a                 #--- 构建发布所有java项目，用分支a
        $0  -c java  -b 分支a  项目1  项目2   #--- 构建发布java【项目1、项目2】，用分支a（一般可不用-c参数）
        $0  -c java            项目1  项目2   #--- 构建发布java【项目1、项目2】，用默认分支
        # 一般
        $0                           #--- 构建发布所有项目，用默认分支
        $0  -b 分支a                 #--- 构建发布所有项目，用【分支a】
        $0  -b 分支a  项目1  项目2   #--- 构建发布【项目1、项目2】，用【分支a】
        $0            项目1  项目2   #--- 构建发布【项目1、项目2】，用默认分支
        # 镜像前置名称
        $0  -I aaa/bbb  项目1  项目2            #--- 构建发布【项目1、项目2】，生成的镜像前置名称为【DOCKER_IMAGE_PRE_NAME='aaa/bbb'】，默认来自env.sh。注：镜像完整名称："\${DOCKER_REPO_SERVER}/\${DOCKER_IMAGE_PRE_NAME}/\${DOCKER_IMAGE_NAME}:\${DOCKER_IMAGE_TAG}"
        $0  --email xm@xxx.com  项目1 项目2     #--- 构建发布【项目1、项目2】，将错误日志发送到邮箱【xm@xxx.com】
        # 邮件
        $0  --email xm@xxx.com  项目1 项目2     #--- 构建发布【项目1、项目2】，将错误日志发送到邮箱【xm@xxx.com】
        # 跳过测试
        $0  -s  项目1 项目2                     #--- 构建发布【项目1、项目2】，跳过测试
        # 强制重新构建
        $0  -f  项目1  项目2                    #--- 强制重新构建发布【项目1、项目2】，用默认分支，不管【项目1、项目2】有没有更新
        # 显示更多信息
        $0  -v  项目1 项目2                     #--- 构建发布【项目1、项目2】，显示更多信息
        # 构建发布带版本号
        $0  -V 2.2  项目1 项目2                 #--- 构建【项目1、项目2】，发布版本号为【2.2】
        # 构建完成后以灰度方式发布
        $0  -G          项目1 项目2             #--- 构建【项目1、项目2】，并灰度发布
        $0  -G  -V 2.2  项目1 项目2             #--- 构建【项目1、项目2】，并灰度发布，发布版本号为【2.2】
        # 项目名称用正则匹配
        $0   .*xxx.*       #--- 构建发布项目名称正则匹配【.*xxx.*】的项目（包含xxx的），用默认分支
        $0   [.]*xxx       #--- 构建发布项目名称正则匹配【[.]*xxx】的项目（包含xxx的），用默认分支
        $0   xxx-          #--- 构建发布项目名称正则匹配【xxx-】的项目（包含xxx-的），用默认分支
        $0   ^[xy]         #--- 构建发布项目名称正则匹配【^[xy]】的项目（以x或y开头的），用默认分支
        $0   ^sss          #--- 构建发布项目名称正则匹配【^sss】的目（以sss开头的），用默认分支
        $0   eee$          #--- 构建发布项目名称正则匹配【eee$】的目（以eee结尾的），用默认分支
        $0   ^sss.*eee$    #--- 构建发布项目名称正则匹配【^sss.*eee$】的项目（以以sss开头，并且以eee结尾的），用默认分支
        $0  -c ja  ^sss.*eee$    #--- 构建发布项目类别正则匹配【ja】，且项目名称正则匹配【^sss.*eee$】的项目（以以sss开头，并且以eee结尾的），用默认分支
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



# 查找项目类别与项目名称，返回错误代码及匹配项目
# 用法：F_FIND_PROJECT  [F_THIS_LANGUAGE_CATEGORY]  <F_THIS_PROJECT>
F_FIND_PROJECT ()
{
    F_THIS_LANGUAGE_CATEGORY=$1
    F_THIS_PROJECT=$2
    F_GET_IT=""
    #
    if [[ -z "${F_THIS_PROJECT}" ]]; then
        # 匹配类别
        while read LINE; do
            F_C=`echo ${LINE} | awk -F '|' '{print $2}'`
            F_C=`echo ${F_C}`
            if [[ ${F_C} =~ ${F_THIS_LANGUAGE_CATEGORY} ]]; then
                echo "${LINE}"
                F_GET_IT="YES"
            fi
        done < ${GOGOGO_PROJECT_LIST_FILE}
        #
    else
        # 匹配类别与项目名称
        while read LINE; do
            F_C=`echo ${LINE} | awk -F '|' '{print $2}'`
            F_C=`echo ${F_C}`
            F_P=`echo ${LINE} | awk -F '|' '{print $3}'`
            F_P=`echo ${F_P}`
            if [[ ${F_C} =~ ${F_THIS_LANGUAGE_CATEGORY} ]]  &&  [[ ${F_P} =~ ${F_THIS_PROJECT} ]]; then
                echo "${LINE}"
                # 仅匹配一次
                #F_GET_IT="Y"
                #break
                # 匹配多次次
                F_GET_IT='YES'
            fi
        done < ${GOGOGO_PROJECT_LIST_FILE}
    fi
    # 函数返回
    if [[ ${F_GET_IT} != 'YES' ]]; then
        return 1
    else
        return 0
    fi
}



# 查找镜像名称对应的服务名称，结果存入SERVICE_NAME_S，并追加到临时文件
# 调用之前一般需要设置: SERVICE_NAME_S=""
# 用法：F_FIND_IMAGE_OUTPUT_SERVICENAME  [F_THIS_DOCKER_IMAGE_NAME]
F_FIND_IMAGE_OUTPUT_SERVICENAME ()
{
    F_THIS_DOCKER_IMAGE_NAME=$1
    F_SERVICE_NAME_S=''
    > "${LOG_HOME}/F_FIND_IMAGE_OUTPUT_SERVICENAME-search.txt"
    GOGOGO_SERVICE_LIST_FILE_FIND_TMP="${LOG_HOME}/${SH_NAME}-${GOGOGO_SERVICE_LIST_FILE##*/}--find-${F_THIS_DOCKER_IMAGE_NAME}"
    cat ${GOGOGO_SERVICE_LIST_FILE} | grep "${F_THIS_DOCKER_IMAGE_NAME}"  >  ${GOGOGO_SERVICE_LIST_FILE_FIND_TMP}
    while read LINE_F
    do
        # 跳过以#开头的行及空行
        [[ "$LINE_F" =~ ^# ]] || [[ "$LINE_F" =~ ^[\ ]*$ ]] && continue
        #
        F_SERVICE_NAME=`echo ${LINE_F} | cut -d \| -f 2`
        F_SERVICE_NAME=`echo ${F_SERVICE_NAME}`
        F_DOCKER_IMAGE_NAME=`echo ${LINE_F} | cut -d \| -f 4`
        F_DOCKER_IMAGE_NAME=`eval echo ${F_DOCKER_IMAGE_NAME}`    #--- 用eval将配置文件中项的变量转成值，下同
        if [[ ${F_DOCKER_IMAGE_NAME} == ${F_THIS_DOCKER_IMAGE_NAME} ]]; then
            F_SERVICE_NAME_S="${F_SERVICE_NAME_S} ${F_SERVICE_NAME}"
        fi
    done < ${GOGOGO_SERVICE_LIST_FILE_FIND_TMP}
    # 结果
    if [[ -z "${F_SERVICE_NAME_S}" ]]; then
        # 结果为空
        return 5
    else
        echo  ${F_SERVICE_NAME_S} > "${LOG_HOME}/F_FIND_IMAGE_OUTPUT_SERVICENAME-search.txt"
        SERVICE_NAME_S=${F_SERVICE_NAME_S}
        return 0
    fi
}



# F_BUILD_TIME_UPDATE  [项目名]  [用时(s)]
F_BUILD_TIME_UPDATE()
{
    F_PJ=$1
    F_TIME=$2
    #
    if [ ! -f "${GOGOGO_PROJECT_BUILD_DURATION_FILE}" ]; then
        touch "${GOGOGO_PROJECT_BUILD_DURATION_FILE}"
    fi
    #
    if [ ${F_TIME} -ge 10 ]; then
        grep  -q "${F_PJ}"  "${GOGOGO_PROJECT_BUILD_DURATION_FILE}"  \
            && sed -i "s/^${F_PJ}.*$/${F_PJ}  ${F_TIME}/"  "${GOGOGO_PROJECT_BUILD_DURATION_FILE}"  \
            || echo "${F_PJ}  ${F_TIME}"  >> "${GOGOGO_PROJECT_BUILD_DURATION_FILE}"
        return 0
    else
        #echo 'Build用时小于10秒，不更新！'
        return 5
    fi
}


# 项目构建历史用时
# F_BUILD_TIME_SEARCH  [项目名]
F_BUILD_TIME_SEARCH()
{
    if [ ! -f "${GOGOGO_PROJECT_BUILD_DURATION_FILE}" ]; then
        echo 0
        return 5
    fi
    F_PJ=$1
    grep  -q "${F_PJ}"  "${GOGOGO_PROJECT_BUILD_DURATION_FILE}"
    if [ $? -eq 0 ]; then
        F_TIME=`cat "${GOGOGO_PROJECT_BUILD_DURATION_FILE}" | grep "${F_PJ}" | head -n 1 | awk '{printf $2}'`
        echo ${F_TIME}
        return 0
    else
        echo 0
        return 5
    fi
}



# 用户搜索
# F_USER_SEARCH  [用户名|姓名]
F_USER_SEARCH()
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
            echo "${CURRENT_USER_XINGMING} ${CURRENT_USER_EMAIL}"
            return 0
        fi
    done < "${USER_DB_FILE}"
    return 3
}



# 精确查找已部署的service，返回是否找到及清单
# 用法：F_ONLINE_SERVICE_SEARCH  [服务名]  [集群类型]
F_ONLINE_SERVICE_SEARCH()
{
    F_SEARCH_NAME=$1
    F_CLUSTER=$2
    case "${F_CLUSTER}" in 
        swarm)
            GET_IT=''
            #docker service ls  --format "{{.Name}}"  --filter name=${F_SEARCH_NAME} | while read S_LINE
            for S_LINE in $(docker service ls  --format "{{.Name}}")
            do
                if [[ ${S_LINE} =~ ^${F_SEARCH_NAME}$ ]]; then
                    echo  ${S_LINE}
                    GET_IT='YES'
                fi
            done
            #
            if [[ ${GET_IT} == 'YES' ]]; then
                # 找到
                return 0
            else
                return 3
            fi
            ;;
        k8s)
            # 待办：
            kubectl get deployments ${F_SEARCH_NAME}
            if [ $? = 0 ]; then
                # 找到
                return 0
            else
                return 3
            fi
            ;;
        compose)
            GET_IT=''
            #docker ps -a  --format "{{.Names}}"  --filter name=${F_SEARCH_NAME} | while read S_LINE
            for S_LINE in $(docker ps -a  --format "{{.Names}}")
            do
                if [[ ${S_LINE} =~ ^${F_SEARCH_NAME} ]]; then
                    echo  ${S_LINE}
                    GET_IT='YES'
                fi
            done
            #
            if [[ ${GET_IT} == 'YES' ]]; then
                # 找到
                return 0
            else
                return 3
            fi
            ;;
        *)
            echo -e "\n猪猪侠警告：未定义集群类型！\n"
            return 52
            ;;
    esac
}



# 根据【DEPLOY_PLACEMENT】设置运行环境
# 用法：
F_SET_RUN_ENV()
{
    case ${CLUSTER} in
        swarm)
            if [[ ! -z ${DEPLOY_PLACEMENT} ]]; then
                DEPLOY_PLACEMENT=${DEPLOY_PLACEMENT// /}               #--- 删除字符串中所有的空格
                DEPLOY_PLACEMENT_ARG_NUM=$(echo ${DEPLOY_PLACEMENT} | grep -o , | wc -l)
                DEPLOY_PLACEMENT_LABELS=''
                for ((i=DEPLOY_PLACEMENT_ARG_NUM; i>=0; i--))
                do
                    if [ "x${DEPLOY_PLACEMENT}" = 'x' ]; then
                        break
                    fi
                    FIELD=$((i+1))
                    DEPLOY_PLACEMENT_SET=`echo ${DEPLOY_PLACEMENT} | cut -d , -f ${FIELD}`
                    # 
                    if [[ ${DEPLOY_PLACEMENT_SET} =~ ^NET ]]; then
                        NETWORK_SWARM=$(echo ${DEPLOY_PLACEMENT_SET} | awk -F ':' '{print $2}')
                    elif [[ ${DEPLOY_PLACEMENT_SET} =~ ^L ]]; then
                        DEPLOY_PLACEMENT_LABELS="$(echo ${DEPLOY_PLACEMENT_SET} | awk -F ':' '{print $2}') ${DEPLOY_PLACEMENT_LABELS}"
                    else
                        echo -e "\n猪猪侠警告：配置文件错误，请检查【DEPLOY_PLACEMENT】\n"
                        return 52
                    fi
                done
            fi
            #
            export DOCKER_HOST=${SWARM_DOCKER_HOST}     #--- 用完需要置空
            ;;
        k8s)
            if [[ ! -z ${DEPLOY_PLACEMENT} ]]; then
                DEPLOY_PLACEMENT=${DEPLOY_PLACEMENT// /}               #--- 删除字符串中所有的空格
                DEPLOY_PLACEMENT_ARG_NUM=$(echo ${DEPLOY_PLACEMENT} | grep -o , | wc -l)
                DEPLOY_PLACEMENT_LABELS=''
                for ((i=DEPLOY_PLACEMENT_ARG_NUM; i>=0; i--))
                do
                    if [ "x${DEPLOY_PLACEMENT}" = 'x' ]; then
                        break
                    fi
                    FIELD=$((i+1))
                    DEPLOY_PLACEMENT_SET=`echo ${DEPLOY_PLACEMENT} | cut -d , -f ${FIELD}`
                    # 假设只有一个Label
                    if [[ ${DEPLOY_PLACEMENT_SET} =~ ^NS ]]; then
                        K8S_NAMESAPCE=$(echo ${DEPLOY_PLACEMENT_SET} | awk -F ':' '{print $2}')
                    elif [[ ${DEPLOY_PLACEMENT_SET} =~ ^L ]]; then
                        DEPLOY_PLACEMENT_LABELS="$(echo ${DEPLOY_PLACEMENT_SET} | awk -F ':' '{print $2}') ${DEPLOY_PLACEMENT_LABELS}"
                    else
                        echo -e "\n猪猪侠警告：配置文件错误，请检查【DEPLOY_PLACEMENT】\n"
                        return 52
                    fi
                done
            fi
            #
            K8S_NAMESAPCE=${K8S_NAMESAPCE:-'default'}
            ;;
        compose)
            if [[ ! -z ${DEPLOY_PLACEMENT} ]]; then
                if [[ ${DEPLOY_PLACEMENT} =~ ^SSH ]]; then
                    # awk会自动去掉【""】引号
                    COMPOSE_SSH_HOST_OR_WITH_USER=$(echo ${DEPLOY_PLACEMENT} | awk '{print $1}' | awk -F ':' '{print $2}')
                    COMPOSE_SSH_PORT=$(echo ${DEPLOY_PLACEMENT} | awk '{print $3}')
                    if [[ -z ${COMPOSE_SSH_PORT} ]]; then
                        COMPOSE_SSH_PORT=22
                    fi
                else
                    echo -e "\n猪猪侠警告：配置文件错误，请检查【DEPLOY_PLACEMENT】\n"
                    return 52
                fi
                COMPOSE_DOCKER_HOST="ssh://${COMPOSE_SSH_HOST_OR_WITH_USER}:${COMPOSE_SSH_PORT}"
            else
                echo -e "\n猪猪侠警告：配置文件错误，请检查【DEPLOY_PLACEMENT】，【CLUSTER=compose】时，此项不能为空\n"
                return 52
            fi
            #
            export DOCKER_HOST=${COMPOSE_DOCKER_HOST}     #--- 用完需要置空
            # test
            if [[ $(docker image ls >/dev/null 2>&1; echo $?) != 0 ]]; then
                echo -e "\n猪猪侠警告：连接测试异常，请检查【DEPLOY_PLACEMENT】或目标主机，Docker daemon无法正常连接\n"
                return 52
            fi
            DOCKER_COMPOSE_SERVICE_HOME=${DOCKER_COMPOSE_BASE}/${SERVICE_NAME}
            ;;
        *)
            echo -e "\n猪猪侠警告：未定义的集群类型\n"
            return 52
            ;;
    esac
}



# docker cluster service 部署
# 用法： F_DOCKER_CLUSTER_SERVICE_DEPLOY  [镜像名]
F_DOCKER_CLUSTER_SERVICE_DEPLOY()
{
    F_DOCKER_IMAGE_NAME=$1
    F_SERVICE_NAME_S=""  &&  F_FIND_IMAGE_OUTPUT_SERVICENAME ${F_DOCKER_IMAGE_NAME}
    A_RETURN=$?
    if [[ ${A_RETURN} == 0 ]]; then
        # 查询服务是否运行中
        #F_DEPLOY_RETURN_CURRENT=0
        F_DEPLOY_RETURN=0
        F_SERVICE_NUM=0
        unset F_SERVICE_NAME
        for F_SERVICE_NAME in ${F_SERVICE_NAME_S}; do
            #
            # 获取${CLUSTER}并设置运行环境
            while read LINE
            do
                # 跳过以#开头的行或空行
                [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
                #
                SERVICE_NAME=`echo $LINE | awk -F '|' '{print $2}'`
                SERVICE_NAME=`echo ${SERVICE_NAME}`
                #
                if [[ ${SERVICE_NAME} == ${F_SERVICE_NAME} ]]; then
                    #
                    # append.1
                    GOGOGO_SERVICE_LIST_FILE_APPEND_1_TMP="${LOG_HOME}/${SH_NAME}-${GOGOGO_SERVICE_LIST_FILE_APPEND_1##*/}---${SERVICE_NAME}"
                    cat ${GOGOGO_SERVICE_LIST_FILE_APPEND_1} | grep "${SERVICE_NAME}"  >  ${GOGOGO_SERVICE_LIST_FILE_APPEND_1_TMP}
                    GET_IT_A='NO'
                    while read LINE_A
                    do
                        # 跳过以#开头的行或空行
                        [[ "$LINE_A" =~ ^# ]] || [[ "$LINE_A" =~ ^[\ ]*$ ]] && continue
                        #
                        SERVICE_NAME_A=`echo ${LINE_A} | cut -d \| -f 2`
                        SERVICE_NAME_A=`echo ${SERVICE_NAME_A}`
                        if [[ ${SERVICE_NAME_A} == ${SERVICE_NAME} ]]; then
                            #
                            GET_IT_A='YES'
                            #
                            CLUSTER=`echo ${LINE_A} | cut -d \| -f 3`
                            CLUSTER=`eval echo ${CLUSTER}`
                            #
                            DEPLOY_PLACEMENT=`echo ${LINE_A} | cut -d \| -f 5`
                            DEPLOY_PLACEMENT=`eval echo ${DEPLOY_PLACEMENT}`
                        fi
                        #
                        if [[ ${GET_IT_A} != 'YES' ]];then
                            echo -e "\n猪猪侠警告：在【${GOGOGO_SERVICE_LIST_FILE_APPEND_1}】文件中没有找到服务名【${SERVICE_NAME}】，请检查！\n"
                            exit 51
                        fi
                    done < ${GOGOGO_SERVICE_LIST_FILE_APPEND_1_TMP}
                    #
                    F_SET_RUN_ENV
                    if [[ $? -ne 0 ]]; then
                        return 52
                    fi
                    break
                fi
            done < ${GOGOGO_SERVICE_LIST_FILE}
            #
            # 子函数的变量可以在父函数中直接使用
            #
            if [[ -n ${RELEASE_VERSION} ]]; then
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    F_SERVICE_X_NAME="${F_SERVICE_NAME}--V_${RELEASE_VERSION}-G"
                    DEPLOY_OPTION="--release-version ${RELEASE_VERSION}  --gray"
                elif [[ ${GRAY_TAG} == 'normal' ]]; then
                    F_SERVICE_X_NAME="${F_SERVICE_NAME}--V_${RELEASE_VERSION}"
                    DEPLOY_OPTION="--release-version ${RELEASE_VERSION}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    return 52
                fi
            else
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    F_SERVICE_X_NAME="${F_SERVICE_NAME}--G"
                    GRAY_OPTION="--gray"
                elif [[ ${GRAY_TAG} == 'normal' ]]; then
                    F_SERVICE_X_NAME="${F_SERVICE_NAME}"
                    GRAY_OPTION=""
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    return 52
                fi
            fi
            #
            F_ONLINE_SERVICE_SEARCH  ${F_SERVICE_X_NAME}  ${CLUSTER}
            if [ $? -eq 0 ]; then
                # 服务运行中
                ${DOCKER_CLUSTER_SERVICE_DEPLOY_SH}  ${IMAGE_PRE_NAME_ARG}  --mode function  --update  --fuck  ${F_SERVICE_NAME}  ${DEPLOY_OPTION}
                #F_DEPLOY_RETURN_CURRENT=$?
                #let  F_DEPLOY_RETURN=${F_DEPLOY_RETURN}+${F_DEPLOY_RETURN_CURRENT}-50
                F_DEPLOY_RETURN=$?
                let  F_SERVICE_NUM=${F_SERVICE_NUM}+1
            else
                # 服务不在运行中
                ${DOCKER_CLUSTER_SERVICE_DEPLOY_SH}  ${IMAGE_PRE_NAME_ARG}  --mode function  --create  --fuck  ${F_SERVICE_NAME}  ${DEPLOY_OPTION}
                #F_DEPLOY_RETURN_CURRENT=$?
                #let  F_DEPLOY_RETURN=${F_DEPLOY_RETURN}+${F_DEPLOY_RETURN_CURRENT}-50
                F_DEPLOY_RETURN=$?
                let  F_SERVICE_NUM=${F_SERVICE_NUM}+1
            fi
            #
            # 获取deploy结果
            #if [ ${F_DEPLOY_RETURN} -eq 0 ]; then
            #    F_DOCKER_CLUSTER_SERVICE_DEPLOY_RESULT='成功'
            #else
            #    F_DOCKER_CLUSTER_SERVICE_DEPLOY_RESULT='失败'
            #fi
            F_DOCKER_CLUSTER_SERVICE_DEPLOY_RESULT=$(awk  '{print $3}'  ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE_function})
            #
            # 一个image对应的service数量
            N=${F_SERVICE_NUM}
            if [[ $N -eq 1 ]]; then
                echo "${PJ} : 构建${BUILD_RESULT} : 发布${F_DOCKER_CLUSTER_SERVICE_DEPLOY_RESULT} : ${BUILD_TIME}s" >> ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE}
                echo "构建：${BUILD_RESULT} - 发布: ${F_DOCKER_CLUSTER_SERVICE_DEPLOY_RESULT} - 耗时 : ${BUILD_TIME}s"
            else
                # 【*N】代表成功发布的服务数量
                echo "${PJ} : 构建${BUILD_RESULT} : 发布${F_DOCKER_CLUSTER_SERVICE_DEPLOY_RESULT}*$N : ${BUILD_TIME}s" >> ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE}
                echo "构建：${BUILD_RESULT} - 发布: ${F_DOCKER_CLUSTER_SERVICE_DEPLOY_RESULT}*$N - 耗时 : ${BUILD_TIME}s"
            fi
        done
        #
        ## 把减掉的50加回去，但是其实如果一个镜像对应多个服务，这个值已经不代表指定含义了，目前这个返回值也没实际用途，只是标准化处理
        #let F_DEPLOY_RETURN=${F_DEPLOY_RETURN}+50
        # 如果有多个服务，只获取最后一个
        return ${F_DEPLOY_RETURN}
    elif [[ ${A_RETURN} -eq 5 ]]; then
        echo "${PJ} : 构建${BUILD_RESULT} : 发布跳过，无需发布* : ${BUILD_TIME}s" >> ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE}
        echo "构建：${BUILD_RESULT} - 发布: 跳过，无需发布* - 耗时 : ${BUILD_TIME}s"
        return 56
    else
        echo -e "\n猪猪侠警告：这是程序Bug【不可能】\n"
        return 59
    fi
    #export DOCKER_HOST=''     #--- 用完置空，已经在函数调用处处理了
}



# F_PYTHON_DEPLOY {项目名称}
# 重启python服务
F_PYTHON_DEPLOY()
{
    echo  没搞
}



# 参数检查
TEMP=`getopt -o hlc:b:I:e:sfvGV:  -l help,list,category:,branch:,image-pre-name:,email:,skiptest,force,verbose,gray,release-version: -- "$@"`
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
            #awk 'BEGIN {FS="|"} { if ($3 !~ /^ *$/) {sub(/^[[:blank:]]*/,"",$3); sub(/[[:blank:]]*$/,"",$3); printf "%2d %5s  %s\n",NR,$2,$3} }'  ${GOGOGO_PROJECT_LIST_FILE}
            sed  -E  -e '/^\s*$/d'  -e '/^##.*$/d'  -e '/---/d'  -e '/^#.*PRIORITY/d'  ${GOGOGO_PROJECT_LIST_FILE}  > /tmp/gogogo-project-for-list.txt
            ${FORMAT_TABLE_SH}  --delimeter '|'  --file /tmp/gogogo-project-for-list.txt
            exit
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
        -v|--verbose)
            BUILD_QUIET='NO'
            shift
            ;;
        -G|--gray)
            GRAY_TAG="gray"
            shift
            ;;
        -V|--release-version)
            RELEASE_VERSION=$2
            shift 2
            if [[ ! V_${RELEASE_VERSION} =~ ^V_[0-9a-z]+([_\.\-]?[0-9a-z]+)*$ ]]; then
                echo -e "\n猪猪侠警告：发布版本号只能使用字符【0-9a-z._-】，且特殊字符不能出现在版本号的头部或尾部\n"
                ERROR_CODE=51
                exit 51
            fi
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



# 运行环境匹配for Hook
if [[ -n ${HOOK_GAN_ENV} ]] && [[ ${HOOK_GAN_ENV} != ${RUN_ENV} ]]; then
    echo -e "\n猪猪侠警告：运行环境不匹配，跳过（这是正常情况）\n"
    exit
fi


# 默认ENV
GIT_BRANCH=${GIT_BRANCH:-"${GIT_DEFAULT_BRANCH}"}


# 建立项目base目录
[ -d "${LOG_HOME}" ] || mkdir -p  ${LOG_HOME}



# 用户信息
if [[ -n ${HOOK_USER} ]]; then
    MY_USER_NAME=${HOOK_USER}
else
    # if sudo -i 取${SUDO_USER}；
    # if sudo cmd 取${LOGNAME}
    MY_USER_NAME=${SUDO_USER:-"${LOGNAME}"}
fi
export MY_USER_NAME
#
F_USER_SEARCH ${MY_USER_NAME} > /dev/null
if [ $? -eq 0 ]; then
    R=`F_USER_SEARCH ${MY_USER_NAME}`
    export MY_EMAIL=${MY_EMAIL:-"`echo $R | cut -d ' ' -f 2`"}
    MY_XINGMING=`echo $R | cut -d ' ' -f 1`
else
    MY_XINGMING='X-Man'
fi



# 待搜索的项目清单
> ${GOGOGO_PROJECT_LIST_FILE_TMP}
## 类别
if [[ -z ${THIS_LANGUAGE_CATEGORY} ]]; then
    # 类别为空
    if [[ $# -eq 0 ]]; then
        # 未指定项目
        cp  ${GOGOGO_PROJECT_LIST_FILE}  ${GOGOGO_PROJECT_LIST_FILE_TMP}
    else
        # 指定项目
        unset i
        for i in $@
        do
            #
            GET_IT=''
            while read LINE
            do
                # 跳过以#开头的行或空行
                [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
                #
                PJ_NAME=`echo $LINE | awk -F '|' '{print $3}'`
                PJ_NAME=`echo ${PJ_NAME}`
                if [[ ${PJ_NAME} =~ $i ]]; then
                    echo $LINE >> ${GOGOGO_PROJECT_LIST_FILE_TMP}
                    # 仅匹配一次
                    #GET_IT='Y'
                    #break
                    # 匹配多次
                    GET_IT='YES'
                fi
            done < ${GOGOGO_PROJECT_LIST_FILE}
            #
            if [[ $GET_IT != 'YES' ]]; then
                echo -e "\n${ECHO_ERROR}猪猪侠警告：【${GAN_WHAT_FUCK}】时，项目【${i}】正则不匹配项目列表【${GOGOGO_PROJECT_LIST_FILE}】中任何项目，请检查！${ECHO_CLOSE}\n"
                ${DINGDING_MARKDOWN_PY}  "【Error:${GAN_PLATFORM_NAME}:${RUN_ENV}】" "猪猪侠警告：【${GAN_WHAT_FUCK}】时，项目【${i}】正则不匹配项目列表【${GOGOGO_PROJECT_LIST_FILE}】中任何项目，请检查！" > /dev/null
                exit 51
            fi
        done
    fi
else
    # 类别不为空
    if [[ "${THIS_LANGUAGE_CATEGORY}" == "all" ]]; then
        # 所有项目
        cp  ${GOGOGO_PROJECT_LIST_FILE}  ${GOGOGO_PROJECT_LIST_FILE_TMP}
        # 忽略
        if [[ $# -ne 0 ]]; then
            echo -e "\n猪猪侠警告：这些参数将会被忽略【$@】\n"
        fi
    elif [[ $# -eq 0 ]]; then
        # 指定类别所有项目
        # 查找
        F_FIND_PROJECT ${THIS_LANGUAGE_CATEGORY} >> ${GOGOGO_PROJECT_LIST_FILE_TMP}
        if [[ $? -ne 0 ]]; then
            echo -e "\n${ECHO_ERROR}猪猪侠警告：【${GAN_WHAT_FUCK}】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目，请检查！${ECHO_CLOSE}\n"
            ${DINGDING_MARKDOWN_PY}  "【Error:${GAN_PLATFORM_NAME}:${RUN_ENV}】" "猪猪侠警告：【${GAN_WHAT_FUCK}】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目，请检查！" > /dev/null
            exit 51
        fi
    else
        # 仅构建指定类别指定项目
        unset i
        for i in $@; do
            # 查找
            F_FIND_PROJECT ${THIS_LANGUAGE_CATEGORY} $i >> ${GOGOGO_PROJECT_LIST_FILE_TMP}
            if [[ $? -ne 0 ]]; then
                echo -e "\n${ECHO_ERROR}猪猪侠警告：【GAN_WHAT_FUCK】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】且正则匹配【$i】的项目，请检查！${ECHO_CLOSE}\n"
                ${DINGDING_MARKDOWN_PY}  "【Error:${GAN_PLATFORM_NAME}:${RUN_ENV}】" "猪猪侠警告：【GAN_WHAT_FUCK】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】且正则匹配【$i】的项目，请检查！" > /dev/null
                exit 51
            fi
        done
    fi
fi
# 删除无关行
#sed  -i  -E  -e '/^\s*$/d'  -e '/^#.*$/d'  -e 's/[ \t]*//g'  ${GOGOGO_PROJECT_LIST_FILE_TMP}
sed  -i  -E  -e '/^\s*$/d'  -e '/^#.*$/d'  ${GOGOGO_PROJECT_LIST_FILE_TMP}
# 优先级排序
> ${GOGOGO_PROJECT_LIST_FILE_TMP}.sort
for i in  `awk -F '|' '{split($8,a," ");print NR,a[1]}' ${GOGOGO_PROJECT_LIST_FILE_TMP}  |  sort -n -k 2 |  awk '{print $1}'`
do
    awk "NR=="$i'{print}' ${GOGOGO_PROJECT_LIST_FILE_TMP}  >> ${GOGOGO_PROJECT_LIST_FILE_TMP}.sort
done
cp  ${GOGOGO_PROJECT_LIST_FILE_TMP}.sort  ${GOGOGO_PROJECT_LIST_FILE_TMP}
# 加表头
sed -i  '1i#| **类别** | **项目名** | **GIT命令空间** | **构建方法** | **输出方法** | **GOGOGO发布方式** | **优先级** | **备注** |'  ${GOGOGO_PROJECT_LIST_FILE_TMP}
# 屏显
echo -e "${ECHO_NORMAL}################################ 开始构建与发布 ################################${ECHO_CLOSE}"  #--- 80 (80-70-60)
echo -e "\n【${SH_NAME}】待构建与发布项目清单："
${FORMAT_TABLE_SH}  --delimeter '|'  --file ${GOGOGO_PROJECT_LIST_FILE_TMP}
#echo -e "\n"



# 初始化命名管道
N_proc=1                 # 设定同时执行的进程数上限
P_fifo="/tmp/$$.fifo"    # 以PID作为文件名，避免重名
mkfifo $P_fifo           # 创建fifo命名管道, 以上面的文件名创建
exec 6<> $P_fifo         # 以读写方式打开命名管道，并设置文件标识符fd为6。 >为写入 <为读取 <>为读写
rm -f $P_fifo            # 删除FIFO文件，可有可无
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
RELEASE_CHECK_COUNT=0
RELEASE_SUCCESS_COUNT=0
RELEASE_ERROR_COUNT=0
RELEASE_NOTNEED_COUNT=0
RELEASE_SKIP_COUNT=0
> ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE}
while read LINE
do
    # 0 - head
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    LANGUAGE_CATEGORY=`echo ${LINE} | cut -d \| -f 2`
    LANGUAGE_CATEGORY=`echo ${LANGUAGE_CATEGORY}`
    #
    PJ=`echo ${LINE} | cut -d \| -f 3`
    PJ=`echo ${PJ}`
    #
    GOGOGO_RELEASE_METHOD=`echo ${LINE} | cut -d \| -f 7`
    GOGOGO_RELEASE_METHOD=`echo ${GOGOGO_RELEASE_METHOD}`
    #
    #
    # append.1
    GOGOGO_PROJECT_LIST_FILE_APPEND_1_TMP="${LOG_HOME}/${SH_NAME}-${GOGOGO_PROJECT_LIST_FILE_APPEND_1##*/}--${LANGUAGE_CATEGORY}-${PJ}"
    cat ${GOGOGO_PROJECT_LIST_FILE_APPEND_1} | grep "${PJ}"  >  ${GOGOGO_PROJECT_LIST_FILE_APPEND_1_TMP}
    GET_IT_A='NO'
    while read LINE_A
    do
        # 跳过以#开头的行或空行
        [[ "$LINE_A" =~ ^# ]] || [[ "$LINE_A" =~ ^[\ ]*$ ]] && continue
        #
        LANGUAGE_CATEGORY_A=`echo ${LINE_A} | cut -d \| -f 2`
        LANGUAGE_CATEGORY_A=`echo ${LANGUAGE_CATEGORY_A}`
        #
        PJ_A=`echo ${LINE_A} | cut -d \| -f 3`
        PJ_A=`echo ${PJ_A}`
        #
        if [[ ${PJ_A} == ${PJ} ]] && [[ ${LANGUAGE_CATEGORY_A} == ${LANGUAGE_CATEGORY} ]]; then
            #
            GET_IT_A='YES'
            #
            DOCKER_IMAGE_PRE_NAME=`echo ${LINE_A} | cut -d \| -f 4`
            DOCKER_IMAGE_PRE_NAME=`echo ${DOCKER_IMAGE_PRE_NAME}`
            # 命令行参数优先级最高（1 arg，2 listfile，3 env.sh）
            if [[ -n ${IMAGE_PRE_NAME} ]]; then
                DOCKER_IMAGE_PRE_NAME=${IMAGE_PRE_NAME}
            elif [[ -z ${DOCKER_IMAGE_PRE_NAME} ]]; then
                DOCKER_IMAGE_PRE_NAME=${DEFAULT_DOCKER_IMAGE_PRE_NAME}
            fi
            #
            DOCKER_IMAGE_NAME=`echo ${LINE_A} | cut -d \| -f 5`
            DOCKER_IMAGE_NAME=`echo ${DOCKER_IMAGE_NAME}`
        fi
        #
        if [[ ${GET_IT_A} != 'YES' ]];then
            echo -e "\n猪猪侠警告：在【${PROJECT_LIST_FILE_APPEND_1}】文件中没有找到项目【${PJ}】，请检查！\n"
            exit 51
        fi
    done < ${GOGOGO_PROJECT_LIST_FILE_APPEND_1_TMP}
    #
    #
    RELEASE_CHECK_COUNT=`expr ${RELEASE_CHECK_COUNT} + 1`
    echo ""
    echo -e "${ECHO_BLACK_GREEN}++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++${ECHO_CLOSE}"  #--- 70 (80-70-60)
    echo -e "${ECHO_NORMAL}${RELEASE_CHECK_COUNT} - ${PJ} :${ECHO_CLOSE}"
    #echo -e "${ECHO_BLACK_GREEN}++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++${ECHO_CLOSE}"  #--- 70 (80-70-60)
    echo ""
    #
    # 构建
    #
    echo "正在构建环节，需要较长时间，请等待......"
    > "${GOGOGO_PROJECT_BUILD_RESULT}.${PJ}"
    SEARCH_s=$( F_BUILD_TIME_SEARCH  ${PJ} )
    if [ "${SEARCH_s}" != '0' ]; then
        echo  "上次构建用时 ${SEARCH_s} 秒"
    fi
    BUILD_TIME_0=`date +%s`
    if [[ "${BUILD_QUIET}" == 'YES' ]]; then
        # 静默(并行构建)
        read -u 6       # 获取令牌
        {
            ${BUILD_SH}  --mode function  --category ${LANGUAGE_CATEGORY}  --branch ${GIT_BRANCH}  ${PJ}  ${IMAGE_PRE_NAME_ARG}  ${BUILD_SKIP_TEST_OPT}  ${BUILD_FORCE_OPT}  > /dev/null 2>&1
            BUILD_RETURN=$?
            echo "ok ${BUILD_RETURN}" > "${GOGOGO_PROJECT_BUILD_RESULT}.${PJ}"
            echo >&6    # 归还令牌
        } &
        s=0
        while true
        do
            sleep 1
            let s=$s+1
            #
            if [[ $s -le ${SEARCH_s} ]]; then
                if [ $(($s % 5)) -eq 0 ]; then
                    printf "$s"
                else
                    printf '.'
                fi
            else
                if [ $(($s % 5)) -eq 0 ]; then
                    printf  "\033[33;1m$s\033[0m"
                else
                    printf  "\033[33;1m.\033[0m"
                fi
            fi
            #
            if [ "`awk '{printf $1}' ${GOGOGO_PROJECT_BUILD_RESULT}.${PJ}`" = "ok" ]; then
                echo ' OK'
                break
            fi
        done
    else
        # 非静默
        ${BUILD_SH}  --mode function  --category ${LANGUAGE_CATEGORY}  --branch ${GIT_BRANCH}  ${PJ}  ${IMAGE_PRE_NAME_ARG}  ${BUILD_SKIP_TEST_OPT}  ${BUILD_FORCE_OPT}  --verbose
        BUILD_RETURN=$?
        #echo "ok ${BUILD_RETURN}" > "${GOGOGO_PROJECT_BUILD_RESULT}.${PJ}"
    fi
    #
    BUILD_TIME_1=`date +%s`
    let BUILD_TIME=${BUILD_TIME_1}-${BUILD_TIME_0}
    #
    LINE=`cat  ${BUILD_OK_LIST_FILE_function}`
    BUILD_RESULT=`echo ${LINE} | cut -d : -f 2`
    BUILD_RESULT=`echo ${BUILD_RESULT}`
    #
    # 发布
    #
    echo -e "${ECHO_NORMAL}######################### 开始发布 #########################${ECHO_CLOSE}"  #--- 60 (80-70-60)
    echo ""
    #
    case "${BUILD_RESULT}" in
        '成功')
            #echo "成功"
            F_BUILD_TIME_UPDATE  ${PJ}  ${BUILD_TIME}
            #
            case "${GOGOGO_RELEASE_METHOD}" in
                NONE)
                    # 无需发布
                    echo "${PJ} : 构建${BUILD_RESULT} : 发布跳过，无需发布* : ${BUILD_TIME}s" >> ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE}
                    echo "构建：${BUILD_RESULT} - 发布: 跳过，无需发布* - 耗时: ${BUILD_TIME}s"
                    ;;
                docker_cluster)
                    # 根据镜像名搜索服务名，然后发布
                    F_DOCKER_CLUSTER_SERVICE_DEPLOY  ${DOCKER_IMAGE_NAME}
                    # 结果在函数里处理
                    unset DOCKER_HOST
                    ;;
                web_release)
                    > ${GOGOGO_RELEASE_WEB_OK_LIST_FILE}
                    #./web-release.sh  --release  ${PJ}
                    ansible nginx_real -m command -a "bash /root/nginx-config/web-release-on-nginx.sh  --release  ${PJ}"  > ${GOGOGO_RELEASE_WEB_OK_LIST_FILE}
                    #
                    if [[ $? -eq 0 ]]; then
                        RELEASE_RESULT=$(cat ${GOGOGO_RELEASE_WEB_OK_LIST_FILE} | sed -n '2p' | awk '{printf $2}')
                        echo "${PJ} : 构建${BUILD_RESULT} : 发布${RELEASE_RESULT} : ${BUILD_TIME}s" >> ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE}
                        echo "构建: ${BUILD_RESULT} - 发布: ${RELEASE_RESULT} - 耗时: ${BUILD_TIME}s"
                    else
                        echo "${PJ} : 构建${BUILD_RESULT} : 发布失败 : ${BUILD_TIME}s" >> ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE}
                        echo "构建: ${BUILD_RESULT} - 发布: 失败 - 耗时: ${BUILD_TIME}s"
                    fi
                    ;;
                python_deploy)
                    F_PYTHON_DEPLOY  ${PJ}
                    # 结果在函数里处理
                    ;;
                *)
                    echo -e "\n猪猪侠警告：【${GOGOGO_RELEASE_METHOD}】这个发布方式你自己加的，你自己把它完善下！【脚本名：${SH_NAME}】\n"
                    exit 52
                    ;;
            esac
            ;;
        '失败，其他用户正在构建中'|'失败，Git Clone 出错'|'失败，Git Checkout 出错'|'失败，Git Pull 出错'|'跳过，Git 分支无更新'|'失败'|'跳过，无需构建')
            #echo "失败"
            echo "${PJ} : 构建${BUILD_RESULT} : 发布跳过 : ${BUILD_TIME}s" >> ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE}
            echo "构建：${BUILD_RESULT} - 发布: 跳过 - 耗时 : ${BUILD_TIME}s"
            ;;
        *)
            echo -e "\n猪猪侠警告：这是程序Bug，返回结果为空或超出范围！\n"
            exit 59
            ;;
    esac
    #echo ''
    #echo -e "${ECHO_NORMAL}############################################################${ECHO_CLOSE}"  #--- 60 (80-70-60)
done < ${GOGOGO_PROJECT_LIST_FILE_TMP}
#
exec 6>&-     # 释放文件标识符
echo -e "\nBuild & Release 完成！\n"


# 输出结果
#
# 结果参考：build.sh、docker-cluster-service-deploy.sh、web-release-on-nginx.sh，在原结果前加了【发布】两个字
#
RELEASE_SUCCESS_COUNT=`cat ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE} | grep -o '发布成功' | wc -l`
RELEASE_ERROR_COUNT=`cat ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE} | grep -o '发布失败' | wc -l`
RELEASE_SKIP_COUNT=`cat ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE} | grep -o '发布跳过' | wc -l`
BUILD_ERROR_COUNT=`cat ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE} | grep -o '构建失败' | wc -l`
TIME_END=`date +%Y-%m-%dT%H:%M:%S`
MESSAGE_END="项目构建已完成！ 共企图构建发布${RELEASE_CHECK_COUNT}个项目，成功构建发布${RELEASE_SUCCESS_COUNT}个项目，成功构建但失败发布${RELEASE_ERROR_COUNT}个项目，跳过发布${RELEASE_SKIP_COUNT}个项目，失败构建${BUILD_ERROR_COUNT}个项目。"
# 消息回显拼接
> ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "干：**${GAN_WHAT_FUCK}**" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "===== 构建与发布报告 =====" >> ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo -e "${ECHO_REPORT}################################ 构建与发布报告 ################################${ECHO_CLOSE}"   #--- 80 (80-70-60)
#
echo "所在环境：${RUN_ENV}" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "造 浪 者：${MY_XINGMING}" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "开始时间：${TIME}" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "结束时间：${TIME_END}" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "代码分支：${GIT_BRANCH}" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "镜像TAG ：${DOCKER_IMAGE_TAG}" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "灰度标志：${GRAY_TAG}" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "发布版本：${RELEASE_VERSION}" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "构建与发布清单：" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
# 输出到文件
echo "----------------------------------------------------------------------" >> ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}   #--- 70 (80-70-60)
cat  ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE}            >> ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "----------------------------------------------------------------------" >> ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
# 输出屏幕
${FORMAT_TABLE_SH}  --delimeter ':'  --title '**项目名称**:**构建**:**发布**:**耗时**'  --file ${GOGOGO_BUILD_AND_RELEASE_OK_LIST_FILE}
#
F_TimeDiff  "${TIME_START}" "${TIME_END}" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "日志Web地址：${LOG_DOWNLOAD_SERVER}/file/${DATE_TIME}" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo "日志Local地址：${LOG_HOME}" | tee -a ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
#
echo "${MESSAGE_END}" >> ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
echo -e "${ECHO_REPORT}${MESSAGE_END}${ECHO_CLOSE}"
# 保存历史
cat ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE} >> ${FUCK_HISTORY_FILE}
echo -e "\n\n\n"  >> ${FUCK_HISTORY_FILE}

# markdown
# 删除空行（以及只有tab、空格的行）
sed -i '/^\s*$/d'  ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
t=1
while read LINE
do
    MSG[$t]=$LINE
    #echo ${MSG[$t]}
    let  t=$t+1
done < ${GOGOGO_BUILD_AND_RELEASE_HISTORY_CURRENT_FILE}
${DINGDING_MARKDOWN_PY}  "【Info:${GAN_PLATFORM_NAME}:${RUN_ENV}】" "${MSG[@]}" > /dev/null



