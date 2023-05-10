#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"

# 自动从/etc/profile.d/run-env.sh引入以下变量
RUN_ENV=${RUN_ENV:-'dev'}
DOMAIN=${DOMAIN:-"xxx.lan"}

# 引入env
. "${SH_PATH}/env.sh"
GAN_PLATFORM_NAME="${GAN_PLATFORM_NAME:-'超甜B&D系统'}"
BUILD_LOG_WEBSITE_DOMAIN_A=${BUILD_LOG_WEBSITE_DOMAIN_A:-"build-log"}         #--- 这个需要与【nginx.list】中【项目名】为【build-log】的【域名A记录】保持一致
DINGDING_API=${DINGDING_API:-"请定义"}
#USER_DB_FILE=
ERROR_EXIT=${ERROR_EXIT:-'NO'}                    #--- 出错立即退出
BUILD_SKIP_TEST=${BUILD_SKIP_TEST:-'NO'}          #--- 跳过测试
BUILD_CODE_VERIFY=${BUILD_CODE_VERIFY:-'NONE'}    #--- BUILD_CODE_VERIFY="sonarQube"
NPM_BIN=${NPM_BIN:-'npm'}                         #--- 可选 npm|cnpm
#GIT_REPO_URL_BASE=
#GIT_DEFAULT_NAMESPACE=
#GIT_DEFAULT_BRANCH=
#DOCKER_REPO_SERVER=
#DEFAULT_DOCKER_IMAGE_PRE_NAME=

# 本地env
GAN_WHAT_FUCK='Build'
TIME=${TIME:-`date +%Y-%m-%dT%H:%M:%S`}
TIME_START=${TIME}
DATE_TIME=`date -d "${TIME}" +%Y%m%dT%H%M%S`
ERROR_CODE=''     #--- 程序最终返回值，一般用于【--mode=function】时
#
DOCKER_BUILD_DIR_NAME='./docker_build'          #-- 对于dockerfile类项目，Dockerfile所在目录名
DOCKER_IMAGE_TAG=$(date -d "${TIME}" +%Y.%m.%d.%H%M%S)
#
PROJECT_BASE="${SH_PATH}/tmp/build"
LOG_BASE="${SH_PATH}/tmp/log"
LOG_HOME="${LOG_BASE}/${DATE_TIME}"
WEBSITE_BASE='/srv/web_sites'
PYTHON_SERVICES_BASE='/srv/python_services'
# 方式
SH_RUN_MODE="normal"
BUILD_QUIET='YES'
BUILD_FORCE='NO'
# 来自父shell
BUILD_OK_LIST_FILE_function=${BUILD_OK_LIST_FILE_function:-"${LOG_HOME}/${SH_NAME}-build-OK.list.function"}
MY_USER_NAME=${MY_USER_NAME:-''}
MY_EMAIL=${MY_EMAIL:-''}
# 来自webhook
HOOK_GAN_ENV=${HOOK_GAN_ENV:-''}
HOOK_USER=${HOOK_USER:-''}
#
PROJECT_LIST_FILE="${SH_PATH}/project.list"
PROJECT_LIST_FILE_TMP=${PROJECT_LIST_FILE_TMP:-"${LOG_HOME}/${SH_NAME}-project.list.tmp"}
PROJECT_LIST_FILE_APPEND_1="${SH_PATH}/project.list.append.1"
PROJECT_LIST_RETRY_FILE="${SH_PATH}/project.list.retry"
PROJECT_BUILD_RESULT="${LOG_HOME}/${SH_NAME}-build.result"
PROJECT_BUILD_DURATION_FILE="${SH_PATH}/db/${SH_NAME}-duration.last.db"     #--- db目录下的文件不建议删除
#
GIT_LOG="${LOG_HOME}/${SH_NAME}-git.log"
BUILD_LOG="${LOG_HOME}/${SH_NAME}-build.log"
BUILD_OK_LIST_FILE=${BUILD_OK_LIST_FILE:-"${LOG_HOME}/${SH_NAME}-build-OK.list"}
BUILD_HISTORY_CURRENT_FILE="${LOG_HOME}/${SH_NAME}-history.current"
# 公共
FUCK_HISTORY_FILE="${SH_PATH}/db/fuck.history"
# LOG_DOWNLOAD_SERVER
if [ "x${RUN_ENV}" = "xprod" ]; then
    LOG_DOWNLOAD_SERVER="https://${BUILD_LOG_WEBSITE_DOMAIN_A}.${DOMAIN}"
else
    LOG_DOWNLOAD_SERVER="https://${RUN_ENV}-${BUILD_LOG_WEBSITE_DOMAIN_A}.${DOMAIN}"
fi
# sh
SEND_MAIL="${SH_PATH}/../op/send_mail.sh"
DOCKER_TAG_PUSH_SH="${SH_PATH}/docker-tag-push.sh"
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
#sed -i '/^\s*$/d'  "${PROJECT_LIST_FILE}"
## 删除行中的空格,markdown文件不要这样
#sed -i 's/[ \t]*//g'  ${PROJECT_LIST_FILE}



# 用法：
F_HELP()
{
    echo "
    用途：用于项目构建，生成docker镜像并push到仓库
    依赖：
        /etc/profile.d/run-env.sh
        ${SH_PATH}/env.sh
        ${PROJECT_LIST_FILE}
        ${SEND_MAIL}
        ${DOCKER_TAG_PUSH_SH}
        ${FORMAT_TABLE_SH}
        ${DINGDING_MARKDOWN_PY}
    注意：
        * 名称正则表达式完全匹配，会自动在正则表达式的头尾加上【^ $】，请规避
        * 输入命令时，参数顺序不分先后
    用法:
        $0  [-h|--help]
        $0  [-l|--list]
        $0  <-M|--mode [normal|function]>  <-c|--category [dockerfile|java|node|自定义]>  <-b|--branch {代码分支}>  <-I|--image-pre-name {镜像前置名称}>  <-e|--email {邮件地址}>  <-s|--skiptest>  <-f|--force>  <-v|--verbose>  <{项目1}  {项目2} ... {项目n} ... {项目名称正则表达式完全匹配}>
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
        -M|--mode      指定构建方式，二选一【normal|function】，默认为normal方式。此参数用于被外部调用
        -c|--category  指定构建项目语言类别：【dockerfile|java|node|自定义】，参考：${PROJECT_LIST_FILE}
        -b|--branch    指定代码分支，默认来自env.sh
        -I|--image-pre-name  指定镜像前置名称【DOCKER_IMAGE_PRE_NAME】，默认来自env.sh。注：镜像完整名称：\${DOCKER_REPO_SERVER}/\${DOCKER_IMAGE_PRE_NAME}/\${DOCKER_IMAGE_NAME}:\${DOCKER_IMAGE_TAG}
        -e|--email     发送日志到指定邮件地址，如果与【-U|--user-name】同时存在，则将会被替代
        -s|--skiptest  跳过测试，默认来自env.sh
        -f|--force     强制重新构建（无论是否有更新）
        -v|--verbose   显示更多过程信息
    示例:
        #
        $0  -l         #--- 列出可构建的项目清单
        #
        $0                              #--- 构建所有项目，用默认分支
        $0  -b 分支a                    #--- 构建所有项目，用分支a
        $0  -b 分支a  项目1  项目2      #--- 构建项目：【项目1、项目2】，用【分支a】
        $0            项目1  项目2      #--- 构建项目：【项目1、项目2】，用默认分支
        # 按类别
        $0  -c java                           #--- 构建所有java项目，用默认分支
        $0  -c java  -b 分支a                 #--- 构建所有java项目，用【分支a】
        $0  -c java  -b 分支a  项目1  项目2   #--- 构建java项目：【项目1、项目2】，用【分支a】
        $0  -c java            项目1  项目2   #--- 构建java项目：【项目1、项目2】，用默认分支
        # 项目名称用正则表达式完全匹配
        $0   .*xxx.*        #--- 构建项目名称正则匹配【^.*xxx.*】的项目，用默认分支
        $0   [ab]*xxx       #--- 构建项目名称正则匹配【^[ab]*xxx$】的项目，用默认分支
        $0   sss.*eee       #--- 构建项目名称正则匹配【^sss.*eee$】的项目，用默认分支
        $0   sss.*          #--- 构建项目名称正则匹配【^sss.*$】的项目，用默认分支
        # 镜像前置名称
        $0  -I aaa/bbb  项目1  项目2          #--- 构建项目：【项目1、项目2】，生成的镜像前置名称为【DOCKER_IMAGE_PRE_NAME='aaa/bbb'】，默认来自env.sh。注：镜像完整名称："\${DOCKER_REPO_SERVER}/\${DOCKER_IMAGE_PRE_NAME}/\${DOCKER_IMAGE_NAME}:\${DOCKER_IMAGE_TAG}"
        # 发邮件
        $0  --email xm@xxx.com                #--- 构建所有项目，用默认分支，将错误日志发送到邮箱【xm@xxx.com】
        $0  --email xm@xxx.com  项目1  项目2  #--- 构建项目：【项目1、项目2】，用默认分支，将错误日志发送到邮箱【xm@xxx.com】
        # 测试
        $0  -b 分支a  -s  项目1  项目2        #--- 构建项目：【项目1、项目2】，用【分支a】，跳过测试
        # 强制重新构建
        $0  -f  项目1  项目2                  #--- 构建【项目1、项目2】，用默认分支，无论有没有更新都进行强制构建
        # 显示更多信息
        $0  -v  --email xm@xxx.com                #--- 构建所有项目，用默认分支，显示更多过程信息并将错误日志发送到邮箱【xm@xxx.com】
        $0  -v  --email xm@xxx.com  项目1  项目2  #--- 构建项目：【项目1、项目2】，用默认分支，显示更多详细信息并将错误日志发送到邮箱【xm@xxx.com】
        # 外调用★
        $0  -M function  项目1                #--- 构建项目：【项目1】，用默认分支
        $0  -M function  -b 分支a  项目1      #--- 构建项目：【项目1】，用分支【分支a】
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
    F_THIS_LANGUAGE_CATEGORY="$1"
    F_THIS_PROJECT="$2"
    F_GET_IT=""
    #
    if [[ -z ${F_THIS_PROJECT} ]]; then
        # 匹配类别
        while read LINE
        do
            # 跳过以#开头的行或空行
            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
            #
            F_C=`echo ${LINE} | awk -F '|' '{print $2}'`
            F_C=`echo ${F_C}`
            if [[ ${F_C} == ${F_THIS_LANGUAGE_CATEGORY} ]]; then
                echo "${LINE}"
                F_GET_IT="YES"
            fi
        done < "${PROJECT_LIST_FILE}"
        #
    else
        # 匹配类别与项目名称
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
        done < ${PROJECT_LIST_FILE}
    fi
    # 找没找到
    if [[ ${F_GET_IT} != "YES" ]]; then
        return 3
    else
        return 0
    fi
}



F_FIND_REMOTE_BR()
{
    SEARCH_R_BR="$1"
    git branch -r | grep "${SEARCH_R_BR}" > "${LOG_HOME}/git-r-branch.txt"
    for BR in `cat "${LOG_HOME}/git-r-branch.txt"`
    do
        R_BR=`echo ${BR} | cut -d / -f 2`
        # 找到，返回0
        [ "x${R_BR}" = "x${SEARCH_R_BR}" ] && return 0
    done
    # 没找到
    return 2
}


F_FIND_LOCAL_BR()
{
    SEARCH_L_BR=$1
    git branch | grep "${SEARCH_L_BR}" > "${LOG_HOME}/git-l-branch.txt"
    for BR in `cat "${LOG_HOME}/git-l-branch.txt"`
    do
        L_BR=`echo ${BR} | cut -d / -f 2`
        # 找到，返回0
        [ "x${L_BR}" = "x${SEARCH_L_BR}" ] && return 0
    done
    # 没找到
    return 2
}



ERR_SHOW()
{
    if [ "${ERROR_EXIT}" = 'YES' ]; then
        MESSAGE_ERR="猪猪侠警告：【${GAN_WHAT_FUCK}】时，【${PJ}】出错了，请检查！ 代码分支：${GIT_BRANCH}。构建已终止！"
    else
        MESSAGE_ERR="猪猪侠警告：【${GAN_WHAT_FUCK}】时，【${PJ}】出错了，请检查！ 代码分支：${GIT_BRANCH}。将继续构建后续项目！"
    fi
    echo -e "${ECHO_ERROR}${MESSAGE_ERR}${ECHO_CLOSE}"
    ${DINGDING_MARKDOWN_PY}  "【Error:${GAN_PLATFORM_NAME}:${RUN_ENV}】" "${MESSAGE_ERR}" > /dev/null
}



GIT_CODE()
{
    # clone 或 pull
    if [ ! -d "./${PJ}" ]; then
        #echo "Git Clone ......"
        #timeout 300 git clone  git@${GIT_SERVER}:${GIT_GROUP}/${PJ}.git   2>&1  | tee ${GIT_LOG_file}
        #git clone  git@${GIT_SERVER}:${GIT_GROUP}/${PJ}.git   2>&1  | tee ${GIT_LOG_file}
        #git clone  "git@${GIT_SERVER}:${GIT_GROUP}/${PJ}.git"   > "${GIT_LOG_file}"  2>&1
        git clone  "${GIT_REPO_URL_BASE}${GIT_NAMESPACE}/${PJ}.git"   > "${GIT_LOG_file}"  2>&1
        if [ $? -eq 0 ]; then
            ansible nginx_real -m copy -a "src=${GIT_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"  > "${GIT_LOG_file}"  2>&1
            cd  "${PJ}"
        else
            ansible nginx_real -m copy -a "src=${GIT_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"  > "${GIT_LOG_file}"  2>&1
            echo "失败，Git Clone 出错，请检查仓库权限！"
            echo "${PJ} : 失败，Git Clone 出错 : x" >> "${BUILD_OK_LIST_FILE}"
            ERR_SHOW
            return 54
        fi
        # 是否存在远程分支
        F_FIND_REMOTE_BR "${GIT_BRANCH}"
        if [ $? -eq 0 ]; then
            git checkout "${GIT_BRANCH}"  >> "${GIT_LOG_file}"  2>&1
        else
            echo "失败，Git Checkout 出错，分支未找到！"
            echo "${PJ}" >>  "${PROJECT_LIST_RETRY_FILE}"
            echo "${PJ} : 失败，Git Checkout 出错 : x" >> "${BUILD_OK_LIST_FILE}"
            ERR_SHOW
            return 54
        fi
    else
        # 更改为本地的本地分支有无更新（以前为本地的remote分支有无更新）
        echo  "Git Pull ......"
        cd  "${PJ}"
        git checkout .      #--- 撤销工作区修改
        git clean -xdf     #--- 删除未跟踪的文件与目录
        LAST_BUILD_BRANCH=$(git branch | grep '*' | awk '{print $2}')
        git checkout master  #--- 切换到必定存在的分支，避免当前分支不存在造成后面的git pull命令出错！
        #
        #timeout 300 git pull   2>&1  | tee ${GIT_LOG_file}
        git pull -p  > "${GIT_LOG_file}"  2>&1  #--- pull + 清理远程已删除本地还存在的分支
        if [ $? -ne 0 ]; then
            echo "失败，Git Pull 出错，请检查日志文件：${GIT_LOG_file}"
            ansible nginx_real -m copy -a "src=${GIT_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
            echo "${PJ} : 失败，Git Pull 出错 : x" >> "${BUILD_OK_LIST_FILE}"
            ERR_SHOW
            return 54
        else
            ansible nginx_real -m copy -a "src=${GIT_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
            #
            CURRENT_BRANCH=$(git branch | grep '*' | awk '{print $2}')
            # 是否存在远程分支
            F_FIND_REMOTE_BR "${GIT_BRANCH}"
            if [ $? -eq 0 ]; then
                # 存在远程分支
                #
                # --- 仅当前分支有更新
                # Updating 77a531b..001f51d
                # Fast-forward
                #  init/envs/ansible-hosts---dev   | 6 +++---
                #  init/install-config-certbot.yml | 2 +-
                #  2 files changed, 4 insertions(+), 4 deletions(-)
                #
                # --- 当前分支及其他分支都有更新
                # Unpacking objects: 100% (6/6), done.
                # From g.hb.lan:root/deploy_home
                #    0d2f006..7c4329d  dev        -> origin/dev
                #    77a531b..7a41f17  master     -> origin/master
                # Updating 0d2f006..7c4329d
                # Fast-forward
                #
                # --- 其他分支有更新
                # Unpacking objects: 100% (3/3), done.
                # From g.hb.lan:root/deploy_home
                #    7a41f17..739e851  master     -> origin/master
                # Already up-to-date.
                #
                # 是否当前分支
                if [ "${CURRENT_BRANCH}" = "${GIT_BRANCH}" ]; then
                    # 当前分支
                    # 分支是否更新
                    grep -q  "Fast-forward"  "${GIT_LOG_file}"
                    GIT_GREP_EN=$?
                    grep -q  "快进"  "${GIT_LOG_file}"
                    GIT_GREP_CN=$?
                    if [[ "${GIT_GREP_EN}" -ne 0 && "${GIT_GREP_CN}" -ne 0 && "${LAST_BUILD_BRANCH}" == "${GIT_BRANCH}" ]]; then
                        echo "跳过，Git 分支【${GIT_BRANCH}】无更新！"
                        echo "${PJ} : 跳过，Git 分支无更新 : x" >> "${BUILD_OK_LIST_FILE}"
                        return 55
                    fi
                else
                    # 非当前分支
                    # 是否存在本地分支
                    F_FIND_LOCAL_BR "${GIT_BRANCH}"
                    if [[ $? == 0 ]]; then
                        # 存在本地分支
                        #
                        # checkout 有更新：
                        # Switched to branch 'dev'
                        # Your branch is behind 'origin/dev' by 12 commits, and can be fast-forwarded.
                        #   (use "git pull" to update your local branch)
                        #
                        # 切换到分支 'dev_deploy'
                        # 您的分支落后 'origin/dev_deploy' 共 2 个提交，并且可以快进。
                        #   （使用 "git pull" 来更新您的本地分支）
                        #
                        git checkout "${GIT_BRANCH}"  > ${LOG_HOME}/${SH_NAME}-git_checkout.log 2>&1
                        # 本地代码被修改会造成异常错误
                        # 是否有更新
                        if [ `cat ${LOG_HOME}/${SH_NAME}-git_checkout.log | grep -q 'git pull' ; echo $?` -ne 0 ]; then
                            # 无更新
                            echo "跳过，Git 分支【${GIT_BRANCH}】无更新！"
                            echo "${PJ} : 跳过，Git 分支无更新 : x" >> "${BUILD_OK_LIST_FILE}"
                            return 55
                        fi
                    fi
                fi
                #
                git checkout "${GIT_BRANCH}"
                git pull
                #
            else
                # 不存在远程分支
                echo "失败，Git Checkout 出错，分支未找到！"
                echo "${PJ}" >>  "${PROJECT_LIST_RETRY_FILE}"
                echo "${PJ} : 失败，Git Checkout 出错 : x" >> "${BUILD_OK_LIST_FILE}"
                ERR_SHOW
                return 54
            fi
        fi
    fi
    #
    return 0
}



DOCKER_BUILD()
{
    echo  "Docker Build ......"
    #
    # 构建方法
    case "${BUILD_METHOD}" in
        docker_*)
            DOCKER_BUILD_OPT=""
            if [ "${BUILD_METHOD}" = "docker_build" ]; then
                DOCKER_BUILD_OPT="build"
            else
                echo -e "\n猪猪侠警告：这是你新添加的docker构建方法，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
            fi
            #
            # build
            docker ${DOCKER_BUILD_OPT} -t ${DOCKER_IMAGE_NAME}  ${DOCKER_BUILD_DIR_NAME}  2>&1 | tee -a ${BUILD_LOG_file}
            ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no" 
            grep  'Successfully built'  ${BUILD_LOG_file}
            #
            if [ $? -ne 0 ]; then
                echo ""
                echo -e "${ECHO_ERROR} 失败！请检查日志文件：${BUILD_LOG_file}  ${ECHO_CLOSE}"  2>&1 | tee -a ${BUILD_LOG_file}
                echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no" 
                echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                ERR_SHOW
                # mail
                if [[ ! -z "${MY_EMAIL}" ]]; then
                    ${SEND_MAIL}  --subject "【${RUN_ENV}】Build Log - ${PJ}"  --content "请看附件\n"  --attach "${BUILD_LOG_file}"  "${MY_EMAIL}"
                fi
                return 54
            else
                # out
                case "${OUTPUT_METHOD}" in
                    docker_image_push)
                        if [ -z "${DOCKER_IMAGE_NAME}" ]; then
                            echo -e "\n猪猪侠警告：输出方式为【docker_image_push】时，镜像名不能为空！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                            echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                            ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no" 
                            echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                            echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                            ERR_SHOW
                            return 52
                        fi
                        #
                        ${DOCKER_TAG_PUSH_SH}  ${IMAGE_PRE_NAME_ARG}  --tag ${DOCKER_IMAGE_TAG}  ${PJ}  2>&1 | tee -a ${BUILD_LOG_file}
                        #if [[ $? -ne 0 ]]; then
                        if [[ $(grep -q '猪猪侠警告' ${BUILD_LOG_file}; echo $?) == 0 ]]; then
                            echo -e "\n猪猪侠警告：项目镜像PUSH失败！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                            echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                            ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no" 
                            echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                            echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                            ERR_SHOW
                            return 54
                        fi
                        ;;
                    NONE)
                        # 啥也不用做，这只是为了标准化
                        ;;
                    *)
                        # 啥也不用做，这只是为了标准化
                        echo -e "\n猪猪侠警告：【${OUTPUT_METHOD}】这种输出方法我未定义，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                        ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no" 
                        return 52
                        ;;
                esac
                # echo
                echo 'OUTPUT成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no" 
                #echo "${PJ} : 成功 : x" >> ${BUILD_OK_LIST_FILE}
                return 50
            fi
            ;;
        *)
            echo -e "\n猪猪侠警告：【 ${LANGUAGE_CATEGORY} 之 ${BUILD_METHOD} 】这个构建方法我没弄，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
            ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no" 
            return 52
            ;;
    esac
}


JAVA_BUILD()
{
    echo  "Java Build ......"
    # 构建方法
    case "${BUILD_METHOD}" in
        mvn_*)
            MVN_OPT=""
            if [ "${BUILD_METHOD}" = "mvn_deploy" ]; then
                MVN_OPT=" deploy "
            elif [ "${BUILD_METHOD}" = "mvn_package" ]; then
                MVN_OPT=" package "
            else
                echo -e "\n猪猪侠警告：这是你新添加的mvn构建方法，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
            fi
            #
            # 跳过测试
            if [[ "${BUILD_SKIP_TEST}" == "YES" ]]; then
                MVN_OPT=" ${MVN_OPT} -Dmaven.test.skip=true "
            else
                MVN_OPT=" ${MVN_OPT} -Dmaven.test.skip=false "
            fi
            # 代码审查
            if [[ "${RUN_ENV}" == "dev" ]] && [[ "x${BUILD_CODE_VERIFY}" == "xsonarQube" ]]; then
                MVN_OPT=" ${MVN_OPT} verify sonar:sonar -Dsonar.host.url=${SONARQUBE_SERVER} -Dsonar.login=${SONARQUBE_USER} -Dsonar.password=${SONARQUBE_PASSWORD} "
            fi
            # build
            mvn clean ${MVN_OPT} -X  2>&1 | tee -a ${BUILD_LOG_file}
            ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no" 
            grep  'BUILD\ SUCCESS'  ${BUILD_LOG_file}
            #
            if [ $? -ne 0 ]; then
                echo ""
                echo -e "${ECHO_ERROR}失败！请检查日志文件：${BUILD_LOG_file}  ${ECHO_CLOSE}"  2>&1 | tee -a ${BUILD_LOG_file}
                echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no" 
                # mail
                if [[ ! -z "${MY_EMAIL}" ]]; then
                    ${SEND_MAIL}  --subject "【${RUN_ENV}】Build Log - ${PJ}"  --content "请看附件\n"  --attach "${BUILD_LOG_file}"  "${MY_EMAIL}"
                fi
                echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                ERR_SHOW
                return 54
            else
                # out
                case "${OUTPUT_METHOD}" in
                    docker_image_push)
                        if [ -z "${DOCKER_IMAGE_NAME}" ]; then
                            echo -e "\n猪猪侠警告：输出方式为【docker_image_push】时，镜像名不能为空！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                            echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                            # copy
                            ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                            echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                            echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                            ERR_SHOW
                            return 52
                        fi
                        #
                        ${DOCKER_TAG_PUSH_SH}  ${IMAGE_PRE_NAME_ARG}  --tag ${DOCKER_IMAGE_TAG}  ${PJ}  2>&1 | tee -a ${BUILD_LOG_file}
                        #if [[ $? -ne 0 ]]; then
                        if [[ $(grep -q '猪猪侠警告' ${BUILD_LOG_file}; echo $?) == 0 ]]; then
                            echo -e "\n猪猪侠警告：项目镜像PUSH失败！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                            echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                            # copy
                            ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                            echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                            echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                            ERR_SHOW
                            return 54
                        fi
                        # echo
                        echo 'OUTPUT成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                        # copy
                        ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                        #echo "${PJ} : 成功 : x" >> ${BUILD_OK_LIST_FILE}
                        return 50
                        ;;
                    deploy_jar_to_repo)
                        # 在打包时如果没有deploy，可以在这里处理
                        # 一般不需要
                        # 示例：
                        # mvn deploy:deploy-file -DgroupId=org.apache.commons -DartifactId=commons-imaging -Dversion=1.0-SNAPSHOT -Dpackaging=jar -Dfile=commons-imaging-1.0-SNAPSHOT.jar -Durl=http://mvn-repo:8081/repository/my-mvn-snapshots/  -DrepositoryId=nexus
                        # echo
                        echo 'OUTPUT成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                        # copy
                        ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                        #echo "${PJ} : 成功 : x" >> ${BUILD_OK_LIST_FILE}
                        return 50
                        ;;
                    deploy_war)
                        # 你来
                        echo -e "\n猪猪侠警告：输出方法【${OUTPUT_METHOD}】未定义，你新加的，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                        # copy
                        ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                        return 52
                        ;;
                    NONE)
                        # 啥也不用做，这只是为了代码结构清晰，便于维护
                        # echo
                        echo 'OUTPUT成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                        # copy
                        ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                        #echo "${PJ} : 成功 : x" >> ${BUILD_OK_LIST_FILE}
                        return 50
                        ;;
                    *)
                        # 你来
                        echo -e "\n猪猪侠警告：输出方法【${OUTPUT_METHOD}】未定义，你新加的，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                        # copy
                        ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                        return 52
                        ;;
                esac
            fi
            ;;
        gradle)
            echo -e "\n猪猪侠警告：【 ${LANGUAGE_CATEGORY} 之 ${BUILD_METHOD} 】这个构建方法我没弄，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
            # copy
            ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
            return 52
            ;;
        *)
            echo -e "\n猪猪侠警告：【 ${LANGUAGE_CATEGORY} 之 ${BUILD_METHOD} 】这个构建方法我没弄，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
            # copy
            ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
            return 52
            ;;
    esac
}



# node_modules备份
F_NODE_MODULES_BACKUP()
{
    [ -d ../TMP_NODE_MODULES ] || mkdir ../TMP_NODE_MODULES
    [ ! -d ../TMP_NODE_MODULES/${PJ} ] && mkdir ../TMP_NODE_MODULES/${PJ}
    mv  ./node_modules  ../TMP_NODE_MODULES/${PJ}/
}



NODE_BUILD()
{
    echo  "Node Build ......"
    # node_modules还原
    [ ! -d ../TMP_NODE_MODULES ] && mkdir ../TMP_NODE_MODULES
    if [ -d ../TMP_NODE_MODULES/${PJ}/node_modules ]; then
        mv ../TMP_NODE_MODULES/${PJ}/node_modules  ./
    fi
    #
    ${NPM_BIN} install --ignore-scripts   2>&1 | tee -a ${BUILD_LOG_file}
    ${NPM_BIN} install                    2>&1 | tee -a ${BUILD_LOG_file}
    #
    #
    # ========== 特殊处理START ==========
    #
    # 最好不要有
    #
    # ========== 特殊处理END ==========
    #
    #
    # LINK 公共组件项目
    if [[ -n "${LINK_NODE_PROJECT}" && ! -L "./node_modules/${LINK_NODE_PROJECT}" ]]; then
        ln -s  "../../${LINK_NODE_PROJECT}"  "./node_modules/${LINK_NODE_PROJECT}"
    fi
    #
    # 构建方法
    case "${BUILD_METHOD}" in
        npm_install)
            if [[ -f "./routes/index---${RUN_ENV}.js" ]]; then
                cp -f "./routes/index---${RUN_ENV}.js"  ./routes/index.js
            fi
            ;;
        npm_build)
            npm run build:${RUN_ENV}   2>&1 | tee -a ${BUILD_LOG_file}
            ;;
        *)
            echo -e "\n猪猪侠警告：【 ${LANGUAGE_CATEGORY} 之 ${BUILD_METHOD} 】这个构建方法我没弄，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
            ;;
    esac
    # copy
    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
    #
    grep -E 'Error|ERR!'  ${BUILD_LOG_file}
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${ECHO_ERROR}失败！请检查日志文件：${BUILD_LOG_file}  ${ECHO_CLOSE}"  2>&1 | tee -a ${BUILD_LOG_file}
        echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
        # copy
        ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
        # mail
        if [[ ! -z "${MY_EMAIL}" ]]; then
            ${SEND_MAIL}  --subject "【${RUN_ENV}】Build Log - ${PJ}"  --content "请看附件\n"  --attach "${BUILD_LOG_file}"  "${MY_EMAIL}"
        fi
        echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
        echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
        ERR_SHOW
        return 54
    else
        #
        # ========== 特殊处理START ==========
        #
        # -apply-front用
        if [[ "${PJ}" == *-apply-front ]] && [[ "${PJ}" != *-thirdparty-apply-front ]] ; then
            unzip  -o -q  ./pdfjs.zip -d ./dist/
        fi
        #
        # ========== 特殊处理END ==========
        #
        # 输出方法
        case "${OUTPUT_METHOD}" in
            docker_image_push)
                if [ -z "${DOCKER_IMAGE_NAME}" ]; then
                    echo -e "\n猪猪侠警告：输出方式为【docker_image_push】时，镜像名不能为空！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                    echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                    # copy
                    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                    echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                    echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                    ERR_SHOW
                    return 52
                fi
                #
                docker build -t ${DOCKER_IMAGE_NAME} ./   2>&1 | tee -a ${BUILD_LOG_file}
                DOCKER_BUILD_RETURN=$?
                if [ ${DOCKER_BUILD_RETURN} -ne 0 ]; then
                    echo -e "\n猪猪侠警告：项目镜像Build失败！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                    echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                    # copy
                    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                    echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                    echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                    ERR_SHOW
                    return 54
                fi
                #
                ${DOCKER_TAG_PUSH_SH}  ${IMAGE_PRE_NAME_ARG}  --tag ${DOCKER_IMAGE_TAG}  ${PJ}  2>&1 | tee -a ${BUILD_LOG_file}
                #if [[ $? -ne 0 ]]; then
                if [[ $(grep -q '猪猪侠警告' ${BUILD_LOG_file}; echo $?) == 0 ]]; then
                    echo -e "\n猪猪侠警告：项目镜像PUSH失败！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                    echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                    # copy
                    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                    echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                    echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                    ERR_SHOW
                    return 54
                fi
                #
                # echo
                echo 'Build and Push 成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                #echo "${PJ} : 成功 : x" >> ${BUILD_OK_LIST_FILE}
                F_NODE_MODULES_BACKUP
                return 50
                ;;
            direct_deploy)
                # 不能拷贝软连接（会转化成文件或目录）
                #ansible nginx_real -m copy -a "src=./dist/  dest=${WEBSITE_BASE}/${PJ}/releases/$(date +%Y%m%d)/ backup=no"
                # 可以拷贝软连接，还会自动创建父目录（仅目录拷贝时）
                CP_FROM_DIR='./dist'
                CP_TO_DIR="${WEBSITE_BASE}/${PJ}/releases/$(date +%Y%m%d)"
                ansible nginx_real -m synchronize -a "src=${CP_FROM_DIR}/  dest=${CP_TO_DIR}/  rsync_opts=--perms=yes,--times=yes"
                # echo
                echo 'Build and Deploy 成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                #echo "${PJ} : 成功 : x" >> ${BUILD_OK_LIST_FILE}
                F_NODE_MODULES_BACKUP
                return 50
                ;;
            NONE)
                # 啥也不需要做
                # 我这里用作公共项目共别人链接node_modules用
                echo 'OUTPUT成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                #echo "${PJ} : 成功 : x" >> ${BUILD_OK_LIST_FILE}
                #F_NODE_MODULES_BACKUP
                return 50
                ;;
            *)
                echo -e "\n猪猪侠警告：【 ${LANGUAGE_CATEGORY} 之 ${OUTPUT_METHOD} 】这个输出方法我没弄，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                return 52
                ;;
        esac
    fi
}



HTML_BUILD()
{
    echo  "HTML Build ......"
    #
    # ========== 特殊处理START ==========
    #
    # ========== 特殊处理  END ==========
    #
    # 构建方法
    case "${BUILD_METHOD}" in
        NONE)
            echo "这是静态文件，无需处理"   2>&1 | tee -a ${BUILD_LOG_file}
            ;;
        *)
            echo -e "\n猪猪侠警告：【 ${LANGUAGE_CATEGORY} 之 ${BUILD_METHOD} 】这个构建方法我没弄，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
            ;;
    esac
    # copy
    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
    #
    grep -E 'Error|ERR!'  ${BUILD_LOG_file}
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${ECHO_ERROR}失败！请检查日志文件：${BUILD_LOG_file}  ${ECHO_CLOSE}"  2>&1 | tee -a ${BUILD_LOG_file}
        # copy
        ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
        # mail
        if [[ ! -z "${MY_EMAIL}" ]]; then
            ${SEND_MAIL}  --subject "【${RUN_ENV}】Build Log - ${PJ}"  --content "请看附件\n"  --attach "${BUILD_LOG_file}"  "${MY_EMAIL}"
        fi
        echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
        echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
        echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
        ERR_SHOW
        return 54
    else
        #
        # ========== 特殊处理START ==========
        #
        # ========== 特殊处理  END ==========
        #
        # 输出方法
        case "${OUTPUT_METHOD}" in
            docker_image_push)
                if [ -z "${DOCKER_IMAGE_NAME}" ]; then
                    echo -e "\n猪猪侠警告：输出方式为【docker_image_push】时，镜像名不能为空！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                    echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                    # copy
                    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                    echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                    echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                    ERR_SHOW
                    return 52
                fi
                #
                docker build -t ${DOCKER_IMAGE_NAME} ./   2>&1 | tee -a ${BUILD_LOG_file}
                DOCKER_BUILD_RETURN=$?
                if [ ${DOCKER_BUILD_RETURN} -ne 0 ]; then
                    echo -e "\n猪猪侠警告：项目镜像Build失败！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                    echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                    # copy
                    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                    echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                    echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                    ERR_SHOW
                    return 54
                fi
                #
                ${DOCKER_TAG_PUSH_SH}  ${IMAGE_PRE_NAME_ARG}  --tag ${DOCKER_IMAGE_TAG}  ${PJ}  2>&1 | tee -a ${BUILD_LOG_file}
                #if [[ $? -ne 0 ]]; then
                if [[ $(grep -q '猪猪侠警告' ${BUILD_LOG_file}; echo $?) == 0 ]]; then
                    echo -e "\n猪猪侠警告：项目镜像PUSH失败！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                    echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                    # copy
                    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                    echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                    echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                    ERR_SHOW
                    return 54
                fi
                #
                # echo
                echo 'Build and Push 成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                return 50
                ;;
            direct_deploy)
                # 可以拷贝软连接，还会自动创建父目录（仅目录拷贝时）
                CP_FROM_DIR='./'
                CP_TO_DIR="${WEBSITE_BASE}/${PJ}/releases/$(date +%Y%m%d)"
                ansible nginx_real -m synchronize -a "src=${CP_FROM_DIR}/  dest=${CP_TO_DIR}/  rsync_opts=--perms=yes,--times=yes"
                # echo
                echo 'Build and Deploy 成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                return 50
                ;;
            NONE)
                # 啥也不需要做
                echo 'OUTPUT成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                return 50
                ;;
            *)
                echo -e "\n猪猪侠警告：【 ${LANGUAGE_CATEGORY} 之 ${OUTPUT_METHOD} 】这个输出方法我没弄，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                return 52
                ;;
        esac
    fi
}



PYTHON_BUILD()
{
    echo  "PYTHON Build ......"
    #
    # ========== 特殊处理START ==========
    #
    # ========== 特殊处理  END ==========
    #
    # 构建方法
    case "${BUILD_METHOD}" in
        NONE)
            echo "这是静态文件，无需处理"   2>&1 | tee -a ${BUILD_LOG_file}
            ;;
        *)
            echo -e "\n猪猪侠警告：【 ${LANGUAGE_CATEGORY} 之 ${BUILD_METHOD} 】这个构建方法我没弄，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
            ;;
    esac
    # copy
    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
    #
    grep -E 'Error|ERR!'  ${BUILD_LOG_file}
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${ECHO_ERROR}失败！请检查日志文件：${BUILD_LOG_file}  ${ECHO_CLOSE}"  2>&1 | tee -a ${BUILD_LOG_file}
        # copy
        ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
        # mail
        if [[ ! -z "${MY_EMAIL}" ]]; then
            ${SEND_MAIL}  --subject "【${RUN_ENV}】Build Log - ${PJ}"  --content "请看附件\n"  --attach "${BUILD_LOG_file}"  "${MY_EMAIL}"
        fi
        echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
        echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
        echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
        ERR_SHOW
        return 54
    else
        #
        # ========== 特殊处理START ==========
        #
        # ========== 特殊处理  END ==========
        #
        # 输出方法
        case "${OUTPUT_METHOD}" in
            docker_image_push)
                if [ -z "${DOCKER_IMAGE_NAME}" ]; then
                    echo -e "\n猪猪侠警告：输出方式为【docker_image_push】时，镜像名不能为空！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                    echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                    # copy
                    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                    echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                    echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                    ERR_SHOW
                    return 52
                fi
                #
                docker build -t ${DOCKER_IMAGE_NAME} ./   2>&1 | tee -a ${BUILD_LOG_file}
                DOCKER_BUILD_RETURN=$?
                if [ ${DOCKER_BUILD_RETURN} -ne 0 ]; then
                    echo -e "\n猪猪侠警告：项目镜像Build失败！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                    echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                    # copy
                    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                    echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                    echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                    ERR_SHOW
                    return 54
                fi
                #
                ${DOCKER_TAG_PUSH_SH}  ${IMAGE_PRE_NAME_ARG}  --tag ${DOCKER_IMAGE_TAG}  ${PJ}  2>&1 | tee -a ${BUILD_LOG_file}
                #if [[ $? -ne 0 ]]; then
                if [[ $(grep -q '猪猪侠警告' ${BUILD_LOG_file}; echo $?) == 0 ]]; then
                    echo -e "\n猪猪侠警告：项目镜像PUSH失败！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                    echo -e "项目【${PJ}】已经添加到重试清单：${PROJECT_LIST_RETRY_FILE}"  2>&1 | tee -a ${BUILD_LOG_file}
                    # copy
                    ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                    echo "${PJ}" >>  ${PROJECT_LIST_RETRY_FILE}
                    echo "${PJ} : 失败 : x" >> ${BUILD_OK_LIST_FILE}
                    ERR_SHOW
                    return 54
                fi
                #
                # echo
                echo 'Build and Push 成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                return 50
                ;;
            direct_deploy)
                # 可以拷贝软连接，还会自动创建父目录（仅目录拷贝时）
                CP_FROM_DIR='./'
                CP_TO_DIR="${WEBSITE_BASE}/${PJ}/releases/$(date +%Y%m%d)"
                ansible nginx_real -m synchronize -a "src=${CP_FROM_DIR}/  dest=${CP_TO_DIR}/  rsync_opts=--perms=yes,--times=yes"
                # echo
                echo 'Build and Deploy 成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                return 50
                ;;
            NONE)
                # 啥也不需要做
                echo 'OUTPUT成功！'  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                return 50
                ;;
            *)
                echo -e "\n猪猪侠警告：【 ${LANGUAGE_CATEGORY} 之 ${OUTPUT_METHOD} 】这个输出方法我没弄，你自己搞下！\n"  2>&1 | tee -a ${BUILD_LOG_file}
                # copy
                ansible nginx_real -m copy -a "src=${BUILD_LOG_file} dest=${WEBSITE_BASE}/build-log/releases/current/file/${DATE_TIME}/ owner=root group=root mode=644 backup=no"
                return 52
                ;;
        esac
    fi
}



# 项目构建时间更新
# F_BUILD_TIME_UPDATE  项目名  用时(s)
F_BUILD_TIME_UPDATE()
{
    if [ ! -f "${PROJECT_BUILD_DURATION_FILE}" ]; then
        touch "${PROJECT_BUILD_DURATION_FILE}"
    fi
    F_PJ=$1
    F_TIME=$2
    # Build用时小于10秒，不更新！
    if [ ${F_TIME} -ge 10 ]; then
        grep  -q "${F_PJ}"  "${PROJECT_BUILD_DURATION_FILE}"  \
            && sed -i "s/^${F_PJ}.*$/${F_PJ}  ${F_TIME}/"  "${PROJECT_BUILD_DURATION_FILE}"  \
            || echo "${F_PJ}  ${F_TIME}"  >> "${PROJECT_BUILD_DURATION_FILE}"
        return 0
    else
        return 5
    fi
}


# 历史构建时间搜索
# 用法：F_BUILD_TIME_SEARCH  项目名
F_BUILD_TIME_SEARCH()
{
    if [ ! -f "${PROJECT_BUILD_DURATION_FILE}" ]; then
        echo 0
        return 2
    fi
    F_PJ=$1
    grep  -q "${F_PJ}"  "${PROJECT_BUILD_DURATION_FILE}"
    if [ $? -eq 0 ]; then
        F_TIME=`cat "${PROJECT_BUILD_DURATION_FILE}" | grep "${F_PJ} " | head -n 1 | awk '{printf $2}'`
        echo ${F_TIME}
        return 0
    else
        echo 0
        return 3
    fi
}



# 用户搜索
# F_USER_SEARCH  [用户名|用户ID]
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



# 参数检查
TEMP=`getopt -o hlM:c:b:I:e:sfv  -l help,list,mode:,category:,branch:,image-pre-name:,email:,skiptest,force,verbose -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 51
fi
#
eval set -- "${TEMP}"



# 获取运行参数
while true
do
    #
    case "$1" in
        -h|--help)
            F_HELP
            exit 0
            ;;
        -l|--list)
            #awk 'BEGIN {FS="|"} { if ($3 !~ /^ *$/) {sub(/^[[:blank:]]*/,"",$3); sub(/[[:blank:]]*$/,"",$3); printf "%2d %5s  %s\n",NR,$2,$3} }'  ${PROJECT_LIST_FILE}
            sed  -E  -e '/^\s*$/d'  -e '/^##.*$/d'  -e '/---/d'  -e '/^#.*PRIORITY/d'  ${PROJECT_LIST_FILE}  > /tmp/project-for-list.txt
            ${FORMAT_TABLE_SH}  --delimeter '|'  --file /tmp/project-for-list.txt
            exit 0
            ;;
        -M|--mode)
            SH_RUN_MODE=$2
            shift 2
            # 参数
            case ${SH_RUN_MODE} in
                function)
                    # 关闭错误立即退出
                    ERROR_EXIT='NO'
                    ;;
                normal)
                    # OK
                    ;;
                *)
                    echo -e "\n猪猪侠警告：参数错误，-M|--mode 的参数值只能是：normal|function\n"
                    exit 51
                    ;;
            esac
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


# 建立base目录
[ -d "${LOG_HOME}" ] || mkdir -p  "${LOG_HOME}"
[ -d "${PROJECT_BASE}" ] || mkdir -p  ${PROJECT_BASE}
cd  ${PROJECT_BASE}



# 用户信息
if [[ -n ${HOOK_USER} ]]; then
    MY_USER_NAME=${HOOK_USER}
elif [[ -n ${MY_USER_NAME} ]]; then
    MY_USER_NAME=${MY_USER_NAME}
else
    # if sudo -i 取${SUDO_USER}；
    # if sudo cmd 取${LOGNAME}
    MY_USER_NAME=${SUDO_USER:-"${LOGNAME}"}
fi
#
F_USER_SEARCH ${MY_USER_NAME} > /dev/null
if [ $? -eq 0 ]; then
    R=`F_USER_SEARCH ${MY_USER_NAME}`
    export MY_EMAIL=${MY_EMAIL:-"`echo $R | cut -d ' ' -f 2`"}
    MY_XINGMING=`echo $R | cut -d ' ' -f 1`
else
    MY_XINGMING='X-Man'
fi



# 删除build失败的项目目录，以便重试
if [ -f "${PROJECT_LIST_RETRY_FILE}" ]; then
    for R_PJ in `cat ${PROJECT_LIST_RETRY_FILE}`
    do
        if [ x${R_PJ} != x ]; then
            rm -rf  ${PROJECT_BASE}/${R_PJ}
            sed -i  "/${R_PJ}/d"  ${PROJECT_LIST_RETRY_FILE}
        fi
    done
fi



# 待搜索的服务清单
> ${PROJECT_LIST_FILE_TMP}
## 类别
if [[ -z "${THIS_LANGUAGE_CATEGORY}" ]]; then
    # 参数个数
    if [[ $# -eq 0 ]]; then
        cp  "${PROJECT_LIST_FILE}"  "${PROJECT_LIST_FILE_TMP}"
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
                    echo $LINE >> ${PROJECT_LIST_FILE_TMP}
                    # 仅匹配一次
                    #GET_IT='YES'
                    #break
                    # 匹配多次
                    GET_IT='YES'
                fi
            done < ${PROJECT_LIST_FILE}
            #
            if [[ $GET_IT != 'YES' ]]; then
                echo -e "\n猪猪侠警告：项目【${i}】不在项目列表【${PROJECT_LIST_FILE}】中，请检查！\n"
                exit 51
            fi
        done
    fi
else
    # 类别不为空
    if [[ "${THIS_LANGUAGE_CATEGORY}" == "all" ]]; then
        # 所有项目
        cp  "${PROJECT_LIST_FILE}"  "${PROJECT_LIST_FILE_TMP}"
        # 忽略
        if [[ $# -ne 0 ]]; then
            echo -e "\n猪猪侠警告：这些参数将会被忽略【 $@ 】\n"
        fi
    elif [[ $# -eq 0 ]]; then
        # 仅构建指定类别项目
        # 查找
        F_FIND_PROJECT "${THIS_LANGUAGE_CATEGORY}" >> ${PROJECT_LIST_FILE_TMP}
        if [[ $? -ne 0 ]]; then
            echo -e "\n${ECHO_ERROR}猪猪侠警告：【${GAN_WHAT_FUCK}】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目，请检查！${ECHO_CLOSE}\n"
            ${DINGDING_MARKDOWN_PY}  "【Error:${GAN_PLATFORM_NAME}:${RUN_ENV}】" "猪猪侠警告：【${GAN_WHAT_FUCK}】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目，请检查！" > /dev/null
            exit 51
        fi
    else
        # 仅构建指定类别指定项目
        for i in $@
        do
            # 查找
            F_FIND_PROJECT "${THIS_LANGUAGE_CATEGORY}" "$i" >> ${PROJECT_LIST_FILE_TMP}
            if [[ $? -ne 0 ]]; then
                echo -e "\n${ECHO_ERROR}猪猪侠警告：【${GAN_WHAT_FUCK}】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目【$i】，请检查！${ECHO_CLOSE}\n"
                ${DINGDING_MARKDOWN_PY}  "【Error:${GAN_PLATFORM_NAME}:${RUN_ENV}】" "猪猪侠警告：【${GAN_WHAT_FUCK}】时，没有找到类别为【${THIS_LANGUAGE_CATEGORY}】的项目【$i】，请检查！" > /dev/null
                exit 51
            fi
        done
    fi
fi
# 删除无关行
#sed  -i  -E  -e '/^\s*$/d'  -e '/^#.*$/d'  -e 's/[ \t]*//g'  ${PROJECT_LIST_FILE_TMP}
sed  -i  -E  -e '/^\s*$/d'  -e '/^#.*$/d'  ${PROJECT_LIST_FILE_TMP}
# 优先级排序
> ${PROJECT_LIST_FILE_TMP}.sort
for i in  `awk -F '|' '{split($8,a," ");print NR,a[1]}' ${PROJECT_LIST_FILE_TMP}  |  sort -n -k 2 |  awk '{print $1}'`
do
    awk "NR=="$i'{print}' ${PROJECT_LIST_FILE_TMP}  >> ${PROJECT_LIST_FILE_TMP}.sort
done
cp  ${PROJECT_LIST_FILE_TMP}.sort  ${PROJECT_LIST_FILE_TMP}
# 加表头
sed -i  '1i#| **类别** | **项目名** | **GIT命令空间** | **构建方法** | **输出方法** | **GOGOGO发布方式** | **优先级** | **备注** |'  ${PROJECT_LIST_FILE_TMP}
# 屏显
if [[ ${SH_RUN_MODE} == 'normal' ]]; then
    echo -e "${ECHO_NORMAL}========================= 开始构建 =========================${ECHO_CLOSE}"  #--- 60 (60-50-40)
    echo -e "\n【${SH_NAME}】待构建项目清单："
    ${FORMAT_TABLE_SH}  --delimeter '|'  --file ${PROJECT_LIST_FILE_TMP}
    #echo -e "\n"
fi



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
BUILD_CHECK_COUNT=0
BUILD_SUCCESS_COUNT=0
BUILD_NOCHANGE_COUNT=0
BUILD_NOTNEED_COUNT=0
BUILD_ERROR_COUNT=0
> ${BUILD_OK_LIST_FILE}
# for LINE in `cat ${PROJECT_LIST_FILE}`           #--- 如果PROJECT_LIST_FILE文件'行中有空格'，将会把空格分隔的字符串分别赋值给for循环，在有些场景应该有用，但for循环内外可以变量持久化
# cat ${PROJECT_LIST_FILE} | while read LINE       #--- cat xxx | while循环内对变量的修改不能传递到循环外，就是说跳出循环后变量又变成初始值了！
# while read LINE;do ;done < ${PROJECT_LIST_FILE}  #--- while do done < file 可以实现上面的变量持久问题
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
    GIT_NAMESPACE=`echo ${LINE} | cut -d \| -f 4`
    GIT_NAMESPACE=`echo ${GIT_NAMESPACE}`
    GIT_NAMESPACE=${GIT_NAMESPACE:-"${GIT_DEFAULT_NAMESPACE}"}
    #
    BUILD_METHOD=`echo ${LINE} | cut -d \| -f 5`
    BUILD_METHOD=`echo ${BUILD_METHOD}`
    #
    OUTPUT_METHOD=`echo ${LINE} | cut -d \| -f 6`
    OUTPUT_METHOD=`echo ${OUTPUT_METHOD}`
    #
    # 7 GOGOGO_RELEASE_METHOD
    #
    PRIORITY=`echo ${LINE} | cut -d \| -f 8`
    PRIORITY=`echo ${PRIORITY}`
    #
    NOTE=`echo ${LINE} | cut -d \| -f 9`
    NOTE=`echo ${NOTE}`
    #
    #
    # append.1
    PROJECT_LIST_FILE_APPEND_1_TMP="${LOG_HOME}/${SH_NAME}-${PROJECT_LIST_FILE_APPEND_1##*/}--${LANGUAGE_CATEGORY}-${PJ}"
    cat ${PROJECT_LIST_FILE_APPEND_1} | grep "${PJ}"  >  ${PROJECT_LIST_FILE_APPEND_1_TMP}
    GET_IT_A='NO'
    while read LINE_A
    do
        # 跳过以#开头的行或空行
        [[ "$LINE_A" =~ ^# ]] || [[ "$LINE_A" =~ ^[\ ]*$ ]] && continue
        #
        LANGUAGE_CATEGORY_A=`echo ${LINE} | cut -d \| -f 2`
        LANGUAGE_CATEGORY_A=`echo ${LANGUAGE_CATEGORY_A}`
        #
        PJ_A=`echo ${LINE_A} | cut -d \| -f 3`
        PJ_A=`echo ${PJ_A}`
        #
        if [[ ${PJ_A} == ${PJ} ]] && [[ ${LANGUAGE_CATEGORY_A} == ${LANGUAGE_CATEGORY} ]]; then
            #
            GET_IT_A='YES'
            #
            DOCKER_IMAGE_PRE_NAME=`echo ${LINE} | cut -d \| -f 4`
            DOCKER_IMAGE_PRE_NAME=`echo ${DOCKER_IMAGE_PRE_NAME}`
            # 命令行参数优先级最高（1 arg，2 listfile，3 env.sh）
            if [[ -n ${IMAGE_PRE_NAME} ]]; then
                DOCKER_IMAGE_PRE_NAME=${IMAGE_PRE_NAME}
            elif [[ -z ${DOCKER_IMAGE_PRE_NAME} ]]; then
                DOCKER_IMAGE_PRE_NAME=${DEFAULT_DOCKER_IMAGE_PRE_NAME}
            fi
            #
            DOCKER_IMAGE_NAME=`echo ${LINE} | cut -d \| -f 5`
            DOCKER_IMAGE_NAME=`echo ${DOCKER_IMAGE_NAME}`
            #
            LINK_NODE_PROJECT=`echo ${LINE} | cut -d \| -f 6`
            LINK_NODE_PROJECT=`echo ${LINK_NODE_PROJECT}`
        fi
        #
        if [[ ${GET_IT_A} != 'YES' ]];then
            echo -e "\n猪猪侠警告：在【${PROJECT_LIST_FILE_APPEND_1}】文件中没有找到项目【${PJ}】，请检查！\n"
            exit 51
        fi
    done < ${PROJECT_LIST_FILE_APPEND_1_TMP}
    #
    #
    GIT_LOG_file=${GIT_LOG}.${PJ}
    BUILD_LOG_file=${BUILD_LOG}.${PJ}
    #
    BUILD_CHECK_COUNT=`expr ${BUILD_CHECK_COUNT} + 1`
    cd  ${PROJECT_BASE}
    echo ""
    echo -e "${ECHO_NORMAL}--------------------------------------------------${ECHO_CLOSE}"   #--- 50 (60-50-40)
    echo -e "${ECHO_NORMAL}${BUILD_CHECK_COUNT} - ${PJ} :${ECHO_CLOSE}"
    echo -e "${ECHO_NORMAL}--------------------------------------------------${ECHO_CLOSE}"   #--- 50 (60-50-40)
    echo ""
    #
    # BUILD_METHOD=NONE，则无需构建
    if [ "y${BUILD_METHOD}" = "yNONE" ]; then
        BUILD_TIME=0
        F_BUILD_TIME_UPDATE  ${PJ}  ${BUILD_TIME}
        #
        echo "${PJ} : 跳过，无需构建 : x" >> ${BUILD_OK_LIST_FILE}
        echo  "跳过，构建方法【${BUILD_METHOD}】无需构建！"
        #
        ERROR_CODE=56
        continue
    fi
    #
    echo "构建需要较长时间，请等待......"
    > "${PROJECT_BUILD_RESULT}.${PJ}"
    SEARCH_s=$( F_BUILD_TIME_SEARCH  ${PJ} )
    if [ "${SEARCH_s}" != '0' ]; then
        echo  "上次构建用时 ${SEARCH_s} 秒"
    fi
    BUILD_TIME_0=`date +%s`
    # 检查是否正在构建
    ps -ef | grep "${PJ}" | grep -v "$0" | grep -v '.sh' | grep -v grep > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${PJ} : 失败，其他用户正在构建中 : x" >> ${BUILD_OK_LIST_FILE}
        echo -e "${ECHO_ERROR}【${GAN_WHAT_FUCK}】时，【${PJ}】失败了，其他用户正在构建中${ECHO_CLOSE}"
        ${DINGDING_MARKDOWN_PY}  "【Error:${GAN_PLATFORM_NAME}:${RUN_ENV}】" "【${GAN_WHAT_FUCK}】时，【${PJ}】失败了，其他用户正在构建中" > /dev/null
        [ "x${ERROR_EXIT}" = 'xYES' ] && break
        ERROR_CODE=53
        continue
    fi
    # 强制重新构建
    if [ "${BUILD_FORCE}" = 'YES' -a -d "./${PJ}" ]; then
        rm -rf  "./${PJ}"
    fi
    # 拉取代码
    GIT_CODE
    GIT_CODE_RETURN=$?
    ERROR_CODE=${GIT_CODE_RETURN}
    if [[ $GIT_CODE_RETURN == 54 ]]; then
        # 出错
        [ "x${ERROR_EXIT}" = 'xYES' ] && break
        continue
    elif [[ $GIT_CODE_RETURN == 55 ]]; then
        # 无更新
        continue
    fi
    # 构建
    if [[ "${BUILD_QUIET}" == 'YES' ]]; then
        # 静默
        read -u 6       # 获取令牌
        {
            #
            case "${LANGUAGE_CATEGORY}" in
                product)
                    # 这个类别是成品，无需构建，他的【构建方法=NONE】，所以程序不会运行到这里来的
                    #echo "类别【${LANGUAGE_CATEGORY}】的项目无需构建"  > /dev/null 2>&1
                    NOT_NEED_RETURN=50
                    ;;
                dockerfile)
                    DOCKER_BUILD  > /dev/null
                    ;;
                java)
                    JAVA_BUILD  > /dev/null
                    ;;
                node)
                    NODE_BUILD  > /dev/null
                    ;;
                html)
                    HTML_BUILD  > /dev/null
                    ;;
                python)
                    PYTHON_BUILD  > /dev/null
                    ;;
                *)
                    echo -e "\n猪猪侠警告：【${LANGUAGE_CATEGORY}】这个类别的语言是你新加的，你自己把它完善下！\n"
                    ${LANGUAGE_CATEGORY}_BUILD      #--- 自己定义
                    exit 52
                    ;;
            esac
            ERROR_CODE=${NOT_NEED_RETURN:-$?}
            NOT_NEED_RETURN=''
            echo "ok ${ERROR_CODE}" > "${PROJECT_BUILD_RESULT}.${PJ}"
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
            if [ "`awk '{printf $1}' ${PROJECT_BUILD_RESULT}.${PJ}`" = "ok" ]; then
                echo ' OK'
                break
            fi
        done
    else
        # 非静默
        case "${LANGUAGE_CATEGORY}" in
            product)
                # 这个类别是成品，无需构建，他的【构建方法=NONE】，所以程序不会运行到这里来的
                #echo "类别【${LANGUAGE_CATEGORY}】的项目无需构建"  > /dev/null 2>&1
                NOT_NEED_RETURN=50
                ;;
            dockerfile)
                DOCKER_BUILD
                ;;
            java)
                JAVA_BUILD
                ;;
            node)
                NODE_BUILD
                ;;
            html)
                HTML_BUILD  > /dev/null 2>&1
                ;;
            python)
                PYTHON_BUILD  > /dev/null 2>&1
                ;;
            *)
                echo -e "\n猪猪侠警告：【${LANGUAGE_CATEGORY}】这个类别的语言是你新加的，你自己把它完善下！\n"
                ${LANGUAGE_CATEGORY}_BUILD      #--- 自己定义
                exit 52
                ;;
        esac
        ERROR_CODE=${NOT_NEED_RETURN:-$?}
        NOT_NEED_RETURN=''
        echo "ok ${ERROR_CODE}" > "${PROJECT_BUILD_RESULT}.${PJ}"     #--- pipe中的变量无法传出，所以这里也保持与上面pipe一样
    fi
    #
    PIPE_RETURN=`awk '{printf $2}' ${PROJECT_BUILD_RESULT}.${PJ}`
    ERROR_CODE=${PIPE_RETURN}
    #
    BUILD_TIME_1=`date +%s`
    let BUILD_TIME=${BUILD_TIME_1}-${BUILD_TIME_0}
    #
    # 注意：这里的ERROR_CODE是自定义输出:50代表成功
    if [[ ${ERROR_CODE} -eq 50 ]]; then
        F_BUILD_TIME_UPDATE  ${PJ}  ${BUILD_TIME}
        echo "${PJ} : 成功 : ${BUILD_TIME}s" >> ${BUILD_OK_LIST_FILE}
    else
        [ "x${ERROR_EXIT}" = 'xYES' ] && break
    fi
    #
done < ${PROJECT_LIST_FILE_TMP}
#
exec 6>&-     # 释放文件标识符
echo -e "Build 完成！\n"


# 输出结果
# 
# 54  "失败，Git Clone 出错"
# 54  "失败，Git Checkout 出错"
# 54  "失败，Git Pull 出错"
# 55  "跳过，Git 分支无更新"
# 53  "失败，其他用户正在构建中"
# 54(52)  "失败"
# 50  "成功"
# 56  "跳过，无需构建"
#
BUILD_SUCCESS_COUNT=`cat ${BUILD_OK_LIST_FILE} | grep -o '成功' | wc -l`
BUILD_ERROR_COUNT=`cat ${BUILD_OK_LIST_FILE} | grep -o '失败' | wc -l`
BUILD_NOCHANGE_COUNT=`cat ${BUILD_OK_LIST_FILE} | grep -o '跳过，Git 分支无更新' | wc -l`
BUILD_NOTNEED_COUNT=`cat ${BUILD_OK_LIST_FILE} | grep -o '跳过，无需构建' | wc -l`
TIME_END=`date +%Y-%m-%dT%H:%M:%S`
case ${SH_RUN_MODE} in
    normal)
        #
        MESSAGE_END="项目构建已完成！共企图构建${BUILD_CHECK_COUNT}个项目，成功构建${BUILD_SUCCESS_COUNT}个项目，${BUILD_NOCHANGE_COUNT}个项目无更新，${BUILD_NOTNEED_COUNT}个项目无需构建，${BUILD_ERROR_COUNT}个项目出错。"
        # 消息回显拼接
        > ${BUILD_HISTORY_CURRENT_FILE}
        echo "干：**${GAN_WHAT_FUCK}**" | tee -a ${BUILD_HISTORY_CURRENT_FILE}
        echo "======== 构建报告 ========" >> ${BUILD_HISTORY_CURRENT_FILE}
        echo -e "${ECHO_REPORT}========================= 构建报告 ==========================${ECHO_CLOSE}"    #--- 60 (60-50-40)
        #
        echo "所在环境：${RUN_ENV}" | tee -a ${BUILD_HISTORY_CURRENT_FILE}
        echo "造 浪 者：${MY_XINGMING}" | tee -a ${BUILD_HISTORY_CURRENT_FILE}
        echo "开始时间：${TIME}" | tee -a ${BUILD_HISTORY_CURRENT_FILE}
        echo "结束时间：${TIME_END}" | tee -a ${BUILD_HISTORY_CURRENT_FILE}
        echo "代码分支：${GIT_BRANCH}" | tee -a ${BUILD_HISTORY_CURRENT_FILE}
        echo "镜像TAG ：${DOCKER_IMAGE_TAG}" | tee -a ${BUILD_HISTORY_CURRENT_FILE}
        echo "已构建清单：" | tee -a ${BUILD_HISTORY_CURRENT_FILE}
        # 输出到文件
        echo "--------------------------------------------------" >> ${BUILD_HISTORY_CURRENT_FILE}   #--- 50 (60-50-40)
        cat  ${BUILD_OK_LIST_FILE}                        >> ${BUILD_HISTORY_CURRENT_FILE}
        echo "--------------------------------------------------" >> ${BUILD_HISTORY_CURRENT_FILE}
        # 输出屏幕
        ${FORMAT_TABLE_SH}  --delimeter ':'  --title '**项目名称**:**构建**:**耗时**'  --file ${BUILD_OK_LIST_FILE}
        #
        F_TimeDiff  "${TIME_START}" "${TIME_END}" | tee -a ${BUILD_HISTORY_CURRENT_FILE}
        echo "日志Web地址：${LOG_DOWNLOAD_SERVER}/file/${DATE_TIME}" | tee -a ${BUILD_HISTORY_CURRENT_FILE}
        echo "日志Local地址：${LOG_HOME}" | tee -a ${BUILD_HISTORY_CURRENT_FILE}
        echo "${MESSAGE_END}" >> ${BUILD_HISTORY_CURRENT_FILE}
        echo -e "${ECHO_REPORT}${MESSAGE_END}${ECHO_CLOSE}"
        # 保存历史
        cat ${BUILD_HISTORY_CURRENT_FILE} >> ${FUCK_HISTORY_FILE}
        echo -e "\n\n\n"  >> ${FUCK_HISTORY_FILE}

        # markdown
        # 删除空行（以及只有tab、空格的行）
        sed -i '/^\s*$/d'  ${BUILD_HISTORY_CURRENT_FILE}
        t=1
        while read LINE
        do
            MSG[$t]=$LINE
            #echo ${MSG[$t]}
            let  t=$t+1
        done < ${BUILD_HISTORY_CURRENT_FILE}
        ${DINGDING_MARKDOWN_PY}  "【Info:${GAN_PLATFORM_NAME}:${RUN_ENV}】" "${MSG[@]}" > /dev/null
        exit 0
        ;;
    function)
        #
        if [ `cat ${BUILD_OK_LIST_FILE} | wc -l` -eq 0 ]; then
            # 结果为空
            exit 59
        fi
        #
        cat  ${BUILD_OK_LIST_FILE} > ${BUILD_OK_LIST_FILE_function}
        exit ${ERROR_CODE}
        ;;
    *)
        echo -e "\n猪猪侠警告：这是你自己加的，请自行完善！\n"
        exit 51
        ;;
esac

