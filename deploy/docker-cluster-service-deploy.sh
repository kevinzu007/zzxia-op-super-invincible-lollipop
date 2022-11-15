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
. ${SH_PATH}/deploy.env
#DINGDING_API=
#USER_DB=
#CONTAINER_ENVS_PUB_FILE=
#NETWORK_SWARM=
#NETWORK_COMPOSE=
#SWARM_DOCKER_HOST=
#K8S_NAMESAPCE=
#DEBUG_RANDOM_PORT_MIN=
#DEBUG_RANDOM_PORT_MAX=
#DOCKER_IMAGE_BASE=
#DOCKER_REPO_SECRET_NAME=

# 本地env
TIME=${TIME:-`date +%Y-%m-%dT%H:%M:%S`}
TIME_START=${TIME}
DATE_TIME=`date -d "${TIME}" +%Y%m%dt%H%M%S`
#
DEBUG='NO'
RELEASE_VERSION=''
# 灰度
GRAY_TAG="normal"                                             #--- 【normal】正常部署；【gray】灰度部署
DEBUG_X_PORTS_FILE="${SH_PATH}/db/deploy-debug-x-ports.db"    #--- db目录下的文件不建议删除
#
LOG_BASE="${SH_PATH}/tmp/log"
LOG_HOME="${LOG_BASE}/${DATE_TIME}"
YAML_BASE="${SH_PATH}/tmp/yaml"
DOCKER_COMPOSE_BASE='/srv/docker'
#
ERROR_CODE=''     #--- 程序最终返回值，一般用于【--mode=function】时
#
DOCKER_ARG_PUB_FILE="${SH_PATH}/docker-arg-pub.list"
CONTAINER_HOSTS_PUB_FILE="${SH_PATH}/container-hosts-pub.list"
JAVA_OPTIONS_PUB_FILE="${SH_PATH}/java-options-pub.list"
#
SERVICE_LIST_FILE="${SH_PATH}/docker-cluster-service.list"
SERVICE_LIST_FILE_TMP="${LOG_HOME}/${SH_NAME}-docker-cluster-service.list.tmp"
SERVICE_ONLINE_LIST_FILE_TMP="${LOG_HOME}/${SH_NAME}-docker-cluster-service-online.list.tmp"
DOCKER_IMAGE_VER='latest'
FUCK=${FUCK:-"no"}
#
DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE=${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE:-"${LOG_HOME}/${SH_NAME}-OK.list"}
#
DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE="${LOG_HOME}/${SH_NAME}-history.current"
FUCK_HISTORY_FILE="${LOG_BASE}/fuck.history"
# 运行方式
SH_RUN_MODE="normal"
# 来自父shell
DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE_function=${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE_function:-"${LOG_HOME}/${SH_NAME}-OK.function"}
MY_XINGMING=${MY_XINGMING:-''}
MY_EMAIL=${MY_EMAIL:-''}
# sh
DOCKER_IMAGE_SEARCH_SH="${SH_PATH}/docker-image-search.sh"
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



# 用法：
F_HELP()
{
    echo "
    用途：用于创建、更新、查看、删除......服务
    依赖：
        ${SERVICE_LIST_FILE}
        ${CONTAINER_ENVS_PUB_FILE}
        ${DOCKER_ARG_PUB_FILE}
        ${CONTAINER_HOSTS_PUB_FILE}
        ${JAVA_OPTIONS_PUB_FILE}
        ${SH_PATH}/deploy.env
        ${DOCKER_IMAGE_SEARCH_SH}
        ${FORMAT_TABLE_SH}
        ${DINGDING_MARKDOWN_PY}
    注意：
        * 名称正则表达式完全匹配，会自动在正则表达式的头尾加上【^ $】，请规避
        * 一般服务名（非灰度服务名）为项目清单中的服务名，灰度服务名为为【项目清单服务名】+【--】+【灰度版本号】
        * 输入命令时，参数顺序不分先后
    用法:
        $0 [-h|--help]
        $0 [-l|--list]                    #--- 列出配置文件中的服务清单
        $0 [-L|--list-run swarm|k8s]      #--- 列出指定集群中运行的所有服务，不支持持【docker-compose】
        # 创建、修改
        $0 <-M|--mode [normal|function]>  [-c|--create|-m|--modify]  <-D|--debug>  <<-t|--tag {模糊镜像tag版本}> | <-T|--TAG {精确镜像tag版本}>>  <-n|--number {副本数}>  <-V|--release-version {版本号}>  <-G|--gray>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        # 更新
        $0 <-M|--mode [normal|function]>  [-u|--update]  <<-t|--tag {模糊镜像tag版本}> | <-T|--TAG {精确镜像tag版本}>>  <-V|--release-version {版本号}>  <-G|--gray>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        # 回滚
        $0 <-M|--mode [normal|function]>  [--b|rollback]   <-V|--release-version {版本号}>  <-G|--gray>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        #
        # 扩缩容
        $0 <-M|--mode [normal|function]>  [-S|--scale]  [-n|--number {副本数}]  <-V|--release-version {版本号}>  <-G|--gray>  <{服务名或灰度服务名1} {服务名或灰度服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        # 删除
        $0 <-M|--mode [normal|function]>  [-r|--rm]  <-V|--release-version {版本号}>  <-G|--gray>  <-a|--all-release>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        # 状态
        $0 [-s|--status]  <-V|--release-version {版本号}>  <-G|--gray>  <-a|--all-release>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        # 详情
        $0 [-d|--detail]  <-V|--release-version {版本号}>  <-G|--gray>  <-a|--all-release>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      ：帮助
        -l|--list      ：列出配置文件中的服务清单
        -L|--list-run  ：列出指定集群中运行的所有服务，不支持【docker-compose】集群
        -F|--fuck      ：直接运行命令，默认：仅显示命令行
        -c|--create    ：创建服务，基于服务清单参数
        -m|--modify    ：修改服务，基于服务清单参数
        -u|--update    ：更新镜像版本
        -b|--rollback  ：回滚服务（回滚到非今天构建的上一个版本）
        -S|--scale     ：副本数设置
        -r|--rm        ：删除服务
        -s|--status    : 获取服务运行状态
        -d|--detail    : 获取服务详细信息
        -D|--debug     : 开启开发者Debug模式，目前用于开放所有容器服务端口
        -t|--tag       ：模糊镜像tag版本
        -T|--TAG       ：精确镜像tag版本
        -n|--number    ：Pod副本数
        -G|--gray      : 设置灰度标志为：gray，默认：normal
        -V|--release-version : 发布版本号
        -a|--all-release     : 所有已发布的版本，包含带版本号的、不带版本号的、灰度的、非灰度的
        -M|--mode      ：指定构建方式，二选一【normal|function】，默认为normal方式。此参数用于被外部调用
    示例：
        # 服务清单
        $0 -l                     #--- 列出配置文件中的服务清单
        $0 -L swarm               #--- 列出【swarm】集群中运行的所有服务
        # 仅显示最终命令行或直接执行（用于检查命令是否有错误）
        $0 -c  服务1                             #--- 根据服务清单显示创建【服务1】的命令行
        $0 -c  服务1  -F                         #--- 根据服务清单创建【服务1】
        # 服务名称正则完全匹配
        $0  -c  .*xxx.*  -F                      #--- 创建服务名称正则完全匹配【^.*xxx.*$】的服务，使用最新镜像
        $0  -u  [.]*xxx  -F                      #--- 更新服务名称正则完全匹配【^[.]*xxx$】的服务，使用最新镜像
        # 创建
        $0 -c  -F                                    #--- 根据服务清单创建所有服务
        $0 -c  服务1 服务2  -F                       #--- 创建【服务1】、【服务2】服务
        $0 -c  -D  服务1 服务2  -F                   #--- 创建【服务1】、【服务2】服务，并开启开发者Debug模式
        $0 -c  -T 2020.12.11  服务1 服务2  -F        #--- 创建【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】
        $0 -c  -t 2020.12     服务1 服务2  -F        #--- 创建【服务1】、【服务2】服务，且使用的镜像版本包含【2020.12】的最新镜像
        $0 -c  -n 2  服务1 服务2  -F                 #--- 创建【服务1】、【服务2】服务，且副本数为【2】
        $0 -c  -T 2020.12.11  -n 2  服务1 服务2  -F  #--- 创建【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】，副本数为【2】
        $0 -c  -V yyy       服务1 服务2  -F          #--- 创建【服务1】、【服务2】，版本号为【yyy】
        $0 -c  -G           服务1 服务2  -F          #--- 创建【服务1】、【服务2】的灰度服务
        $0 -c  -G  -V yyy   服务1 服务2  -F          #--- 创建【服务1】、【服务2】的灰度服务，版本号为【yyy】
        # 修改
        $0 -m  服务1 服务2  -F                       #--- 修改【服务1】、【服务2】服务
        $0 -m  服务1 服务2  -V yyy  -F               #--- 根据服务清单修改所有版本号为【yyy】的服务
        $0 -m  -T 2020.12.11  服务1 服务2  -F        #--- 修改【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】
        $0 -m  -t 2020.12     服务1 服务2  -F        #--- 修改【服务1】、【服务2】服务，且使用的镜像版本包含【2020.12】的最新镜像
        $0 -m  -n 2  服务1 服务2  -F                 #--- 修改【服务1】、【服务2】服务，且副本数为【2】
        $0 -m  -T 2020.12.11  -n 2  服务1 服务2  -F  #--- 修改【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】，副本数为【2】
        # 更新镜像
        $0 -u  -F                                    #--- 根据服务清单更新设置所有服务的最新镜像tag版本（如果今天构建过）
        $0 -u  服务1 服务2  -F                       #--- 设置【服务1】、【服务2】服务的最新镜像tag版本（如果今天构建过）
        $0 -u  -t 2020.12  -F                        #--- 根据服务清单更新设置所有服务，且镜像tag版本包含【2020.12】的最新镜像
        $0 -u  -t 2020.12     服务1 服务2  -F        #--- 更新【服务1】、【服务2】有服务，且镜像tag版本包含【2020.12】的最新镜像
        $0 -u  -T 2020.12.11  -F                     #--- 根据服务清单更新设置所有服务，且镜像tag版本为【2020.12.11】的镜像
        $0 -u  -T 2020.12.11  服务1 服务2  -F        #--- 更新【服务1】、【服务2】有服务，且镜像tag版本为【2020.12.11】的镜像
        # 回滚
        $0 -b  -F                          #--- 根据服务清单回滚所有服务（如果今天构建过）
        $0 -b  服务1 服务2  -F             #--- 回滚【服务1】、【服务2】服务（如果今天构建过）
        $0 -b  服务1 服务2  -V yyy  -F     #--- 回滚【服务1】、【服务2】服务，且版本号为【yyy】（如果今天构建过）
        #
        # 扩缩容
        $0 -S  -n 2  -F                    #--- 根据服务清单设置所有服务的pod副本数为2
        $0 -S  -n 2  服务1 服务2  -F       #--- 设置【服务1】、【服务2】服务的pod副本数为2
        $0 -S  -n 2  -G  服务1 服务2  -F   #--- 设置【服务1】、【服务2】的灰度服务的pod副本数为2
        $0 -S  -n 2  -G  -V yyy  服务1 服务2  -F   #--- 设置【服务1】、【服务2】的灰度服务，且版本为【yyy】的pod副本数为2
        # 删除
        $0 -r  -F                          #--- 根据服务清单删除所有服务
        $0 -r  服务1 服务2  -F             #--- 删除【服务1】、【服务2】服务
        $0 -r  -G  服务1 服务2  -F         #--- 删除【服务1】、【服务2】的灰度服务
        $0 -r  -V yyy  服务1 服务2  -F     #--- 删除【服务1】、【服务2】，且版本为【yyy】的服务
        $0 -r  -V yyy  -G  服务1 服务2  -F #--- 删除【服务1】、【服务2】，且版本为【yyy】的灰度服务
        $0 -r  -a  服务1 服务2  -F         #--- 删除模糊匹配【服务1】、【服务2】的服务，包含带版本号的、不带版本号的、灰度的、非灰度的
        # 运行状态（更多请参考【删除】）
        $0 -s  -F                          #--- 根据服务清单获取服务运行状态
        $0 -s  服务1 服务2  -F             #--- 获取【服务1】、【服务2】服务运行状态
        $0 -s  -G  服务1 服务2  -F         #--- 获取【服务1】、【服务2】的灰度服务运行状态
        # 运行详细信息（更多请参考【删除】）
        $0 -d  -F                          #--- 根据服务清单获服务运行取详细信息
        $0 -d  服务1 服务2  -F             #--- 获取【服务1】、【服务2】服务运行详细信息
        # 外调用★ 
        $0 -M function  -u                 服务1  -F    #--- 更新部署【服务1】，使用最新镜像
        $0 -M function  -u  -T 2020.12.11  服务1  -F    #--- 更新部署【服务1】，使用版本为【2020.12.11】的镜像
    "
}



# 时间差计算函数
# F_TimeDiff  [开始时间]  [结束时间]
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



# 模糊查找已部署的service，返回是否找到及清单
# 用法：F_ONLINE_SERVICE_SEARCH_LIKE  [服务名]  [集群类型]
F_ONLINE_SERVICE_SEARCH_LIKE()
{
    F_SEARCH_NAME=$1
    F_CLUSTER=$2
    case "${F_CLUSTER}" in 
        swarm)
            GET_IT=''
            #docker service ls  --format "{{.Name}}"  --filter name=${F_SEARCH_NAME} | while read S_LINE
            for S_LINE in $(docker service ls  --format "{{.Name}}")
            do
                if [[ ${S_LINE} =~ ${F_SEARCH_NAME} ]]; then
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
                if [[ ${S_LINE} =~ ${F_SEARCH_NAME} ]]; then
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



# 搜索镜像精确版本
# 返回是否找到
# F_SEARCH_IMAGE_TAG  [服务名]  [镜像版本]
F_SEARCH_IMAGE_TAG()
{
    F_SERVICE_NAME=$1
    F_THIS_TAG=$2
    ${DOCKER_IMAGE_SEARCH_SH}  --tag ${F_THIS_TAG}  --output ${LOG_HOME}/${SH_NAME}-F_SEARCH_IMAGE_TAG-result.txt  ${F_SERVICE_NAME}
    search_r=$(cat ${LOG_HOME}/${SH_NAME}-F_SEARCH_IMAGE_TAG-result.txt | cut -d " " -f 3-)
    F_GET_IT=""
    # 这个其实不可能有多行
    for i in ${search_r}
    do
        if [ "$i" = "${F_THIS_TAG}" ]; then
            F_GET_IT="YES"
            break
        fi
    done
    # 找到否
    if [ "${F_GET_IT}" = "YES" ]; then
        return 0
    else
        return 3
    fi
}



##### 已经弃用，因为子脚本异常不方便展示 #####
# 搜索镜像模糊版本最新的一个
# 返回是否找到，并输出镜像版本号
# F_SEARCH_IMAGE_LIKE_TAG  [服务名]  [%镜像版本%]
F_SEARCH_IMAGE_LIKE_TAG()
{
    F_SERVICE_NAME=$1
    F_LIKE_THIS_TAG=$2
    ${DOCKER_IMAGE_SEARCH_SH}  --tag ${F_LIKE_THIS_TAG}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-F_SEARCH_IMAGE_LIKE_TAG-result.txt  ${F_SERVICE_NAME}  1>/dev/null 2>/dev/null   #--- 需要关闭任何输出，方便取的结果，以结果是否为空作为成功失败的标志
    search_like_r=$(cat ${LOG_HOME}/${SH_NAME}-F_SEARCH_IMAGE_LIKE_TAG-result.txt | cut -d " " -f 3)
    #
    if [[ ! -z ${search_like_r} ]]; then
        echo ${search_like_r}
        return 0
    else
        return 3
    fi
}



# 搜索镜像排除模糊版本后最新的一个
# 返回是否找到，并输出镜像版本号
# F_SEARCH_IMAGE_NOT_LIKE_TAG  [服务名]  [%镜像版本%]
F_SEARCH_IMAGE_NOT_LIKE_TAG()
{
    F_SERVICE_NAME=$1
    F_NOT_LIKE_THIS_TAG=$2
    ${DOCKER_IMAGE_SEARCH_SH}  --exclude ${F_NOT_LIKE_THIS_TAG}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-F_SEARCH_IMAGE_NOT_LIKE_TAG-result.txt  ${F_SERVICE_NAME}  2>/dev/null
    search_not_like_r=$(cat ${LOG_HOME}/${SH_NAME}-F_SEARCH_IMAGE_NOT_LIKE_TAG-result.txt | cut -d " " -f 3)
    # 
    if [[ ! -z ${search_not_like_r} ]]; then
        echo ${search_not_like_r}
        return 0
    else
        return 3
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
    done < "${USER_DB}"
    return 3
}



# 从文件追加到变量：CONTAINER_ENVS_OK
# 用法：F_ENVS_FROM_FILE  [/path/to/FILENAME]  [集群类型]
F_ENVS_FROM_FILE ()
{
    F_CONTAINER_ENVS_FILE=$1
    F_CLUSTER=$2
    while read ENV_LINE
    do
        # 跳过以#开头的行或空行
        [[ "$ENV_LINE" =~ ^# ]] || [[ "$ENV_LINE" =~ ^[\ ]*$ ]] && continue
        #
        # 转化变量
        ENV_LINE=$( eval echo ${ENV_LINE} )
        ENV_LINE=${ENV_LINE//'~/${HOME}'}
        if [[ "${ENV_LINE}" =~ ^export.*=.+$ ]]; then
            # 有export，有=
            F_CONTAINER_ENVS_FILE_SET_n=$( echo ${ENV_LINE} | awk '{print $2}' | awk -F '=' '{print $1}' )
            F_CONTAINER_ENVS_FILE_SET_n=$( echo ${F_CONTAINER_ENVS_FILE_SET_n} )
            F_CONTAINER_ENVS_FILE_SET_v=$( echo ${ENV_LINE} | awk '{print $2}' | awk -F '=' '{print $2}' | sed 's/\"//g' )
            F_CONTAINER_ENVS_FILE_SET_v=$( echo ${F_CONTAINER_ENVS_FILE_SET_v} )
        elif [[ "${ENV_LINE}" =~ ^[a-zA-Z]+.*=.+$ ]]; then
            # 无export，有=
            F_CONTAINER_ENVS_FILE_SET_n=$( echo ${ENV_LINE} | awk -F '=' '{print $1}' )
            F_CONTAINER_ENVS_FILE_SET_n=$( echo ${F_CONTAINER_ENVS_FILE_SET_n} )
            F_CONTAINER_ENVS_FILE_SET_v=$( echo ${ENV_LINE} | awk -F '=' '{print $2}' | sed 's/\"//g' )
            F_CONTAINER_ENVS_FILE_SET_v=$( echo ${F_CONTAINER_ENVS_FILE_SET_v} )
        fi
        # 输出
        case "${F_CLUSTER}" in
            swarm)
                CONTAINER_ENVS_OK="${CONTAINER_ENVS_OK}  --env ${F_CONTAINER_ENVS_FILE_SET_n}=\"${F_CONTAINER_ENVS_FILE_SET_v}\""
                ;;
            k8s)
                sed -i "/        env:/a\        - name: ${F_CONTAINER_ENVS_FILE_SET_n}\n          value: ${F_CONTAINER_ENVS_FILE_SET_v}"  ${YAML_HOME}/${SERVICE_X_NAME}.yaml
                ;;
            compose)
                sed -i "/^    environment:/a\      ${F_CONTAINER_ENVS_FILE_SET_n}: ${F_CONTAINER_ENVS_FILE_SET_v}"  ${YAML_HOME}/docker-compose.yaml
                ;;
            *)
                echo -e "\n猪猪侠警告：未定义集群类型！\n"
                return 52
                ;;
        esac
    done < "${F_CONTAINER_ENVS_FILE}"
    return 0
}



# k8s base yaml
F_K8S_MODEL_YAML()
{
    echo "
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${SERVICE_X_NAME}
  namespace: ${K8S_NAMESAPCE:-'default'}
  annotations:
  #  deployment.kubernetes.io/revision: "1"
  labels:
    project-code: pufi
spec:
  selector:
    matchLabels:
      project: ${SERVICE_X_NAME}
  progressDeadlineSeconds: 300
  replicas: ${POD_REPLICAS}
  revisionHistoryLimit: 10
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        project: ${SERVICE_X_NAME}
    spec:
      hostname:
      hostAliases:
      containers:
      - name: c-${SERVICE_X_NAME}
        image: ${DOCKER_IMAGE_BASE}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VER}
        imagePullPolicy: IfNotPresent
        args:
        env:
        ports:
      imagePullSecrets:
      - name: ${DOCKER_REPO_SECRET_NAME}
      nodeSelector:
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      terminationGracePeriodSeconds: 30

---
apiVersion: v1
kind: Service
metadata:
  name: ${SERVICE_X_NAME}
  namespace: default
  annotations:
  labels:
    project: ${SERVICE_X_NAME}
spec:
  type: NodePort
  selector:
    project: ${SERVICE_X_NAME}
  ports:
    "
}



# docker-compose base yaml
F_DOCKER_COMPOSE_MODEL_YAML()
{
    echo "
version: '3'
services:
  ${SERVICE_NAME}:
    image: 
    container_name: ${SERVICE_NAME}.${DATE_TIME}
    hostname: ${SERVICE_NAME}
    restart: always
    #entrypoint: ["/path/entrypoint.sh"]
    #command: 
    # 必须有
    ports:
    networks:
      - ${NETWORK_COMPOSE}
    extra_hosts:
      - somehost:1.1.1.1
    #depends_on:
    #  - db 
    environment:
      foo: "bar"
    #volumes:
    #  - ./tmp:/tmp/cac:ro
    # 其他（一般不用）
    #cpu_shares: 73
    #cpu_quota: 50000
    #mem_limit: 1000000000
    #privileged: true
networks:
  ${NETWORK_COMPOSE}:
    "
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
            export DOCKER_HOST=${SWARM_DOCKER_HOST}
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
            export DOCKER_HOST=${COMPOSE_DOCKER_HOST}
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



# 查询在线服务publish端口
# 用法：F_SEARCH_ONLINE_SERVICE_PUBLISH_PORTS [{服务名}]
# 返回端口号列表（以空格分隔）
F_SEARCH_ONLINE_SERVICE_PUBLISH_PORTS()
{
    FS_SERVICE_NAME=$1
    case "${CLUSTER}" in
        swarm)
            #
            docker service ls --format="{{.Name}}, {{.Ports}}"  | grep ${FS_SERVICE_NAME}  > ${LOG_HOME}/${SH_NAME}-F_SEARCH_ONLINE_SERVICE_PUBLISH_PORTS.txt
            #
            for ONLINE_LINE in $(cat  ${LOG_HOME}/${SH_NAME}-F_SEARCH_ONLINE_SERVICE_PUBLISH_PORTS.txt)
            do
                ONLINE_SERVICE_NAME=$(echo ${ONLINE_LINE} | awk -F ', ' '{print $1}')
                PUBLISH_PORTS=''
                if [[ ${FS_SERVICE_NAME} == ${ONLINE_SERVICE_NAME} ]]; then
                    PUBLISH_PORTS_NUM=$(echo ${ONLINE_LINE} | awk -F ', ' '{print NF}')
                    for((p=2; p<=PUBLISH_PORTS_NUM; p++))
                    do
                        PUBLISH_PORTS="${PUBLISH_PORTS} $(echo ${ONLINE_LINE} | awk -F ', ' -v p=$p  '{print $p}' | awk -F ':' '{print $2}' | awk -F '->' '{print $1}')"
                    done
                fi
            done
            ;;
        k8s)
            # 待办：
            echo
            ;;
        compose)
            # 不需要
            echo
            ;;
        *)
            echo -e "\n猪猪侠警告：未定义的集群类型\n"
            exit 52
            ;;
    esac
    #
    echo ${PUBLISH_PORTS}
    return 0
}



# 删除已删除服务的publish端口
# 用法：F_DEBUG_X_PORTS_RM  端口1 端口2 ... 端口n
F_DEBUG_X_PORTS_RM()
{
    #
    for n in $@
    do
        sed -i -E "/^${n}$/d"  ${DEBUG_X_PORTS_FILE}
    done
}



# 随机端口生成器
# 用法： F_GEN_RANDOM_PORT
F_GEN_RANDOM_PORT()
{
    F_PORT_MIN=${DEBUG_RANDOM_PORT_MIN}
    F_PORT_MAX=${DEBUG_RANDOM_PORT_MAX}
    while true
    do
        F_RANDOM_PORT=$(expr $(date +%N) % $[${F_PORT_MAX} - ${F_PORT_MIN} + 1] + ${F_PORT_MIN})
        # 搜索服务清单文件
        if [[ $(grep -q ${F_RANDOM_PORT} ${SERVICE_LIST_FILE}; echo $?) -eq 0 ]]; then
            continue
        else
            if [[ ! -f ${DEBUG_X_PORTS_FILE} ]]; then
                touch  ${DEBUG_X_PORTS_FILE}
            fi
            #
            if [[ $(grep -q ${F_RANDOM_PORT} ${DEBUG_X_PORTS_FILE}; echo $?) -eq 0 ]]; then
                continue
            fi
        fi
        # 
        break
    done
    #
    echo ${F_RANDOM_PORT} | tee -a  ${DEBUG_X_PORTS_FILE}
    return 0
}



# 端口冲突检查
# 用法：F_PROJECT_LIST_PORT_CONFLICT  [{端口号}]
# 返回 0，代表冲突
F_PROJECT_LIST_PORT_CONFLICT()
{
    F_C_PORT=$1
    F_C_NUM=$(grep  ":${F_C_PORT}"  ${SERVICE_LIST_FILE}  |  wc -l)
    if [[ ${F_C_NUM} -gt 1 ]]; then
        # 冲突
        return 0
    else
        return 1
    fi
}



# DOCKER_FULL_CMD执行
# 用法：F_FUCK
F_FUCK()
{
    if [ "x${FUCK}" = "xyes" -o "x${FUCK}" = "xfuck" ]; then
        if [[ ${SERVICE_OPERATION} == 'rm' ]] && [[ ${SERVICE_OPERATION} == 'modify' ]]; then
            # 保存服务端口备用
            PORTS_RM=''
            while read P_LINE
            do
                PORTS_RM="${PORTS_RM} $(F_SEARCH_ONLINE_SERVICE_PUBLISH_PORTS  ${P_LINE})"
            done < ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
        fi
        #
        echo "正在执行以下指令："
        echo "${DOCKER_FULL_CMD}"
        echo "${DOCKER_FULL_CMD}" | bash
        SH_ERROR_CODE=$?
        case ${SERVICE_OPERATION} in
            create|modify|update|rollback|scale)
                if [[ ${SH_ERROR_CODE} -eq 0 ]]; then
                    ERROR_CODE=50
                    echo "${SERVICE_X_NAME} : 成功"
                    echo "${SERVICE_X_NAME} : 成功" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    # 删除端口
                    F_DEBUG_X_PORTS_RM  $(echo ${PORTS_RM})
                else
                    ERROR_CODE=54
                    echo "${SERVICE_X_NAME} : 失败"
                    echo "${SERVICE_X_NAME} : 失败" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                fi
                ;;
            rm|status|detail)
                if [[ ${SH_ERROR_CODE} -eq 0 ]]; then
                    ERROR_CODE=50
                    echo "${SERVICE_X_NAME} : 成功"
                    while read R_LINE
                    do
                        echo "${R_LINE} : 成功" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                        # 删除端口
                        F_DEBUG_X_PORTS_RM  $(echo ${PORTS_RM})
                    done < ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
                else
                    ERROR_CODE=54
                    echo "${SERVICE_X_NAME} : 失败"
                    while read R_LINE
                    do
                        echo "${R_LINE} : 失败" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    done < ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
                fi
                ;;
            *)
                echo -e "\n猪猪侠警告：未定义的集群类型\n"
                return 52
                ;;
        esac
        #
    else
        echo '完整命令如下，请拷贝到命令行运行，或使用【-F|--fuck】参数运行：'
        echo  ${DOCKER_FULL_CMD}
    fi
    #echo ''
}



# 参数检查
TEMP=`getopt -o hlL:FcmubSrsdDt:T:n:GV:aM:  -l help,list,list-run:,fuck,create,modify,update,rollback,scale,rm,status,detail,debug,tag:,TAG:,number:,gray,release-version:,all-release,mode: -- "$@"`
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
            #cat  "${SERVICE_LIST_FILE}"
            sed  -E  -e '/^\s*$/d'  -e '/^##.*$/d'  -e '/---/d'  -e '/^#.*PRIORITY/d'  ${SERVICE_LIST_FILE}  > /tmp/docker-cluster-service-list.txt
            ${FORMAT_TABLE_SH}  --delimeter '|'  --file /tmp/docker-cluster-service-list.txt
            exit
            ;;
        -L|--list-run)
            case $2 in
                swarm)
                    export DOCKER_HOST=${SWARM_DOCKER_HOST}
                    docker service ls
                    ;;
                k8s)
                    K8S_NAMESAPCE=${K8S_NAMESAPCE:-'default'}
                    kubectl get services --all
                    ;;
                compose)
                    echo -e "\n猪猪侠警告：此集群不支持\n"
                    exit 51
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未定义的集群类型\n"
                    exit 52
                    ;;
            esac
            exit
            ;;
        -F|--fuck)
            FUCK='yes'
            shift
            ;;
        -c|--create)
            if [ -z "${SERVICE_OPERATION}" ]; then
                SERVICE_OPERATION='create'
            else
                echo -e "\n猪猪侠警告：主要参数太多^_^\n"
                exit 51
            fi
            shift
            ;;
        -m|--modify)
            if [ -z "${SERVICE_OPERATION}" ]; then
                SERVICE_OPERATION='modify'
            else
                echo -e "\n猪猪侠警告：主要参数太多^_^\n"
                exit 51
            fi
            shift
            ;;
        -u|--update)
            if [ -z "${SERVICE_OPERATION}" ]; then
                SERVICE_OPERATION='update'
            else
                echo -e "\n猪猪侠警告：主要参数太多^_^\n"
                exit 51
            fi
            shift
            ;;
        -b|--rollback)
            if [ -z "${SERVICE_OPERATION}" ]; then
                SERVICE_OPERATION='rollback'
            else
                echo -e "\n猪猪侠警告：主要参数太多^_^\n"
                exit 51
            fi
            shift
            ;;
        -S|--scale)
            if [ -z "${SERVICE_OPERATION}" ]; then
                SERVICE_OPERATION='scale'
            else
                echo -e "\n猪猪侠警告：主要参数太多^_^\n"
                exit 51
            fi
            shift
            ;;
        -r|--rm)
            if [ -z "${SERVICE_OPERATION}" ]; then
                SERVICE_OPERATION='rm'
            else
                echo -e "\n猪猪侠警告：主要参数太多^_^\n"
                exit 51
            fi
            shift
            ;;
        -s|--status)
            if [ -z "${SERVICE_OPERATION}" ]; then
                SERVICE_OPERATION='status'
            else
                echo -e "\n猪猪侠警告：主要参数太多^_^\n"
                exit 51
            fi
            shift
            ;;
        -d|--detail)
            if [ -z "${SERVICE_OPERATION}" ]; then
                SERVICE_OPERATION='detail'
            else
                echo -e "\n猪猪侠警告：主要参数太多^_^\n"
                exit 51
            fi
            shift
            ;;
        -D|--debug)
            DEBUG='YES'
            shift
            ;;
        -t|--tag)
            LIKE_THIS_TAG=$2
            shift 2
            ;;
        -T|--TAG)
            THIS_TAG=$2
            shift 2
            ;;
        -n|--number)
            POD_REPLICAS_NEW=$2
            shift 2
            grep -q '^[[:digit:]]\+$' <<< ${POD_REPLICAS_NEW}
            if [ $? -ne 0 ]; then
                echo '参数：<副本数> 必须为整数！'
                exit 51
            fi
            ;;
        -G|--gray)
            GRAY_TAG="gray"
            shift
            ;;
        -V|--release-version)
            RELEASE_VERSION=$2
            shift 2
            ;;
        -a|--all-release)
            ALL_RELEASE='YES'
            shift
            ;;
        -M|--mode)
            SH_RUN_MODE=$2
            shift 2
            # 参数
            case ${SH_RUN_MODE} in
                normal|function)
                    # OK
                    ;;
                *)
                    echo -e "\n猪猪侠警告：参数错误，-M|--mode 的参数值只能是：normal|function\n"
                    exit 51
                    ;;
            esac
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


# 至少要一个主要参数
if [ -z ${SERVICE_OPERATION} ]; then
    echo -e "\n猪猪侠警告：缺少主要参数！请查看帮助【$0 --help】\n"
    exit 51
fi


# 用户信息
if [[ -z ${MY_XINGMING} ]]; then
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
fi


# 建立base目录
[ -d "${LOG_HOME}" ] || mkdir -p "${LOG_HOME}"
[ -d "${YAML_BASE}" ] || mkdir -p "${YAML_BASE}"


# 删除空行
#sed -i '/^\s*$/d' ${SERVICE_LIST_FILE}
## 删除行中的空格,markdown文件不要这样
#sed -i 's/[ \t]*//g'  ${SERVICE_LIST_FILE}



# 创建服务清单
# 即：${SERVICE_LIST_FILE_TMP}
#
> ${SERVICE_LIST_FILE_TMP}
#
if [ $# -eq 0 ]; then
    # 无参数
    cp ${SERVICE_LIST_FILE}  ${SERVICE_LIST_FILE_TMP}
else
    # 有参数
    for i in $@
    do
        #
        GET_IT=''
        while read LINE
        do
            # 跳过以#开头的行或空行
            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
            #
            SERVICE_NAME=`echo $LINE | awk -F '|' '{print $2}'`
            SERVICE_NAME=`echo ${SERVICE_NAME}`
            if [[ ${SERVICE_NAME} =~ ^$i$ ]]; then
                echo $LINE >> ${SERVICE_LIST_FILE_TMP}
                GET_IT='YES'
            fi
        done < ${SERVICE_LIST_FILE}
        #
        if [[ ${GET_IT} != 'YES' ]]; then
            echo -e "\n猪猪侠警告：服务【$i】正则不匹配服务列表【${SERVICE_LIST_FILE}】中的任何服务名，请检查！\n"
            exit 51
        fi
    done
    
fi
#
# 删除无关行
#sed  -i  -E  -e '/^\s*$/d'  -e '/^#.*$/d'  -e 's/[ \t]*//g'  ${SERVICE_LIST_FILE_TMP}
sed  -i  -E  -e '/^\s*$/d'  -e '/^#.*$/d'  ${SERVICE_LIST_FILE_TMP}
# 优先级排序
> ${SERVICE_LIST_FILE_TMP}.sort
for i in  `awk -F '|' '{split($9,a," ");print NR,a[1]}' ${SERVICE_LIST_FILE_TMP}  |  sort -n -k 2 |  awk '{print $1}'`
do
    awk "NR=="$i'{print}' ${SERVICE_LIST_FILE_TMP}  >> ${SERVICE_LIST_FILE_TMP}.sort
done
cp  ${SERVICE_LIST_FILE_TMP}.sort  ${SERVICE_LIST_FILE_TMP}
# 加表头
sed -i  '1i#| **服务名** | **DOCKER镜像名** | **POD副本数** | **容器PORTS** | **JAVA选项** | **容器ENVS** | **容器CMDS** | **优先级** | **集群** | **部署位置** | **主机名** |'  ${SERVICE_LIST_FILE_TMP}
# 屏显
if [[ ${SH_RUN_MODE} == 'normal' ]]; then
    echo -e "${ECHO_NORMAL}========================= 开始发布 =========================${ECHO_CLOSE}"  #--- 60 (60-50-40)
    echo -e "\n【${SH_NAME}】待${SERVICE_OPERATION}服务清单："
    ${FORMAT_TABLE_SH}  --delimeter '|'  --file ${SERVICE_LIST_FILE_TMP}
    #echo -e "\n"
fi



# 干
> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
NUM=0
#
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    SERVICE_NAME=`echo ${LINE} | cut -d \| -f 2`
    SERVICE_NAME=`echo ${SERVICE_NAME}`
    #
    DOCKER_IMAGE_NAME=`echo ${LINE} | cut -d \| -f 3`
    DOCKER_IMAGE_NAME=`eval echo ${DOCKER_IMAGE_NAME}`    #--- 用eval将配置文件中项的变量转成值，下同
    #
    POD_REPLICAS=`echo ${LINE} | cut -d \| -f 4`
    POD_REPLICAS=`eval echo ${POD_REPLICAS}`
    #
    CONTAINER_PORTS=`echo ${LINE} | cut -d \| -f 5`
    CONTAINER_PORTS=`eval echo ${CONTAINER_PORTS}`
    #
    JAVA_OPTIONS=`echo ${LINE} | cut -d \| -f 6`
    JAVA_OPTIONS=`eval echo ${JAVA_OPTIONS}`
    JAVA_OPTIONS=${JAVA_OPTIONS//'~'/${HOME}}
    #
    CONTAINER_ENVS=`echo ${LINE} | cut -d \| -f 7`
    CONTAINER_ENVS=`eval echo ${CONTAINER_ENVS}`
    CONTAINER_ENVS=${CONTAINER_ENVS//'~'/${HOME}}
    #
    CONTAINER_CMDS=`echo ${LINE} | cut -d \| -f 8`
    CONTAINER_CMDS=`eval echo ${CONTAINER_CMDS}`
    CONTAINER_CMDS=${CONTAINER_CMDS//'~'/${HOME}}
    #
    # 9
    #
    CLUSTER=`echo ${LINE} | cut -d \| -f 10`
    CLUSTER=`eval echo ${CLUSTER}`
    #
    DEPLOY_PLACEMENT=`echo ${LINE} | cut -d \| -f 11`
    DEPLOY_PLACEMENT=`eval echo ${DEPLOY_PLACEMENT}`
    #
    HOSTNAME=`echo ${LINE} | cut -d \| -f 12`
    HOSTNAME=`eval echo ${HOSTNAME}`
    #
    # 运行环境
    F_SET_RUN_ENV
    if [[ $? -ne 0 ]]; then
        exit 52
    fi

    
    # RUN
    DOCKER_FULL_CMD=""
    # 目录
    case ${CLUSTER} in
        swarm)
            echo
            ;;
        k8s)
            YAML_HOME="${YAML_BASE}/${SERVICE_NAME}"
            [ -d "${YAML_HOME}" ] || mkdir -p "${YAML_HOME}"
            ;;
        compose)
            YAML_HOME="${YAML_BASE}/${SERVICE_NAME}"
            [ -d "${YAML_HOME}" ] || mkdir -p "${YAML_HOME}"
            ;;
        *)
            echo -e "\n猪猪侠警告：未定义的集群类型\n"
            exit 52
            ;;
    esac
    #
    #
    let NUM=${NUM}+1
    echo ''
    echo -e "${ECHO_NORMAL}# ----------------------------------------------------------${ECHO_CLOSE}"
    echo -e "${ECHO_NORMAL}# ${NUM}: ${LINE}${ECHO_CLOSE}"
    echo -e "${ECHO_NORMAL}# ----------------------------------------------------------${ECHO_CLOSE}"
    #
    # operation
    case "${SERVICE_OPERATION}" in
        create|modify)
            #
            DOCKER_SERVICE_RM="echo"
            #
            if [[ -n ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                # 注释掉此块，可以启用正则表达式
                if [[ ! V_${RELEASE_VERSION} =~ ^V_[0-9a-z]+([_\.\-]?[0-9a-z]+)*$ ]]; then
                    echo -e "\n猪猪侠警告：在【${SERVICE_OPERATION}】操作时，发布版本号不能使用正则表达式，只能使用字符【0-9a-z._-】，且特殊字符不能出现在版本号的头部或尾部\n"
                    ERROR_CODE=51
                    exit 51
                else
                    # 替换【.】为【_】，服务名中不能有【.】
                    RELEASE_VERSION=${RELEASE_VERSION//./_}
                fi
                #
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}-G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            elif [[ -z ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            else
                SERVICE_X_NAME="${SERVICE_NAME}"
            fi
            #
            # 是否运行中
            F_ONLINE_SERVICE_SEARCH  ${SERVICE_X_NAME}  ${CLUSTER} > /dev/null
            [[ $? -eq 0 ]] && SERVICE_RUN_STATUS='YES' || SERVICE_RUN_STATUS='NO'
            #
            if [[ ${SERVICE_RUN_STATUS} == YES ]]; then
                # 运行中
                case "${SERVICE_OPERATION}" in
                    create)
                        echo "${SERVICE_X_NAME} : 失败，服务已在运行中"
                        echo "${SERVICE_X_NAME} : 失败，服务已在运行中" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                        ERROR_CODE=53
                        continue
                        ;;
                    modify)
                        case "${CLUSTER}" in
                            swarm)
                                DOCKER_SERVICE_RM="docker service rm ${SERVICE_X_NAME}"
                                ;;
                            k8s)
                                DOCKER_SERVICE_RM="echo"
                                ;;
                            compose)
                                DOCKER_SERVICE_RM="docker-compose down"
                                ;;
                            *)
                                echo -e "\n猪猪侠警告：未定义的集群类型\n"
                                exit 52
                                ;;
                        esac
                        ;;
                esac
            fi


            # 生成yaml文件
            case "${CLUSTER}" in
                swarm)
                    echo
                    ;;
                k8s)
                    F_K8S_MODEL_YAML > ${YAML_HOME}/${SERVICE_X_NAME}.yaml
                    ;;
                compose)
                    F_DOCKER_COMPOSE_MODEL_YAML > ${YAML_HOME}/docker-compose.yaml
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未定义的集群类型\n"
                    exit 52
                    ;;
            esac


            # 0 组装日志
            case "${CLUSTER}" in
                swarm)
                    DOCKER_LOG_PUB_OK=$( eval echo ${DOCKER_LOG_PUB} )
                    DOCKER_LOG_PUB_OK=${DOCKER_LOG_PUB_OK//'~'/${HOME}}
                    ;;
                k8s)
                    echo
                    ;;
                compose)
                    echo
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未定义的集群类型\n"
                    exit 52
                    ;;
            esac


            # 0 组装 DOCKER 公共ARG
            case "${CLUSTER}" in
                swarm)
                    DOCKER_ARG_PUB_OK=""
                    DOCKER_ARG_PUB_OK="--network ${NETWORK_SWARM}  ${DOCKER_ARG_PUB_OK}"
                    #
                    DOCKER_ARG_PUB_FILE=`eval echo ${DOCKER_ARG_PUB_FILE}`
                    DOCKER_ARG_PUB_FILE=${DOCKER_ARG_PUB_FILE//'~'/${HOME}}
                    if [ -f "${DOCKER_ARG_PUB_FILE}" ]; then
                        # 存在
                        while read LINE
                        do
                            # 跳过以#开头的行或空行
                            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
                            #
                            LINE=$( eval echo ${LINE} )
                            LINE=${LINE//'~'/${HOME}}
                            if [[ "${LINE}" =~ ^[a-zA-Z-]+ ]]; then
                                DOCKER_ARG_PUB_FILE_SET=$( echo ${LINE} | sed 's/\"//g' )
                                DOCKER_ARG_PUB_OK="${DOCKER_ARG_PUB_FILE_SET}  ${DOCKER_ARG_PUB_OK}"
                            fi
                        done < "${DOCKER_ARG_PUB_FILE}"
                    fi
                    ;;
                k8s)
                    echo
                    ;;
                compose)
                    echo
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未定义的集群类型\n"
                    exit 52
                    ;;
            esac


            # 0 组装hosts - 从公共文件
            CONTAINER_HOSTS_PUB_OK=""
            #
            CONTAINER_HOSTS_PUB_FILE=`eval echo ${CONTAINER_HOSTS_PUB_FILE}`
            CONTAINER_HOSTS_PUB_FILE=${CONTAINER_HOSTS_PUB_FILE//'~'/${HOME}}
            if [ -f "${CONTAINER_HOSTS_PUB_FILE}" ]; then
                while read LINE
                do
                    # 跳过以#开头的行或空行
                    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
                    #
                    LINE=$( eval echo ${LINE} )
                    LINE=${LINE//'~'/${HOME}}
                    if [[ "${LINE}" =~ ^[1-9]+ ]]; then
                        HOST_IP=$(   echo ${LINE} | awk '{print $1}' )
                        HOST_NAME=$( echo ${LINE} | awk '{print $2}' )
                        #
                        case "${CLUSTER}" in
                            swarm)
                                CONTAINER_HOSTS_PUB_OK="${CONTAINER_HOSTS_PUB_OK}  --host ${HOST_NAME}:${HOST_IP}"
                                ;;
                            k8s)
                                sed -i "/^      hostAliases:/a\      - ip: ${HOST_IP}\n        hostnames:\n        - ${HOST_NAME}"  ${YAML_HOME}/${SERVICE_X_NAME}.yaml
                                ;;
                            compose)
                                sed -i "/^    extra_hosts:/a\      - \"${HOST_NAME}:${HOST_IP}\""  ${YAML_HOME}/docker-compose.yaml
                                ;;
                            *)
                                echo -e "\n猪猪侠警告：未定义的集群类型\n"
                                exit 52
                        esac
                    fi
                done < "${CONTAINER_HOSTS_PUB_FILE}"
            fi


            # 3 组装image
            DOCKER_IMAGE_VER=${DOCKER_IMAGE_VER:-'latest'}
            # 命令参数指定版本
            if [ ! -z "${THIS_TAG}" ]; then
                # 完全匹配服务镜像
                F_SEARCH_IMAGE_TAG  ${SERVICE_NAME}  ${THIS_TAG}
                if [ $? -ne 0 ]; then
                    echo "${SERVICE_NAME} : 失败，镜像版本【${THIS_TAG}】未找到"
                    echo "${SERVICE_NAME} : 失败，镜像版本【${THIS_TAG}】未找到" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
                DOCKER_IMAGE_VER="${THIS_TAG}"
                #
            elif [ ! -z "${LIKE_THIS_TAG}" ]; then
                # LIKE匹配镜像最新的一个
                ${DOCKER_IMAGE_SEARCH_SH}  --tag ${LIKE_THIS_TAG}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-image-search.${SERVICE_OPERATION}  ${SERVICE_NAME}
                search_r=`cat ${LOG_HOME}/${SH_NAME}-image-search.${SERVICE_OPERATION} | awk '{print $3}'`
                if [ "x${search_r}" = "x" ]; then
                    echo "${SERVICE_NAME} : 失败，镜像版本【%${LIKE_THIS_TAG}%】未找到"
                    echo "${SERVICE_NAME} : 失败，镜像版本【%${LIKE_THIS_TAG}%】未找到" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
                DOCKER_IMAGE_VER=`cat ${LOG_HOME}/${SH_NAME}-image-search.${SERVICE_OPERATION} | cut -d ' ' -f 3`
                #
            else
                # 默认镜像版本
                F_SEARCH_IMAGE_TAG  ${SERVICE_NAME}  ${DOCKER_IMAGE_VER}
                if [ $? -ne 0 ]; then
                    echo "${SERVICE_NAME} : 失败，镜像版本【${DOCKER_IMAGE_VER}】未找到"
                    echo "${SERVICE_NAME} : 失败，镜像版本【${DOCKER_IMAGE_VER}】未找到" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
            fi
            #
            DOCKER_IMAGE_FULL_URL="${DOCKER_IMAGE_BASE}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VER}"
            #
            case ${CLUSTER} in
                swarm)
                    echo ""
                    ;;
                k8s)
                    sed -i "s%^        image:.*$%        image: ${DOCKER_IMAGE_FULL_URL}%"  "${YAML_HOME}/${SERVICE_X_NAME}.yaml"
                    ;;
                compose)
                    sed -i "s%^    image:.*$%    image: ${DOCKER_IMAGE_FULL_URL}%"  "${YAML_HOME}/docker-compose.yaml"
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未定义的集群类型\n"
                    exit 52
            esac


            # 4 副本数
            POD_REPLICAS=${POD_REPLICAS_NEW:-"${POD_REPLICAS}"}
            #
            case ${CLUSTER} in
                swarm)
                    echo ""
                    ;;
                k8s)
                    sed -i "s/^  replicas:.*$/  replicas: ${POD_REPLICAS}/"  "${YAML_HOME}/${SERVICE_X_NAME}.yaml"
                    ;;
                compose)
                    echo "compose之【POD_REPLICAS】暂时不弄"
                    #sed -i 
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未定义的集群类型\n"
                    exit 52
            esac


            # 5 组装port
            CONTAINER_PORTS_OK=''
            DEBUG_X_PORT=''
            DEBUG_X_PORTS=''
            #
            CONTAINER_PORTS_NUM=`echo ${CONTAINER_PORTS} | grep -o , | wc -l`
            for ((i=CONTAINER_PORTS_NUM; i>=0; i--))
            do
                # 无端口
                if [[ -z ${CONTAINER_PORTS} ]]; then
                    echo "端口为空，故不会开放任何外部端口"
                    break
                fi
                #
                FIELD=$((i+1))
                CONTAINER_PORTS_SET=`echo ${CONTAINER_PORTS} | cut -d , -f ${FIELD}`
                CONTAINER_PORTS_SET_outside=`echo ${CONTAINER_PORTS} | cut -d , -f ${FIELD} | cut -d : -f 1`
                CONTAINER_PORTS_SET_outside=`echo ${CONTAINER_PORTS_SET_outside}`
                CONTAINER_PORTS_SET_inside=`echo ${CONTAINER_PORTS} | cut -d , -f ${FIELD} | cut -d : -f 2`
                CONTAINER_PORTS_SET_inside=`echo ${CONTAINER_PORTS_SET_inside}`
                #
                if [[ -z ${CONTAINER_PORTS_SET_inside} ]]; then
                    echo -e "\n猪猪侠警告：配置文件错误，请检查【CONTAINER_PORTS】。inside端口不能为空\n"
                    exit 52
                fi
                #
                # dev环境开放Debug端口
                if [[ ${RUN_ENV} == 'dev' ]] || [[ ${DEBUG} == 'YES' ]]; then
                    case ${GRAY_TAG} in
                        gray)
                            # 灰度
                            # 改用随机端口
                            # 这个是为开发人员另外开放的外部端口，便于开发调试
                            CONTAINER_PORTS_SET_outside=$(F_GEN_RANDOM_PORT)
                            echo -e "\n【${RUN_ENV}】环境，调试端口映射为：【外：${CONTAINER_PORTS_SET_outside}】-->【内：${CONTAINER_PORTS_SET_inside}】\n"
                            ;;
                        normal)
                            # 非灰度
                            if [[ -n ${RELEASE_VERSION} ]]; then
                                # 有版本号
                                # 改用随机端口
                                # 这个是为开发人员另外开放的外部端口，便于开发调试
                                CONTAINER_PORTS_SET_outside=$(F_GEN_RANDOM_PORT)
                                echo -e "\n【${RUN_ENV}】环境，调试端口映射为：【外：${CONTAINER_PORTS_SET_outside}】-->【内：${CONTAINER_PORTS_SET_inside}】\n"
                            else
                                # 无版本号
                                if [[ -z ${CONTAINER_PORTS_SET_outside} ]]; then
                                    # 无外部端口
                                    # 如果不重复，则默认将内部端口等值发布出来
                                    # 如果重复，则改用随机端口
                                    # 这个是为开发人员另外开放的外部端口，便于开发调试
                                    #
                                    F_PROJECT_LIST_PORT_CONFLICT  ${CONTAINER_PORTS_SET_inside}
                                    if [[ $? -eq 0 ]]; then
                                        # 端口冲突
                                        # 改用随机端口
                                        CONTAINER_PORTS_SET_outside=$(F_GEN_RANDOM_PORT)
                                    else
                                        CONTAINER_PORTS_SET_outside=${CONTAINER_PORTS_SET_inside}
                                    fi
                                    #
                                    echo -e "\n【${RUN_ENV}】环境，调试端口映射为：【外：${CONTAINER_PORTS_SET_outside}】-->【内：${CONTAINER_PORTS_SET_inside}】\n"
                                else
                                    # 有外部端口
                                    # 保持配置文件指定的端口
                                    echo -e "\n【${RUN_ENV}】环境，调试端口映射为：【外：${CONTAINER_PORTS_SET_outside}】-->【内：${CONTAINER_PORTS_SET_inside}】\n"
                                fi
                            fi
                            #
                            ;;
                        *)
                            echo -e "\n猪猪侠警告：未定义的灰度标志【${GRAY_TAG}】\n"
                            exit 52
                            ;;
                    esac
                    # 保存端口以备用
                    DEBUG_X_PORT=${CONTAINER_PORTS_SET_outside}
                    DEBUG_X_PORTS="${DEBUG_X_PORTS},${DEBUG_X_PORT}"
                    DEBUG_X_PORTS=$(echo ${DEBUG_X_PORTS})
                    DEBUG_X_PORTS=${DEBUG_X_PORTS#,}
                    DEBUG_X_PORTS=${DEBUG_X_PORTS%,}
                fi
                #
                # 组装
                if [[ -n ${CONTAINER_PORTS_SET_outside} ]]; then
                    case "${CLUSTER}" in
                        swarm)
                            CONTAINER_PORTS_SET="--publish ${CONTAINER_PORTS_SET_outside}:${CONTAINER_PORTS_SET_inside}"
                            CONTAINER_PORTS_OK="${CONTAINER_PORTS_OK} ${CONTAINER_PORTS_SET}"
                            ;;
                        k8s)
                            sed -i "/^        ports:/a\        - name: tcp-${CONTAINER_PORTS_SET_outside}\n          containerPort: ${CONTAINER_PORTS_SET_outside}\n          protocol: TCP"  ${YAML_HOME}/${SERVICE_X_NAME}.yaml
                            sed -i "/^  ports:/a\  - name: svc-${CONTAINER_PORTS_SET_outside}\n    port: ${CONTAINER_PORTS_SET_outside}\n    protocol: TCP\n    targetPort: tcp-${CONTAINER_PORTS_SET_outside}\n    nodePort: ${CONTAINER_PORTS_SET_inside}"  ${YAML_HOME}/${SERVICE_X_NAME}.yaml
                            ;;
                        compose)
                            sed -i "/^    ports:/a\      - ${CONTAINER_PORTS_SET_outside}:${CONTAINER_PORTS_SET_inside}"  ${YAML_HOME}/docker-compose.yaml
                            ;;
                        *)
                            echo -e "\n猪猪侠警告：未定义的集群类型\n"
                            exit 52
                            ;;
                    esac
                fi
            done


            # 6 组装 JAVA ENV（JAVA_OPTIONS）
            JAVA_OPTIONS_OK=''
            #
            # - 从公共文件
            JAVA_OPTIONS_PUB_OK_V=""
            #
            JAVA_OPTIONS_PUB_FILE=`eval echo ${JAVA_OPTIONS_PUB_FILE}`
            JAVA_OPTIONS_PUB_FILE=${JAVA_OPTIONS_PUB_FILE//'~'/${HOME}}
            if [ -f "${JAVA_OPTIONS_PUB_FILE}" ]; then
                # 存在
                while read LINE
                do
                    # 跳过以#开头的行或空行
                    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
                    #
                    LINE=$( eval echo ${LINE} )
                    LINE=${LINE//'~'/${HOME}}
                    if [[ "${LINE}" =~ ^[a-zA-Z-]+ ]]; then
                        JAVA_OPTIONS_PUB_FILE_SET=$( echo ${LINE} | sed 's/\"//g' )
                        JAVA_OPTIONS_PUB_OK_V="${JAVA_OPTIONS_PUB_FILE_SET}  ${JAVA_OPTIONS_PUB_OK_V}"
                    fi
                done < "${JAVA_OPTIONS_PUB_FILE}"
            fi
            #
            # - 从配置文件
            JAVA_OPTIONS_OK_V=""
            #
            JAVA_OPTIONS_NUM=`echo ${JAVA_OPTIONS} | grep -o , | wc -l`
            for ((i=JAVA_OPTIONS_NUM; i>=0; i--))
            do
                if [ "x${JAVA_OPTIONS}" = 'x' ]; then
                    break
                fi
                FIELD=$((i+1))
                JAVA_OPTIONS_SET=`echo ${JAVA_OPTIONS} | cut -d , -f ${FIELD}`
                #
                if [[ "${JAVA_OPTIONS_SET}" =~ ^JAVA_OPT_FROM_FILE.* ]]; then
                    # 从指定文件组装
                    JAVA_OPTIONS_SET_v=`echo ${JAVA_OPTIONS_SET} | cut -d '=' -f 2`
                    JAVA_OPTIONS_SET_v=`echo ${JAVA_OPTIONS_SET_v}`
                    JAVA_OPTIONS_FILE=${JAVA_OPTIONS_SET_v}
                    if [ -f "${JAVA_OPTIONS_FILE}" ]; then
                        # 存在
                        while read LINE
                        do
                            # 跳过以#开头的行或空行
                            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
                            #
                            LINE=$( eval echo ${LINE} )
                            LINE=${LINE//'~'/${HOME}}
                            if [[ "${LINE}" =~ ^[a-zA-Z-]+ ]]; then
                                JAVA_OPTIONS_FILE_SET=$( echo ${LINE} | sed 's/\"//g' )
                                JAVA_OPTIONS_OK_V="${JAVA_OPTIONS_FILE_SET}  ${JAVA_OPTIONS_OK_V}"
                            fi
                        done < "${JAVA_OPTIONS_FILE}"
                    else
                        # 不存在
                        echo -e "\n猪猪侠警告：服务【${SERVICE_NAME}】的配置文件【${JAVA_OPTIONS_FILE}】不存在！\n"
                        echo "跳过，配置文件错误"
                        echo "${SERVICE_NAME} : 跳过，配置文件错误" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                        ERROR_CODE=52
                        continue
                    fi
                else
                    # 直接组装
                    JAVA_OPTIONS_OK_V="${JAVA_OPTIONS_SET}  ${JAVA_OPTIONS_OK_V}"
                fi
            done
            #
            # 加上JAVA_OPTIONS_PUB
            JAVA_OPTIONS_OK_V="${JAVA_OPTIONS_PUB_OK_V}  ${JAVA_OPTIONS_OK_V}"
            #
            #
            JAVA_OPTIONS_OK_V=$( echo ${JAVA_OPTIONS_OK_V} )
            if [ ! -z "${JAVA_OPTIONS_OK_V}" ]; then
                #
                case "${CLUSTER}" in
                    swarm)
                        JAVA_OPTIONS_OK="--env JAVA_OPTIONS=\"${JAVA_OPTIONS_OK_V}\""
                        ;;
                    k8s)
                        sed -i "/        env:/a\        - name: JAVA_OPTIONS\n          value: ${JAVA_OPTIONS_OK_V}"  ${YAML_HOME}/${SERVICE_X_NAME}.yaml
                        ;;
                    compose)
                        sed -i "/^    environment:/a\      JAVA_OPTIONS: ${JAVA_OPTIONS_OK_V}"  ${YAML_HOME}/docker-compose.yaml
                        ;;
                    *)
                        echo -e "\n猪猪侠警告：未定义的集群类型\n"
                        exit 52
                        ;;
                esac
            fi
            

            # 7 组装ENV
            #
            # - 灰度用ENV
            CONTAINER_ENVS_GRAY_OK="  --env GRAY_TAG=${GRAY_TAG}  --env RELEASE_VERSION=${RELEASE_VERSION}  --env SERVICE_X_NAME=${SERVICE_X_NAME}  --env DEBUG_X_PORTS=${DEBUG_X_PORTS}"
            #
            # - 从公共文件
            CONTAINER_ENVS_PUB_OK=""
            #
            CONTAINER_ENVS_OK=""
            CONTAINER_ENVS_PUB_FILE=`eval echo ${CONTAINER_ENVS_PUB_FILE}`
            CONTAINER_ENVS_PUB_FILE=${CONTAINER_ENVS_PUB_FILE//'~'/${HOME}}
            if [ -f "${CONTAINER_ENVS_PUB_FILE}" ]; then
                # 存在
                F_ENVS_FROM_FILE  "${CONTAINER_ENVS_PUB_FILE}"  "${CLUSTER}"
            fi
            CONTAINER_ENVS_PUB_OK=$( echo ${CONTAINER_ENVS_OK} )
            CONTAINER_ENVS_OK=""
            #
            # - 从配置文件
            CONTAINER_ENVS_OK=''
            #
            CONTAINER_ENVS_NUM=`echo ${CONTAINER_ENVS} | grep -o , | wc -l`
            for ((i=CONTAINER_ENVS_NUM; i>=0; i--))
            do
                if [ "x${CONTAINER_ENVS}" = 'x' ]; then
                    break
                fi
                FIELD=$((i+1))
                CONTAINER_ENVS_SET=`echo ${CONTAINER_ENVS} | cut -d , -f ${FIELD}`
                #
                CONTAINER_ENVS_SET_n=`echo ${CONTAINER_ENVS} | cut -d , -f ${FIELD} | cut -d = -f 1`
                CONTAINER_ENVS_SET_n=`echo ${CONTAINER_ENVS_SET_n}`
                #
                CONTAINER_ENVS_SET_v=`echo ${CONTAINER_ENVS} | cut -d , -f ${FIELD} | cut -d = -f 2`
                CONTAINER_ENVS_SET_v=`echo ${CONTAINER_ENVS_SET_v}`
                # 是否为空
                if [ -z "${CONTAINER_ENVS_SET_n}" -o -z "${CONTAINER_ENVS_SET_v}" ]; then
                    echo -e "\n猪猪侠警告：服务【${SERVICE_NAME}】的ENV参数等号两边不能为空！\n"
                    echo "跳过，配置文件错误"
                    echo "${SERVICE_NAME} : 跳过，配置文件错误" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=52
                    continue
                fi
                # 是否为文件
                if [ "${CONTAINER_ENVS_SET_n}" = 'ENVS_FROM_FILE' ]; then
                    # 从指定文件组装
                    CONTAINER_ENVS_FILE=${CONTAINER_ENVS_SET_v}
                    if [ -f "${CONTAINER_ENVS_FILE}" ]; then
                        # 存在
                        F_ENVS_FROM_FILE  "${CONTAINER_ENVS_FILE}"  "${CLUSTER}"
                    else
                        # 不存在
                        echo -e "\n猪猪侠警告：服务【${SERVICE_NAME}】的ENV文件【${CONTAINER_ENVS_FILE}】不存在！\n"
                        echo "跳过，配置文件错误"
                        echo "${SERVICE_NAME} : 跳过，配置文件错误" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                        ERROR_CODE=52
                        continue
                    fi
                else
                    # 直接组装
                    CONTAINER_ENVS_OK="${CONTAINER_ENVS_OK}  --env ${CONTAINER_ENVS_SET_n}=\"${CONTAINER_ENVS_SET_v}\""
                fi
            done
            #
            CONTAINER_ENVS_OK=$( echo ${CONTAINER_ENVS_OK} )


            # 8 组装CMD
            CONTAINER_CMDS_OK=''
            #
            CONTAINER_CMDS_NUM=`echo ${CONTAINER_CMDS} | grep -o , | wc -l`
            for ((i=CONTAINER_CMDS_NUM; i>=0; i--))
            do
                if [ "x${CONTAINER_CMDS}" = 'x' ]; then
                    break
                fi
                FIELD=$((i+1))
                CONTAINER_CMDS_SET=`echo ${CONTAINER_CMDS} | cut -d , -f ${FIELD}`
                CONTAINER_CMDS_SET=`echo ${CONTAINER_CMDS_SET}`
                if [[ "${CONTAINER_CMDS_SET}" =~ ^CMDS_FROM_FILE.* ]]; then
                    # 从指定文件组装
                    CONTAINER_CMDS_SET_v=`echo ${CONTAINER_CMDS_SET} | cut -d '=' -f 2`
                    CONTAINER_CMDS_SET_v=`echo ${CONTAINER_CMDS_SET_v}`
                    CONTAINER_CMDS_FILE=${CONTAINER_CMDS_SET_v}
                    if [ -f "${CONTAINER_CMDS_FILE}" ]; then
                        # 存在
                        while read LINE
                        do
                            # 跳过以#开头的行或空行
                            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
                            #
                            LINE=$( eval echo ${LINE} )
                            LINE=${LINE//'~'/${HOME}}
                            if [[ "${LINE}" =~ ^[a-zA-Z-]+ ]]; then
                                CONTAINER_CMDS_FILE_SET=$( echo ${LINE} | sed 's/\"//g' )
                                #
                                case ${CLUSTER} in
                                    swarm)
                                        CONTAINER_CMDS_OK="${CONTAINER_CMDS_FILE_SET}; ${CONTAINER_CMDS_OK}"
                                        ;;
                                    k8s)
                                        sed -i "/^        args:/a\        - ${CONTAINER_CMDS_FILE_SET}"  "${YAML_HOME}/${SERVICE_X_NAME}.yaml"
                                        ;;
                                    compose)
                                        sed -i "s/#command:/command:/"  "${YAML_HOME}/docker-compose.yaml"
                                        sed -i "/^    command:/a\      - ${CONTAINER_CMDS_FILE_SET}"  "${YAML_HOME}/docker-compose.yaml"
                                        ;;
                                    *)
                                        echo -e "\n猪猪侠警告：未定义的集群类型\n"
                                        exit 52
                                esac
                            fi
                        done < "${CONTAINER_CMDS_FILE}"
                    else
                        # 不存在
                        echo -e "\n猪猪侠警告：服务【${SERVICE_NAME}】的ENV文件【${CONTAINER_CMDS_FILE}】不存在！\n"
                        echo "跳过，配置文件错误"
                        echo "${SERVICE_NAME} : 跳过，配置文件错误" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                        ERROR_CODE=52
                        continue
                    fi
                else
                    # 直接组装
                    case ${CLUSTER} in
                        swarm)
                            CONTAINER_CMDS_OK="${CONTAINER_CMDS_SET}; ${CONTAINER_CMDS_OK}"
                            ;;
                        k8s)
                            sed -i "/        args:/a\        - ${CONTAINER_CMDS_SET}"  "${YAML_HOME}/${SERVICE_X_NAME}.yaml"
                            ;;
                        compose)
                            sed -i "s/#command:/command:/"  "${YAML_HOME}/docker-compose.yaml"
                            sed -i "/^    command:/a\      - ${CONTAINER_CMDS_SET}"  "${YAML_HOME}/docker-compose.yaml"
                            ;;
                        *)
                            echo -e "\n猪猪侠警告：未定义的集群类型\n"
                            exit 52
                    esac
                fi
            done

            # 9 优先级
            # 前面已经处理

            # 10 集群
            # 前面已经处理

            # 11 部署位置
            # 前面已经处理一部分
            #
            # 12 容器主机名
            if [[ -n ${HOSTNAME} ]]; then
                # 正则校验
                #if [[ ! ${HOSTNAME} =~ ^(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$ ]]; then
                if [[ ! ${HOSTNAME} =~ ^[0-9a-z]([0-9a-z\-]{0,61}[0-9a-z])?(\.[0-9a-z](0-9a-z\-]{0,61}[0-9a-z])?)*$ ]]; then
                    echo -e "\n猪猪侠警告：主机名【${HOSTNAME}】不符合规范\n"
                    exit 52
                fi
                # 直接组装
                case ${CLUSTER} in
                    swarm)
                        HOSTNAME_OK="--hostname ${HOSTNAME}"
                        ;;
                    k8s)
                        sed -i "s/      hostname:.*/      hostname: ${HOSTNAME}/"  "${YAML_HOME}/${SERVICE_X_NAME}.yaml"
                        ;;
                    compose)
                        sed -i "s/    hostname:.*/    hostname: ${HOSTNAME}/"  "${YAML_HOME}/docker-compose.yaml"
                        ;;
                    *)
                        echo -e "\n猪猪侠警告：未定义的集群类型\n"
                        exit 52
                esac
            fi
            #
            DEPLOY_PLACEMENT_LABELS_OK=''
            #
            if [[ ! -z ${DEPLOY_PLACEMENT_LABELS} ]]; then
                case ${CLUSTER} in
                    swarm)
                        for LABEL in ${DEPLOY_PLACEMENT_LABELS}
                        do
                            DEPLOY_PLACEMENT_LABELS_OK="${DEPLOY_PLACEMENT_LABELS_OK}  --label ${LABEL}"
                        done
                        ;;
                    k8s)
                        for LABEL in ${DEPLOY_PLACEMENT_LABELS}
                        do
                            DEPLOY_PLACEMENT_LABEL_K=$(echo ${LABEL} | awk -F '=' '{print $1}')
                            DEPLOY_PLACEMENT_LABEL_V=$(echo ${LABEL} | awk -F '=' '{print $2}')
                            sed -i "/      nodeSelector:/a\        ${DEPLOY_PLACEMENT_LABEL_K}: ${DEPLOY_PLACEMENT_LABEL_V}"  "${YAML_HOME}/${SERVICE_X_NAME}.yaml"
                        done
                        ;;
                    compose)
                        # 不需要
                        echo
                        ;;
                    *)
                        echo -e "\n猪猪侠警告：未定义的集群类型\n"
                        exit 52
                        ;;
                esac
            fi


            # x 特殊处理（最好不要有）
            # ========== 特殊处理START ==========
            # 
            # 
            # ========== 特殊处理END ==========
            

            # END 全部组装
            case ${CLUSTER} in
                swarm)
                    DOCKER_FULL_CMD="${DOCKER_SERVICE_RM}  &&  docker service create  \
                        --name ${SERVICE_X_NAME}  \
                        --replicas ${POD_REPLICAS}  \
                        ${DOCKER_ARG_PUB_OK}  \
                        ${DOCKER_LOG_PUB_OK}  \
                        ${CONTAINER_HOSTS_PUB_OK}  \
                        ${CONTAINER_PORTS_OK}  \
                        ${JAVA_OPTIONS_OK}  \
                        ${CONTAINER_ENVS_GRAY_OK}  \
                        ${CONTAINER_ENVS_PUB_OK}  \
                        ${CONTAINER_ENVS_OK}  \
                        ${DEPLOY_PLACEMENT_LABELS_OK}  \
                        ${HOSTNAME_OK}  \
                        ${DOCKER_IMAGE_FULL_URL}  \
                        ${CONTAINER_CMDS_OK}"
                    ;;
                k8s)
                    DOCKER_FULL_CMD="kubectl apply -f ${YAML_HOME}/${SERVICE_X_NAME}.yaml"
                    ;;
                compose)
                    DOCKER_FULL_CMD="echo  \
                        ; ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                            \"[ ! -d ${DOCKER_COMPOSE_SERVICE_HOME} ] && mkdir -p ${DOCKER_COMPOSE_SERVICE_HOME}\"  \
                        ; rsync -r  -e \"ssh -p ${COMPOSE_SSH_PORT}\"  \
                            ${YAML_HOME}/docker-compose.yaml  \
                            ${COMPOSE_SSH_HOST_OR_WITH_USER}:${DOCKER_COMPOSE_SERVICE_HOME}/  \
                        && ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                            \"cd ${DOCKER_COMPOSE_SERVICE_HOME}  \
                            &&  docker-compose pull  \
                            &&  ${DOCKER_SERVICE_RM}  \
                            &&  docker-compose up -d\"
                       "
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未定义的集群类型\n"
                    exit 52
                    ;;
            esac
            ;;
        update)
            #
            if [[ -n ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                # 注释掉此块，可以启用正则表达式
                if [[ ! V_${RELEASE_VERSION} =~ ^V_[0-9a-z]+([_\.\-]?[0-9a-z]+)*$ ]]; then
                    echo -e "\n猪猪侠警告：在【${SERVICE_OPERATION}】操作时，发布版本号不能使用正则表达式，只能使用字符【0-9a-z._-】，且特殊字符不能出现在版本号的头部或尾部\n"
                    ERROR_CODE=51
                    exit 51
                else
                    # 替换【.】为【_】，服务名中不能有【.】
                    RELEASE_VERSION=${RELEASE_VERSION//./_}
                fi
                #
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}-G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            elif [[ -z ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            else
                SERVICE_X_NAME="${SERVICE_NAME}"
            fi
            #
            # 是否运行中
            F_ONLINE_SERVICE_SEARCH  ${SERVICE_X_NAME}  ${CLUSTER} > ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
            [[ $? -eq 0 ]] && SERVICE_RUN_STATUS='YES' || SERVICE_RUN_STATUS='NO'
            #
            if [[ ${SERVICE_RUN_STATUS} == 'NO' ]]; then
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中"
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=53
                continue
            fi
            #
            if [ ! -z "${THIS_TAG}" ]; then
                # 更新指定完全匹配服务镜像
                F_SEARCH_IMAGE_TAG  ${SERVICE_NAME}  ${THIS_TAG}
                if [ $? -ne 0 ]; then
                    echo "${SERVICE_X_NAME} : 失败，镜像版本【${THIS_TAG}】未找到"
                    echo "${SERVICE_X_NAME} : 失败，镜像版本【${THIS_TAG}】未找到" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
                #
                DOCKER_IMAGE_VER_UPDATE=${THIS_TAG}
                #
            elif [ ! -z "${LIKE_THIS_TAG}" ]; then
                # 更新指定LIKE匹配镜像
                #DOCKER_IMAGE_VER_UPDATE=$(F_SEARCH_IMAGE_LIKE_TAG  ${SERVICE_NAME}  ${LIKE_THIS_TAG})
                ${DOCKER_IMAGE_SEARCH_SH}  --tag ${LIKE_THIS_TAG}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_TAG-result.txt  ${SERVICE_NAME}
                DOCKER_IMAGE_VER_UPDATE=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_TAG-result.txt | cut -d " " -f 3)
                #
                if [[ -z ${DOCKER_IMAGE_VER_UPDATE} ]]; then
                    echo "${SERVICE_X_NAME} : 失败，镜像版本【%${LIKE_THIS_TAG}%】未找到"
                    echo "${SERVICE_X_NAME} : 失败，镜像版本【%${LIKE_THIS_TAG}%】未找到" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
                #
            else
                # 更新今日发布的服务镜像
                TODAY=`date +%Y.%m.%d`
                #DOCKER_IMAGE_VER_UPDATE=$(F_SEARCH_IMAGE_LIKE_TAG  ${SERVICE_NAME}  ${TODAY})
                ${DOCKER_IMAGE_SEARCH_SH}  --tag ${TODAY}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_TAG-result.txt  ${SERVICE_NAME}
                DOCKER_IMAGE_VER_UPDATE=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_TAG-result.txt | cut -d " " -f 3)
                if [[ -z ${DOCKER_IMAGE_VER_UPDATE} ]]; then
                    echo "${SERVICE_X_NAME} : 跳过，今日无更新"
                    echo "${SERVICE_X_NAME} : 跳过，今日无更新" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=55
                    continue
                fi
                #
            fi
            #
            DOCKER_IMAGE_FULL_URL="${DOCKER_IMAGE_BASE}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VER_UPDATE}"
            #
            case ${CLUSTER} in 
                swarm)
                    DOCKER_FULL_CMD="docker service update  \
                        --with-registry-auth  \
                        --restart-max-attempts 5  \
                        --image ${DOCKER_IMAGE_FULL_URL}  \
                        ${SERVICE_X_NAME}"
                    ;;
                k8s)
                    DOCKER_FULL_CMD="kubectl set image deployments ${SERVICE_X_NAME} c-${SERVICE_NAME}=${DOCKER_IMAGE_FULL_URL}"
                    ;;
                compose)
                    SED_IMAGE='sed -i "s%^    image:.*$%    image: ${DOCKER_IMAGE_FULL_URL}%"  docker-compose.yaml'
                    echo ${SED_IMAGE}  > ${LOG_HOME}/${SERVICE_X_NAME}-update.sh
                    DOCKER_FULL_CMD="echo  \
                        ; scp -P ${COMPOSE_SSH_PORT}  ${LOG_HOME}/${SERVICE_X_NAME}-update.sh  ${COMPOSE_SSH_HOST_OR_WITH_USER}:${DOCKER_COMPOSE_SERVICE_HOME}/  \
                        ; ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                            \"cd ${DOCKER_COMPOSE_SERVICE_HOME}  \
                              &&  sh ./${SERVICE_X_NAME}-update.sh  \
                              &&  docker-compose pull  \
                              &&  docker-compose down  \
                              &&  docker-compose up -d  \
                            \"
                        "
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未定义的集群类型\n" 
                    exit 52
                    ;;
            esac
            ;;
        rollback)
            #
            # 仅回滚今天有更新的服务镜像
            #
            if [[ -n ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                # 注释掉此块，可以启用正则表达式
                if [[ ! V_${RELEASE_VERSION} =~ ^V_[0-9a-z]+([_\.\-]?[0-9a-z]+)*$ ]]; then
                    echo -e "\n猪猪侠警告：在【${SERVICE_OPERATION}】操作时，发布版本号不能使用正则表达式，只能使用字符【0-9a-z._-】，且特殊字符不能出现在版本号的头部或尾部\n"
                    ERROR_CODE=51
                    exit 51
                else
                    # 替换【.】为【_】，服务名中不能有【.】
                    RELEASE_VERSION=${RELEASE_VERSION//./_}
                fi
                #
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}-G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            elif [[ -z ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            else
                SERVICE_X_NAME="${SERVICE_NAME}"
            fi
            #
            # 是否运行中
            F_ONLINE_SERVICE_SEARCH  ${SERVICE_X_NAME}  ${CLUSTER} > ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
            [[ $? -eq 0 ]] && SERVICE_RUN_STATUS='YES' || SERVICE_RUN_STATUS='NO'
            #
            if [[ ${SERVICE_RUN_STATUS} == 'NO' ]]; then
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中"
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=53
                continue
            fi
            #
            TODAY=`date +%Y.%m.%d`
            #DOCKER_IMAGE_VER_TODAY=$(F_SEARCH_IMAGE_LIKE_TAG  ${SERVICE_NAME}  ${TODAY})
            ${DOCKER_IMAGE_SEARCH_SH}  --tag ${TODAY}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_TAG-result.txt  ${SERVICE_NAME}
            DOCKER_IMAGE_VER_TODAY=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_TAG-result.txt | cut -d " " -f 3)
            if [[ -z ${DOCKER_IMAGE_VER_TODAY} ]]; then
                echo "${SERVICE_X_NAME} : 跳过，今日无更新"
                echo "${SERVICE_X_NAME} : 跳过，今日无更新" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=55
                continue
            else
                DOCKER_IMAGE_VER_ROLLBACK=$(F_SEARCH_IMAGE_NOT_LIKE_TAG  ${SERVICE_NAME}  ${TODAY})
                if [[ -z ${DOCKER_IMAGE_VER_ROLLBACK} ]]; then
                    echo "${SERVICE_X_NAME} : 跳过，无历史镜像"
                    echo "${SERVICE_X_NAME} : 跳过，无历史镜像" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=55
                    continue
                fi
            fi
            #
            DOCKER_IMAGE_FULL_URL="${DOCKER_IMAGE_BASE}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VER_ROLLBACK}"
            #
            case ${CLUSTER} in
                swarm)
                    DOCKER_FULL_CMD="docker service update  \
                        --with-registry-auth  \
                        --restart-max-attempts 5  \
                        --image ${DOCKER_IMAGE_FULL_URL}  \
                        ${SERVICE_X_NAME}"
                    # 待办：这里是不是有多余参数，他可以从公共参数引入
                    ;;
                k8s)
                    DOCKER_FULL_CMD="kubectl set image deployments ${SERVICE_X_NAME} c-${SERVICE_NAME}=${DOCKER_IMAGE_FULL_URL}"
                    ;;
                compose)
                    SED_IMAGE='sed -i "s%^    image:.*$%    image: ${DOCKER_IMAGE_FULL_URL}%"  docker-compose.yaml'
                    echo ${SED_IMAGE}  > ${LOG_HOME}/${SERVICE_X_NAME}-update.sh
                    DOCKER_FULL_CMD="echo  \
                        ; scp -P ${COMPOSE_SSH_PORT}  ${LOG_HOME}/${SERVICE_X_NAME}-update.sh  ${COMPOSE_SSH_HOST_OR_WITH_USER}:${DOCKER_COMPOSE_SERVICE_HOME}/  \
                        ; ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                            \"cd ${DOCKER_COMPOSE_SERVICE_HOME}  \
                              &&  sh ./${SERVICE_X_NAME}-update.sh  \
                              &&  docker-compose pull  \
                              &&  docker-compose down  \
                              &&  docker-compose up -d  \
                            \"
                        "
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未定义的集群类型\n" 
                    exit 52
                    ;;
            esac
            ;;
        scale)
            #
            if [[ -n ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                # 注释掉此块，可以启用正则表达式
                if [[ ! V_${RELEASE_VERSION} =~ ^V_[0-9a-z]+([_\.\-]?[0-9a-z]+)*$ ]]; then
                    echo -e "\n猪猪侠警告：在【${SERVICE_OPERATION}】操作时，发布版本号不能使用正则表达式，只能使用字符【0-9a-z._-】，且特殊字符不能出现在版本号的头部或尾部\n"
                    ERROR_CODE=51
                    exit 51
                else
                    # 替换【.】为【_】，服务名中不能有【.】
                    RELEASE_VERSION=${RELEASE_VERSION//./_}
                fi
                #
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}-G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            elif [[ -z ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            else
                SERVICE_X_NAME="${SERVICE_NAME}"
            fi
            #
            # 是否运行中
            F_ONLINE_SERVICE_SEARCH  ${SERVICE_X_NAME}  ${CLUSTER} > ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
            [[ $? -eq 0 ]] && SERVICE_RUN_STATUS='YES' || SERVICE_RUN_STATUS='NO'
            #
            if [[ ${SERVICE_RUN_STATUS} == 'NO' ]]; then
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中"
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=53
                continue
            fi
            #
            if [ -z "${POD_REPLICAS_NEW}" ]; then
                echo -e "\n猪猪侠警告：参数【-n|--number】使用错误！\n"
                echo "跳过，配置文件错误"
                echo "${SERVICE_X_NAME} : 跳过，配置文件错误" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=52
                continue
            fi
            #
            DOCKER_FULL_CMD="echo "
            #
            case ${CLUSTER} in 
                swarm)
                    DOCKER_FULL_CMD="${DOCKER_FULL_CMD} ; docker service update  \
                        --with-registry-auth  \
                        --replicas ${POD_REPLICAS_NEW}  \
                        ${SERVICE_X_NAME}"
                    ;;
                k8s)
                    DOCKER_FULL_CMD="${DOCKER_FULL_CMD} ;  kubectl scale deployments ${SERVICE_X_NAME} --replicas=${POD_REPLICAS_NEW}"
                    ;;
                compose)
                    DOCKER_FULL_CMD="echo 'compose之【scale】暂时无此功能'"
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未定义的集群类型\n" 
                    exit 52
                    ;;
            esac
            ;;
        rm)
            #
            if [[ -n ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                # 注释掉此块，可以启用正则表达式
                #if [[ ! V_${RELEASE_VERSION} =~ ^V_[0-9a-z]+([_\.\-]?[0-9a-z]+)*$ ]]; then
                #    echo -e "\n猪猪侠警告：在【${SERVICE_OPERATION}】操作时，发布版本号不能使用正则表达式，只能使用字符【0-9a-z._-】，且特殊字符不能出现在版本号的头部或尾部\n"
                #    ERROR_CODE=51
                #    exit 51
                #else
                #    # 替换【.】为【_】，服务名中不能有【.】
                #    RELEASE_VERSION=${RELEASE_VERSION//./_}
                #fi
                #
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}-G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            elif [[ -z ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            else
                SERVICE_X_NAME="${SERVICE_NAME}"
            fi
            #
            # 是否运行中
            if [[ ${ALL_RELEASE} == 'YES' ]]; then
                SERVICE_X_NAME=${SERVICE_NAME}
                F_ONLINE_SERVICE_SEARCH_LIKE  ${SERVICE_X_NAME}  ${CLUSTER} > ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
                [[ $? -eq 0 ]] && SERVICE_RUN_STATUS='YES' || SERVICE_RUN_STATUS='NO'
            else
                F_ONLINE_SERVICE_SEARCH       ${SERVICE_X_NAME}  ${CLUSTER} > ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
                [[ $? -eq 0 ]] && SERVICE_RUN_STATUS='YES' || SERVICE_RUN_STATUS='NO'
            fi
            #
            if [[ ${SERVICE_RUN_STATUS} == 'NO' ]]; then
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中"
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=53
                continue
            fi
            #
            DOCKER_FULL_CMD="echo "
            #
            while read GET_LINE
            do
                #
                case ${CLUSTER} in 
                    swarm)
                        DOCKER_FULL_CMD="${DOCKER_FULL_CMD} ; docker service rm ${GET_LINE}"
                        ;;
                    k8s)
                        DOCKER_FULL_CMD="${DOCKER_FULL_CMD} ;  echo '========== Deployments ==========' ;  kubectl delete deployments ${GET_LINE} ; echo ; echo '========== Services ==========' ;  kubectl delete services ${GET_LINE}"
                        ;;
                    compose)
                        DOCKER_FULL_CMD="echo  \
                            ; ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                                \"cd ${DOCKER_COMPOSE_SERVICE_HOME}  \
                                &&  docker-compose down\"
                            "
                        ;;
                    *)
                        echo -e "\n猪猪侠警告：未定义的集群类型\n" 
                        exit 52
                        ;;
                esac
            done < ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
            # 待办：服务删除时，gray端口删除暂未处理
            ;;
        status)
            #
            if [[ -n ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                # 注释掉此块，可以启用正则表达式
                #if [[ ! V_${RELEASE_VERSION} =~ ^V_[0-9a-z]+([_\.\-]?[0-9a-z]+)*$ ]]; then
                #    echo -e "\n猪猪侠警告：在【${SERVICE_OPERATION}】操作时，发布版本号不能使用正则表达式，只能使用字符【0-9a-z._-】，且特殊字符不能出现在版本号的头部或尾部\n"
                #    ERROR_CODE=51
                #    exit 51
                #else
                #    # 替换【.】为【_】，服务名中不能有【.】
                #    RELEASE_VERSION=${RELEASE_VERSION//./_}
                #fi
                #
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}-G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            elif [[ -z ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            else
                SERVICE_X_NAME="${SERVICE_NAME}"
            fi
            #
            # 是否运行中
            if [[ ${ALL_RELEASE} == 'YES' ]]; then
                SERVICE_X_NAME=${SERVICE_NAME}
                F_ONLINE_SERVICE_SEARCH_LIKE  ${SERVICE_X_NAME}  ${CLUSTER} > ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
                [[ $? -eq 0 ]] && SERVICE_RUN_STATUS='YES' || SERVICE_RUN_STATUS='NO'
            else
                F_ONLINE_SERVICE_SEARCH       ${SERVICE_X_NAME}  ${CLUSTER} > ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
                [[ $? -eq 0 ]] && SERVICE_RUN_STATUS='YES' || SERVICE_RUN_STATUS='NO'
            fi
            #
            if [[ ${SERVICE_RUN_STATUS} == 'NO' ]]; then
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中"
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=53
                continue
            fi
            #
            DOCKER_FULL_CMD="echo "
            #
            while read GET_LINE
            do
                #
                case ${CLUSTER} in 
                    swarm)
                        DOCKER_FULL_CMD="${DOCKER_FULL_CMD} ; docker service ps ${GET_LINE}"
                        ;;
                    k8s)
                        DOCKER_FULL_CMD="${DOCKER_FULL_CMD} ;  echo '========== Deployments ==========' ;  kubectl get deployments ${GET_LINE} ; echo ; echo '========== Services ==========' ;  kubectl get services ${GET_LINE}"
                        ;;
                    compose)
                        DOCKER_FULL_CMD="echo  \
                            ; ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                                \"cd ${DOCKER_COMPOSE_SERVICE_HOME}  \
                                &&  docker-compose ps\"
                            "
                        ;;
                    *)
                        echo -e "\n猪猪侠警告：未定义的集群类型\n" 
                        exit 52
                        ;;
                esac
            done < ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
            ;;
        detail)
            #
            if [[ -n ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                # 注释掉此块，可以启用正则表达式
                #if [[ ! V_${RELEASE_VERSION} =~ ^V_[0-9a-z]+([_\.\-]?[0-9a-z]+)*$ ]]; then
                #    echo -e "\n猪猪侠警告：在【${SERVICE_OPERATION}】操作时，发布版本号不能使用正则表达式，只能使用字符【0-9a-z._-】，且特殊字符不能出现在版本号的头部或尾部\n"
                #    ERROR_CODE=51
                #    exit 51
                #else
                #    # 替换【.】为【_】，服务名中不能有【.】
                #    RELEASE_VERSION=${RELEASE_VERSION//./_}
                #fi
                #
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}-G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}--V_${RELEASE_VERSION}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            elif [[ -z ${RELEASE_VERSION} ]] && [[ ${CLUSTER} != 'compose' ]]; then
                if [[ ${GRAY_TAG} == 'gray' ]]; then
                    SERVICE_X_NAME="${SERVICE_NAME}--G"
                elif [[ ${GRAY_TAG} == 'normal' ]];then
                    SERVICE_X_NAME="${SERVICE_NAME}"
                else
                    echo -e "\n猪猪侠警告：这是不可能的\n"
                    ERROR_CODE=52
                    exit 52
                fi
            else
                SERVICE_X_NAME="${SERVICE_NAME}"
            fi
            #
            # 是否运行中
            if [[ ${ALL_RELEASE} == 'YES' ]]; then
                SERVICE_X_NAME=${SERVICE_NAME}
                F_ONLINE_SERVICE_SEARCH_LIKE  ${SERVICE_X_NAME}  ${CLUSTER} > ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
                [[ $? -eq 0 ]] && SERVICE_RUN_STATUS='YES' || SERVICE_RUN_STATUS='NO'
            else
                F_ONLINE_SERVICE_SEARCH       ${SERVICE_X_NAME}  ${CLUSTER} > ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
                [[ $? -eq 0 ]] && SERVICE_RUN_STATUS='YES' || SERVICE_RUN_STATUS='NO'
            fi
            #
            if [[ ${SERVICE_RUN_STATUS} == 'NO' ]]; then
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中"
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=53
                continue
            fi
            #
            DOCKER_FULL_CMD="echo "
            #
            while read GET_LINE
            do
                #
                case ${CLUSTER} in 
                    swarm)
                        DOCKER_FULL_CMD="${DOCKER_FULL_CMD} ;  docker service inspect ${GET_LINE}"
                        ;;
                    k8s)
                        DOCKER_FULL_CMD="${DOCKER_FULL_CMD} ;  echo '========== Deployments ==========' && kubectl describe deployments ${GET_LINE} ; echo ; echo '========== Services ==========' && kubectl describe services ${GET_LINE}"
                        ;;
                    compose)
                        DOCKER_FULL_CMD="echo  \
                            ; ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                                \"cd ${DOCKER_COMPOSE_SERVICE_HOME}  \
                                &&  docker-compose ps\"
                        "
                        ;;
                    *)
                        echo -e "\n猪猪侠警告：未定义的集群类型\n" 
                        exit 52
                        ;;
                esac
            done < ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
            ;;
    esac
    # 运行
    F_FUCK
    #
done < ${SERVICE_LIST_FILE_TMP}
echo -e "\n${SERVICE_OPERATION} 完成！\n"


# 退出
if ! [ "x${FUCK}" = "xyes" -o "x${FUCK}" = "xfuck" ]; then
    exit
fi
#
if [ "${SERVICE_OPERATION}" = 'status' -o "${SERVICE_OPERATION}" = 'detail' ]; then
    exit
fi


# 输出结果
#
# create:
# 53  "失败，服务已在运行中"
# 54  "失败，镜像版本【${DOCKER_IMAGE_VER} 】未找到"
# update:
# 53  "失败，服务不在运行中"
# 55  "跳过，今日无更新"
# 54  "失败，镜像版本【${THIS_TAG}】未找到"
# 54  "失败，镜像版本【%${LIKE_THIS_TAG}%】未找到"
# rm:
# 53  "失败，服务不在运行中"
# scale
# 53  "失败，服务不在运行中"
# rollback:
# 53  "失败，服务不在运行中"
# 55  "跳过，今日无更新"
# 55  "跳过，无历史镜像"
# F_FUCK:
# 50  "成功"
# 54  "失败"
#
CHECK_COUNT=${NUM}
SUCCESS_COUNT=`cat ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE} | grep -o '成功' | wc -l`
NONEED_COUNT=`cat ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE} | grep -o '跳过' | wc -l`
ERROR_COUNT=`cat ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE} | grep -o '失败' | wc -l`
TIME_END=`date +%Y-%m-%dT%H:%M:%S`
case ${SH_RUN_MODE} in
    normal)
        #
        MESSAGE_END="DOCKER SERVICE ${SERVICE_OPERATION} 已完成！ 共企图 ${SERVICE_OPERATION} ${CHECK_COUNT} 个项目，成功 ${SERVICE_OPERATION} ${SUCCESS_COUNT} 个项目，跳过 ${NONEED_COUNT} 个项目，${ERROR_COUNT} 个项目失败。"
        # 消息回显拼接
        > ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "== DOCKER SERVICE ${SERVICE_OPERATION} 报告 ==" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo -e "${ECHO_REPORT}==================== DOCKER SERVICE ${SERVICE_OPERATION} 报告 ====================${ECHO_CLOSE}"
        #
        echo "所在环境：${RUN_ENV}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "造 浪 者：${MY_XINGMING}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "开始时间：${TIME}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "结束时间：${TIME_END}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "灰度标志：${GRAY_TAG}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "发布版本：${RELEASE_VERSION}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "${SERVICE_OPERATION}清单：" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        # 输出到文件
        echo "--------------------------------------------------" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        cat  ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}            >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "--------------------------------------------------" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        # 输出屏幕
        ${FORMAT_TABLE_SH}  --delimeter ':'  --title "**服务名称**:**${SERVICE_OPERATION}**"  --file ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
        #
        F_TimeDiff  "${TIME_START}" "${TIME_END}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        #
        echo "${MESSAGE_END}" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo -e "${ECHO_REPORT}${MESSAGE_END}${ECHO_CLOSE}"
        # 保存历史
        cat ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE} >> ${FUCK_HISTORY_FILE}
        echo -e "\n\n\n"  >> ${FUCK_HISTORY_FILE}

        # markdown
        # 删除空行（以及只有tab、空格的行）
        sed -i '/^\s*$/d'  ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        t=1
        while read LINE
        do
            MSG[$t]=$LINE
            #echo ${MSG[$t]}
            let  t=$t+1
        done < ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        ${DINGDING_MARKDOWN_PY}  "【Info:Deploy:${RUN_ENV}】" "${MSG[@]}" > /dev/null
        ;;
    function)
        #
        if [ `cat ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE} | wc -l` -eq 0 ]; then
            # 结果为空
            exit 59
        fi
        #
        cat  ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE} >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE_function}
        #grep -q '成功' ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE} >/dev/null 2>&1
        #exit $?
        #exit ${ERROR_COUNT}
        exit ${ERROR_CODE}
        ;;
    *)
        echo -e "\n猪猪侠警告：这是你自己加的，请自行完善！\n"
        exit 51
        ;;
esac


