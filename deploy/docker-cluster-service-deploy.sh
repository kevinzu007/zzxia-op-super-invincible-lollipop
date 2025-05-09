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
#DOCKER_COMPOSE_BASE=
#USER_DB_FILE=
#USER_DB_FILE_APPEND_1=
#DINGDING_WEBHOOK_API_deploy=

# 引入env.sh
. ${SH_PATH}/env.sh
#LOLLIPOP_PLATFORM_NAME=
#LOLLIPOP_DB_HOME=
#LOLLIPOP_LOG_BASE=
#LOLLIPOP_YAML_BASE=
#K8S_DOCKER_REPO_SECRET_NAME=
#CONTAINER_ENVS_PUB_FILE=
#ENABLE_DEBUG_PORT=
#DEBUG_RANDOM_PORT_MIN=
#DEBUG_RANDOM_PORT_MAX=
#K8S_DEFAULT_CONTEXT=
#K8S_DEFAULT_NAMESAPCE=
#SWARM_DEFAULT_DOCKER_HOST=
#SWARM_DEFAULT_NETWORK=
#COMPOSE_DEFAULT_DOCKER_HOST=
#COMPOSE_DEFAULT_NETWORK=
# 来自 ${MY_PRIVATE_ENVS_DIR} 目录下的 *.sec
#DOCKER_REPO_SERVER=
#DOCKER_IMAGE_DEFAULT_PRE_NAME=


# 本地env
GAN_WHAT_FUCK='Docker_Deploy'
NEED_PRIVILEGES='deploy'                   #-- 运行此程序需要的权限，如果需要多个权限，则用【&】分隔
TIME=${TIME:-`date +%Y-%m-%dT%H:%M:%S`}
TIME_START=${TIME}
DATE_TIME=`date -d "${TIME}" +%Y%m%dT%H%M%S`
#
RELEASE_VERSION=''
# 灰度
GRAY_TAG="normal"                                             #--- 【normal】正常部署；【gray】灰度部署
DEBUG_X_PORTS_FILE="${LOLLIPOP_DB_HOME}/deploy-debug-x-ports.db"    #--- db目录下的文件不建议删除
#
LOG_HOME="${LOLLIPOP_LOG_BASE}/${DATE_TIME}"
#
ERROR_CODE=''     #--- 程序最终返回值，一般用于【--mode=function】时
#
DOCKER_ARG_PUB_FILE="${SH_PATH}/docker-arg-pub.list"
CONTAINER_HOSTS_PUB_FILE="${SH_PATH}/container-hosts-pub.list"
JAVA_OPTIONS_PUB_FILE="${SH_PATH}/java-options-pub.list"
#
SERVICE_LIST_FILE="${SH_PATH}/docker-cluster-service.list"
SERVICE_LIST_FILE_APPEND_1="${SH_PATH}/docker-cluster-service.list.append.1"
SERVICE_LIST_FILE_APPEND_2="${SH_PATH}/docker-cluster-service.list.append.2"
SERVICE_LIST_FILE_TMP="${LOG_HOME}/${SH_NAME}-docker-cluster-service.list.tmp"
SERVICE_ONLINE_LIST_FILE_TMP="${LOG_HOME}/${SH_NAME}-docker-cluster-service-online.list.tmp"
DOCKER_IMAGE_TAG='latest'
FUCK=${FUCK:-"NO"}
DEPLOY_BY_STEP=${DEPLOY_BY_STEP:-"NO"}
DEPLOY_LOG="${LOG_HOME}/${SH_NAME}-deploy.log"
#
DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE=${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE:-"${LOG_HOME}/${SH_NAME}-OK.list"}
#
DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE="${LOG_HOME}/${SH_NAME}-history.current"
FUCK_HISTORY_FILE="${LOLLIPOP_DB_HOME}/fuck.history"
# 运行方式
SH_RUN_MODE="normal"
# 来自webhook或父shell
export HOOK_USER_INFO_FROM
export HOOK_GAN_ENV
export HOOK_USER_NAME
export HOOK_USER_XINGMING
export HOOK_USER_EMAIL
# 来自父shell
DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE_function=${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE_function:-"${LOG_HOME}/${SH_NAME}-OK.function"}
#MY_USER_NAME=
#MY_USER_XINGMING=
#MY_USER_EMAIL=
if [[ -z ${USER_INFO_FROM} ]]; then
    USER_INFO_FROM=${HOOK_USER_INFO_FROM:-'local'}     #--【local|hook_hand|hook_gitlab】，默认：local
fi
# sh
SEND_MAIL="${SH_PATH}/../tools/send_mail.sh"
DOCKER_IMAGE_SEARCH_SH="${SH_PATH}/docker-image-search.sh"
FORMAT_TABLE_SH="${SH_PATH}/../tools/format_table.sh"
DINGDING_SEND_DEPLOY_SH="/usr/local/bin/dingding_conver_to_markdown_list.sh  --webhook ${DINGDING_WEBHOOK_API_deploy}"
# 引入函数
.  ${SH_PATH}/function.sh



# 用法：
F_HELP()
{
    echo "
    用途：用于创建、更新、查看、删除......服务
    依赖：
        ${SERVICE_LIST_FILE}
        ${SERVICE_LIST_FILE_APPEND_1}
        ${SERVICE_LIST_FILE_APPEND_2}
        ${CONTAINER_ENVS_PUB_FILE}
        ${DOCKER_ARG_PUB_FILE}
        ${CONTAINER_HOSTS_PUB_FILE}
        ${JAVA_OPTIONS_PUB_FILE}
        ${SH_PATH}/env.sh
        ${SEND_MAIL}
        ${DOCKER_IMAGE_SEARCH_SH}
        ${FORMAT_TABLE_SH}
        ${DINGDING_SEND_DEPLOY_SH}
    注意：
        * 名称正则表达式完全匹配，会自动在正则表达式的头尾加上【^ $】，请规避
        * 一般服务名（非灰度服务名）为项目清单中的服务名，灰度服务名为为【项目清单服务名】+【--】+【灰度版本号】
        * 输入命令时，参数顺序不分先后
    用法:
        $0 [-h|--help]
        $0 [-l|--list]                            #--- 列出配置文件中的服务清单
        $0 [-L|--list-run swarm|k8s|compose]      #--- 列出指定集群类型中运行的所有服务
        # 创建、修改
        $0 <-M|--mode [normal|function]>  [-c|--create|-m|--modify]  <-D|--debug-port>  <-I|--image-pre-name {镜像前置名称}>  <<-T|--TAG {精确镜像tag版本}> | <<-t|--tag {模糊镜像tag版本}> <-A|--time-ago {时间}>>>  <-n|--number {副本数}>  <-V|--release-version {版本号}>  <-G|--gray>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>  <-P|--by-step>
        # 更新
        $0 <-M|--mode [normal|function]>  [-u|--update]  <-I|--image-pre-name {镜像前置名称}>  <<-T|--TAG {精确镜像tag版本}> | <<-t|--tag {模糊镜像tag版本}> <-A|--time-ago {时间}>>>  <-V|--release-version {版本号}>  <-G|--gray>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>  <-P|--by-step>
        # 回滚
        $0 <-M|--mode [normal|function]>  [--b|rollback]  <-I|--image-pre-name {镜像前置名称}>  <<-T|--TAG {精确镜像tag版本}> | <<-t|--tag {模糊镜像tag版本}> <-A|--time-ago {时间}>>>  <-V|--release-version {版本号}>  <-G|--gray>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>  <-P|--by-step>
        #
        # 扩缩容
        $0 <-M|--mode [normal|function]>  [-S|--scale]  [-n|--number {副本数}]  <-V|--release-version {版本号}>  <-G|--gray>  <{服务名或灰度服务名1} {服务名或灰度服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>  <-P|--by-step>
        # 删除
        $0 <-M|--mode [normal|function]>  [-r|--rm]  <-V|--release-version {版本号}>  <-G|--gray>  <-a|--all-release>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>  <-P|--by-step>
        # 状态
        $0 [-s|--status]  <-V|--release-version {版本号}>  <-G|--gray>  <-a|--all-release>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>  <-P|--by-step>
        # 详情
        $0 [-d|--detail]  <-V|--release-version {版本号}>  <-G|--gray>  <-a|--all-release>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>  <-P|--by-step>
        # 日志
        $0 [-o|--logs]    <-V|--release-version {版本号}>  <-G|--gray>  <-a|--all-release>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>  <-P|--by-step>
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
        -L|--list-run  ：列出指定集群类型中运行的所有服务
        -F|--fuck      ：直接运行命令，默认：仅显示命令行
        -P|--by-step   ：【-F|--fuck】生效时，步进执行（即：按任意键执行，或按【Ctrl+C】键退出）
        -c|--create    ：创建服务，基于服务清单参数
        -m|--modify    ：修改服务，基于服务清单参数
        -u|--update    ：更新镜像版本
        -b|--rollback  ：回滚服务（默认回滚到非今天构建的最新版本），回滚到匹配的第一个版本
        -S|--scale     ：副本数设置
        -r|--rm        ：删除服务
        -s|--status    : 获取服务运行状态
        -d|--detail    : 获取服务详细信息
        -o|--logs      : 获取服务运行日志
        -D|--debug-port: 开启开发者Debug-port模式，目前用于开放所有容器内部服务端口
        -t|--tag       ：模糊镜像tag版本，支持正则
        -T|--TAG       ：精确镜像tag版本
        -I|--image-pre-name  指定镜像前置名称【DOCKER_IMAGE_PRE_NAME】，默认来自env.sh。注：镜像完整名称：\${DOCKER_REPO_SERVER}/\${DOCKER_IMAGE_PRE_NAME}/\${DOCKER_IMAGE_NAME}:\${DOCKER_IMAGE_TAG}
        -A|--time-ago  ：某时间之前的镜像版本，比如1d、24h、30m、100s，有此参数时会剔除自定义tag版本（比如：v1.2），只保留基于时间自动标记的tag版本（比如：2023.05.11.090746）
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
        $0 -c  -F  -P                                #--- 根据服务清单创建所有服务，步进执行
        $0 -c  服务1 服务2  -F                       #--- 创建【服务1】、【服务2】服务
        $0 -c  -D  服务1 服务2  -F                   #--- 创建【服务1】、【服务2】服务，并开启开发者Debug-port模式
        $0 -c  -T 2020.12.11  服务1 服务2  -F        #--- 创建【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】
        $0 -c  -t 2020.12     服务1 服务2  -F        #--- 创建【服务1】、【服务2】服务，且使用的镜像版本包含【2020.12】的最新镜像
        $0 -c  -n 2  服务1 服务2  -F                 #--- 创建【服务1】、【服务2】服务，且副本数为【2】
        $0 -c  -T 2020.12.11  -n 2  服务1 服务2  -F  #--- 创建【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】，副本数为【2】
        $0 -c  -V yyy       服务1 服务2  -F          #--- 创建【服务1】、【服务2】，版本号为【yyy】
        $0 -c  -G           服务1 服务2  -F          #--- 创建【服务1】、【服务2】的灰度服务
        $0 -c  -G  -V yyy   服务1 服务2  -F          #--- 创建【服务1】、【服务2】的灰度服务，版本号为【yyy】
        $0 -c  -G  -I aa/bb  服务1 服务2  -F         #--- 创建【服务1】、【服务2】的灰度服务，镜像前置名称为【aa/bb】
        $0 -c  -A 2d  服务1 服务2  -F                #--- 创建【服务1】、【服务2】服务，且使用2天之前最新的镜像版本
        # 修改
        $0 -m  服务1 服务2  -F                       #--- 修改【服务1】、【服务2】服务
        $0 -m  服务1 服务2  -V yyy  -F               #--- 根据服务清单修改所有版本号为【yyy】的服务
        $0 -m  -T 2020.12.11  服务1 服务2  -F        #--- 修改【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】
        $0 -m  -t 2020.12     服务1 服务2  -F        #--- 修改【服务1】、【服务2】服务，且使用的镜像版本包含【2020.12】的最新镜像
        $0 -m  -n 2  服务1 服务2  -F                 #--- 修改【服务1】、【服务2】服务，且副本数为【2】
        $0 -m  -T 2020.12.11  -n 2  服务1 服务2  -F  #--- 修改【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】，副本数为【2】
        $0 -m  -G  -I aa/bb  服务1 服务2  -F         #--- 修改【服务1】、【服务2】的灰度服务，镜像前置名称为【aa/bb】
        $0 -m  -A 2d  服务1 服务2  -F                #--- 修改【服务1】、【服务2】服务，且使用2天之前最新的镜像版本
        # 更新镜像
        $0 -u  -F                                    #--- 根据服务清单更新所有服务到最新镜像tag版本（如果今天构建过）
        $0 -u  服务1 服务2  -F                       #--- 更新【服务1】、【服务2】服务到最新镜像tag版本（如果今天构建过）
        $0 -u  -t 2020.12  -F                        #--- 根据服务清单更新所有服务到镜像tag版本包含【2020.12】的最新镜像
        $0 -u  -t 2020.12     服务1 服务2  -F        #--- 更新【服务1】、【服务2】有服务到镜像tag版本包含【2020.12】的最新镜像
        $0 -u  -T 2020.12.11  -F                     #--- 根据服务清单更新所有服务到镜像tag版本为【2020.12.11】的镜像
        $0 -u  -T 2020.12.11  服务1 服务2  -F        #--- 更新【服务1】、【服务2】有服务到镜像tag版本为【2020.12.11】的镜像
        $0 -u  -T 2020.12.11  -I aa/bb  服务1 服务2  -F   #--- 更新【服务1】、【服务2】服务到镜像tag版本为【2020.12.11】，且镜像前置名称为【aa/bb】的镜像
        $0 -u  -A 2d  服务1 服务2  -F                     #--- 设置【服务1】、【服务2】服务到【2天前】的最新镜像tag版本
        # 回滚
        $0 -b  -F                          #--- 根据服务清单回滚所有服务（如果今天构建过）
        $0 -b  服务1 服务2  -F             #--- 回滚【服务1】、【服务2】服务（如果今天构建过）
        $0 -b  服务1 服务2  -V yyy  -F     #--- 回滚【服务1】、【服务2】服务，且版本号为【yyy】（如果今天构建过）
        $0 -b  -I aa/bb  服务1 服务2  -F   #--- 更新【服务1】、【服务2】服务（如果今天构建过），搜索镜像前置名称为【aa/bb】
        $0 -b  -A 2d  服务1 服务2  -F      #--- 回滚【服务1】、【服务2】服务到【2天前】的最新镜像版本（如果今天构建过）
        #
        #
        # 扩缩容
        $0 -S  -n 2  -F                    #--- 根据服务清单设置所有服务的pod副本数为2
        $0 -S  -n 2  服务1 服务2  -F       #--- 设置【服务1】、【服务2】服务的pod副本数为2
        $0 -S  -n 2  -G  服务1 服务2  -F   #--- 设置【服务1】、【服务2】的灰度服务的pod副本数为2
        $0 -S  -n 2  -G  -V yyy  服务1 服务2  -F   #--- 设置【服务1】、【服务2】的灰度服务，且版本为【yyy】的pod副本数为2
        # 删除
        $0 -r  -F                          #--- 根据服务清单删除所有服务
        $0 -r  -F  -P                      #--- 根据服务清单删除所有服务，步进方式
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
        # 容器运行日志（更多请参考【删除】）
        $0 -o  -F  -P                      #--- 根据服务清单获服务运行取详细信息，步进方式
        $0 -o  服务1 服务2  -F             #--- 获取【服务1】、【服务2】服务运行详细信息
        # 外调用★ 
        $0 -M function  -u                 服务1  -F    #--- 更新部署【服务1】，使用最新镜像
        $0 -M function  -u  -T 2020.12.11  服务1  -F    #--- 更新部署【服务1】，使用版本为【2020.12.11】的镜像
    "
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
            for S_LINE in $(docker service ls  --format "{{.Name}}" | grep "${F_SEARCH_NAME}")
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
            for S_LINE in $(docker service ls  --format "{{.Name}}" | grep "${F_SEARCH_NAME}")
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
    F_SEARCH_IMAGE_TAG_RESULT_FILE="${LOG_HOME}/${SH_NAME}-F_SEARCH_IMAGE_TAG-result--${F_SERVICE_NAME}.txt"
    ${DOCKER_IMAGE_SEARCH_SH}  ${IMAGE_PRE_NAME_ARG}  --tag ${F_THIS_TAG}  --output ${F_SEARCH_IMAGE_TAG_RESULT_FILE}  ${F_SERVICE_NAME}
    search_r=$(cat ${F_SEARCH_IMAGE_TAG_RESULT_FILE} | cut -d " " -f 3-)
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
            #F_CONTAINER_ENVS_FILE_SET_n=$( echo ${ENV_LINE} | awk '{print $2}' | awk -F '=' '{print $1}' )
            F_CONTAINER_ENVS_FILE_SET_n=$( echo ${ENV_LINE} | awk '{$1="";print}' | awk -F '=' '{print $1}' )
            F_CONTAINER_ENVS_FILE_SET_n=$( echo ${F_CONTAINER_ENVS_FILE_SET_n} )
            #F_CONTAINER_ENVS_FILE_SET_v=$( echo ${ENV_LINE} | awk '{print $2}' | awk -F '=' '{print $2}' | sed 's/\"//g' )
            F_CONTAINER_ENVS_FILE_SET_v=$( echo ${ENV_LINE} | cut -d ' ' -f 2- | awk -F '=' '{print $2}' | sed 's/\"//g' )
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
        image: ${DOCKER_REPO_SERVER}/${DOCKER_IMAGE_PRE_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
        imagePullPolicy: IfNotPresent
        args:
        env:
        ports:
      imagePullSecrets:
      - name: ${K8S_DOCKER_REPO_SECRET_NAME}
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
      - ${COMPOSE_NETWORK}
    extra_hosts:
      - somehost:1.1.1.1
    #depends_on:
    #  - db 
    environment:
      foo: "bar"
    volumes:
      - ./default_vol:/host_vol:rw
    # 其他（一般不用）
    #cpu_shares: 73
    #cpu_quota: 50000
    #mem_limit: 1000000000
    #privileged: true
networks:
  ${COMPOSE_NETWORK}:
    # 二选一
    # 1 自动创建网络
    #driver: bridge
    # 2 使用外部网络，需要手动预先创建 -- for v1.x ，如果是v2.x，会有警告
    #external:
    #  name: ${COMPOSE_NETWORK}
    # 3 使用外部网络，需要手动预先创建 -- for v2.x
    #external: true
    "
}



# 根据【DEPLOY_PLACEMENT】设置运行环境
# 用法：
F_SET_RUN_ENV()
{
    K8S_CONTEXT=''
    K8S_NAMESAPCE=''
    #
    SWARM_DOCKER_HOST=''
    SWARM_NETWORK=''
    #
    COMPOSE_DOCKER_HOST=''
    COMPOSE_NETWORK=''
    COMPOSE_SERVICE_HOME=''
    COMPOSE_SSH_HOST_OR_WITH_USER=''
    COMPOSE_SSH_PORT=''
    #
    DEPLOY_PLACEMENT_LABELS=''
    #
    case ${CLUSTER} in
        swarm)
            if [[ ! -z ${DEPLOY_PLACEMENT} ]]; then
                DEPLOY_PLACEMENT=${DEPLOY_PLACEMENT// /}               #--- 删除字符串中所有的空格
                DEPLOY_PLACEMENT_ARG_NUM=$(echo ${DEPLOY_PLACEMENT} | grep -o ',' | wc -l)
                DEPLOY_PLACEMENT_LABELS=''
                for ((i=DEPLOY_PLACEMENT_ARG_NUM; i>=0; i--))
                do
                    if [[ -z ${DEPLOY_PLACEMENT} ]]; then
                        break
                    fi
                    FIELD=$((i+1))
                    DEPLOY_PLACEMENT_SET=`echo ${DEPLOY_PLACEMENT} | cut -d ',' -f ${FIELD}`
                    # 
                    if [[ ${DEPLOY_PLACEMENT_SET} =~ ^H ]]; then
                        SWARM_DOCKER_HOST=$(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-)
                    elif [[ ${DEPLOY_PLACEMENT_SET} =~ ^NET ]]; then
                        SWARM_NETWORK=$(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-)
                    elif [[ ${DEPLOY_PLACEMENT_SET} =~ ^L ]]; then
                        DEPLOY_PLACEMENT_LABELS="$(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-) ${DEPLOY_PLACEMENT_LABELS}"
                    else
                        echo -e "\n猪猪侠警告：配置文件错误，请检查【DEPLOY_PLACEMENT】\n"
                        return 52
                    fi
                done
            fi
            #
            # 输出
            SWARM_DOCKER_HOST=${SWARM_DOCKER_HOST:-"${SWARM_DEFAULT_DOCKER_HOST}"}
            SWARM_NETWORK=${SWARM_NETWORK:-"${SWARM_DEFAULT_NETWORK}"}
            # DEPLOY_PLACEMENT_LABELS
            export DOCKER_HOST=${SWARM_DOCKER_HOST}
            ;;
        k8s)
            if [[ ! -z ${DEPLOY_PLACEMENT} ]]; then
                DEPLOY_PLACEMENT=${DEPLOY_PLACEMENT// /}               #--- 删除字符串中所有的空格
                DEPLOY_PLACEMENT_ARG_NUM=$(echo ${DEPLOY_PLACEMENT} | grep -o ',' | wc -l)
                DEPLOY_PLACEMENT_LABELS=''
                for ((i=DEPLOY_PLACEMENT_ARG_NUM; i>=0; i--))
                do
                    if [ "x${DEPLOY_PLACEMENT}" = 'x' ]; then
                        break
                    fi
                    FIELD=$((i+1))
                    DEPLOY_PLACEMENT_SET=`echo ${DEPLOY_PLACEMENT} | cut -d ',' -f ${FIELD}`
                    # 假设只有一个Label
                    if [[ ${DEPLOY_PLACEMENT_SET} =~ ^C ]]; then
                        K8S_CONTEXT=$(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-)
                    elif [[ ${DEPLOY_PLACEMENT_SET} =~ ^NS ]]; then
                        K8S_NAMESAPCE=$(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-)
                    elif [[ ${DEPLOY_PLACEMENT_SET} =~ ^L ]]; then
                        DEPLOY_PLACEMENT_LABELS="$(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-) ${DEPLOY_PLACEMENT_LABELS}"
                    else
                        echo -e "\n猪猪侠警告：配置文件错误，请检查【DEPLOY_PLACEMENT】\n"
                        return 52
                    fi
                done
            fi
            #
            # 输出
            K8S_CONTEXT=${K8S_CONTEXT:-"K8S_DEFAULT_CONTEXT"}
            K8S_NAMESAPCE=${K8S_NAMESAPCE:-"K8S_DEFAULT_NAMESAPCE"}
            # DEPLOY_PLACEMENT_LABELS
            ;;
        compose)
            COMPOSE_NETWORK_IS_EXT='NO'           #-- 默认不是外部预定义网络
            if [[ ! -z ${DEPLOY_PLACEMENT} ]]; then
                DEPLOY_PLACEMENT=${DEPLOY_PLACEMENT// /}               #--- 删除字符串中所有的空格
                DEPLOY_PLACEMENT_ARG_NUM=$(echo ${DEPLOY_PLACEMENT} | grep -o ',' | wc -l)
                DEPLOY_PLACEMENT_LABELS=''
                for ((i=DEPLOY_PLACEMENT_ARG_NUM; i>=0; i--))
                do
                    if [[ -z ${DEPLOY_PLACEMENT} ]]; then
                        break
                    fi
                    FIELD=$((i+1))
                    DEPLOY_PLACEMENT_SET=`echo ${DEPLOY_PLACEMENT} | cut -d ',' -f ${FIELD}`
                    # 
                    if [[ ${DEPLOY_PLACEMENT_SET} =~ ^H ]]; then
                        COMPOSE_DOCKER_HOST=$(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-)
                    elif [[ ${DEPLOY_PLACEMENT_SET} =~ ^NET ]]; then
                        COMPOSE_NETWORK=$(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-)
                    elif [[ ${DEPLOY_PLACEMENT_SET} =~ ^L ]]; then
                        DEPLOY_PLACEMENT_LABELS="$(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-) ${DEPLOY_PLACEMENT_LABELS}"
                    else
                        echo -e "\n猪猪侠警告：配置文件错误，请检查【DEPLOY_PLACEMENT】\n"
                        return 52
                    fi
                done
            else
                echo -e "\n猪猪侠警告：配置文件错误，请检查【DEPLOY_PLACEMENT】，【CLUSTER=compose】时，此项不能为空\n"
                return 52
            fi
            #
            # 输出
            COMPOSE_DOCKER_HOST=${COMPOSE_DOCKER_HOST:-"${COMPOSE_DEFAULT_DOCKER_HOST}"}
            COMPOSE_SERVICE_HOME=${DOCKER_COMPOSE_BASE}/${SERVICE_NAME}
            COMPOSE_NETWORK=${COMPOSE_NETWORK:-"${COMPOSE_DEFAULT_NETWORK}"}
            if [[ ${COMPOSE_NETWORK} =~ @ ]]; then
                COMPOSE_NETWORK=$( echo ${COMPOSE_NETWORK} | awk -F '@' '{print $1}' )
                COMPOSE_NETWORK_IS_EXT='YES'
            fi
            #
            # 检查是否ssh协议，并获取 COMPOSE_SSH_HOST_OR_WITH_USER 及 COMPOSE_SSH_PORT 供后面使用
            # ssh://<用户@>主机名或IP<:端口号>
            if [[ ${COMPOSE_DOCKER_HOST} =~ ^ssh ]]; then
                # awk会自动去掉【""】引号
                COMPOSE_SSH_HOST_OR_WITH_USER=$(echo ${COMPOSE_DOCKER_HOST} | awk -F '//' '{print $2}' | awk -F ':' '{print $1}')
                COMPOSE_SSH_PORT=$(echo ${COMPOSE_DOCKER_HOST} | awk -F '//' '{print $2}' | awk -F ':' '{print $2}')
                if [[ -z ${COMPOSE_SSH_PORT} ]]; then
                    COMPOSE_SSH_PORT='22'
                fi
            else
                echo -e "\n猪猪侠警告：配置文件错误，请检查【DEPLOY_PLACEMENT】，Compose集群仅支持【ssh://<用户@>主机名或IP<:端口号>】格式，因为要使用ssh端口拷贝文件\n"
                return 52
            fi
            #
            export DOCKER_HOST=${COMPOSE_DOCKER_HOST}
            #
            # test
            if [[ $(docker image ls >/dev/null 2>&1; echo $?) != 0 ]]; then
                echo -e "\n猪猪侠警告：连接测试异常，请检查【DEPLOY_PLACEMENT】或目标主机，Docker daemon无法正常连接\n"
                return 52
            fi
            ;;
        *)
            echo -e "\n猪猪侠警告：未定义的集群类型\n"
            return 52
            ;;
    esac
    return 0
}



# 查询某种集群管理信息，去重并输出为以空格分隔的字符串
# 用法：F_SEARCH_CLUSTER_MANAGE_INFO  [{集群}]
F_SEARCH_CLUSTER_MANAGE_INFO()
{
    #
    F_CLUSTER=$1
    #
    CLUSTER_MANAGE_INFO=''
    #
    case ${F_CLUSTER} in
        swarm)
            CLUSTER_MANAGE_INFO=${SWARM_DEFAULT_DOCKER_HOST}
            ;;
        k8s)
            CLUSTER_MANAGE_INFO=${K8S_DEFAULT_CONTEXT}
            ;;
        compose)
            CLUSTER_MANAGE_INFO=${COMPOSE_DEFAULT_DOCKER_HOST}
            ;;
        *)
            echo -e "\n猪猪侠警告：未定义的集群类型\n"
            return 51
            ;;
    esac
    #
    while read LINE_A
    do
        # 跳过以#开头的行或空行
        [[ "$LINE_A" =~ ^# ]] || [[ "$LINE_A" =~ ^[\ ]*$ ]] && continue
        #
        # 2
        #
        CLUSTER=`echo ${LINE_A} | cut -d \| -f 3`
        CLUSTER=`eval echo ${CLUSTER}`
        #
        # 4
        #
        DEPLOY_PLACEMENT=`echo ${LINE_A} | cut -d \| -f 5`
        DEPLOY_PLACEMENT=`eval echo ${DEPLOY_PLACEMENT}`
        #
        #
        if [[ ! -z ${DEPLOY_PLACEMENT} ]] &&  [[ ${CLUSTER} == ${F_CLUSTER} ]]; then
            #
            DEPLOY_PLACEMENT=${DEPLOY_PLACEMENT// /}               #--- 删除字符串中所有的空格
            DEPLOY_PLACEMENT_ARG_NUM=$(echo ${DEPLOY_PLACEMENT} | grep -o ',' | wc -l)
            #
            for ((i=DEPLOY_PLACEMENT_ARG_NUM; i>=0; i--))
            do
                #
                if [[ -z ${DEPLOY_PLACEMENT} ]]; then
                    break
                fi
                FIELD=$((i+1))
                DEPLOY_PLACEMENT_SET=`echo ${DEPLOY_PLACEMENT} | cut -d ',' -f ${FIELD}`
                # 
                case ${F_CLUSTER} in
                    swarm)
                        if [[ ${DEPLOY_PLACEMENT_SET} =~ ^H ]]; then
                            CLUSTER_MANAGE_INFO+=" $(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-)"
                        fi
                        ;;
                    k8s)
                        if [[ ${DEPLOY_PLACEMENT_SET} =~ ^C ]]; then
                            CLUSTER_MANAGE_INFO+=" $(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-)"
                        fi
                        ;;
                    compose)
                        if [[ ${DEPLOY_PLACEMENT_SET} =~ ^H ]]; then
                            CLUSTER_MANAGE_INFO+=" $(echo ${DEPLOY_PLACEMENT_SET} | cut -d '=' -f 2-)"
                        fi
                        ;;
                    *)
                        echo -e "\n猪猪侠警告：未定义的集群类型\n"
                        return 51
                        ;;
                esac
            done
        fi
        #
    done < ${SERVICE_LIST_FILE_APPEND_1}
    #
    # 全匹配去重
    #CLUSTER_MANAGE_INFO=$( awk  -v RS=' '  '!a[$1]++'  <<< ${CLUSTER_MANAGE_INFO} )
    CLUSTER_MANAGE_INFO=$( echo ${CLUSTER_MANAGE_INFO} | awk  -v RS=' '  '!a[$1]++' )
    #
    #
    # 去ip相同部分（避免因为IP主机相同，而用户或端口不同，亦或者用户或端口省略的情况造成的重复问题，这也许不是大问题，但我想做个全套）
    # 获取ip主机列表
    CLUSTER_MANAGE_INFO_HOST_a=''
    for a in ${CLUSTER_MANAGE_INFO}
    do
        a_host=$( echo $a  |  awk -F '//' '{print $2}' | awk -F ':' '{print $1}' | cut -d '@' -f 2 )
        CLUSTER_MANAGE_INFO_HOST_a+=" ${a_host}"
    done
    # ip主机去重
    CLUSTER_MANAGE_INFO_HOST_a=$( echo ${CLUSTER_MANAGE_INFO_HOST_a} | awk  -v RS=' '  '!a[$1]++' )
    # 根据列表重新组织${CLUSTER_MANAGE_INFO}
    CLUSTER_MANAGE_INFO_HOST_bc=''
    for b in ${CLUSTER_MANAGE_INFO_HOST_a}
    do
        # 在原表中查询完全信息
        for c in ${CLUSTER_MANAGE_INFO}
        do
            c_host=$( echo $c  |  awk -F '//' '{print $2}' | awk -F ':' '{print $1}' | cut -d '@' -f 2 )
            if [[ ${c_host} == $b ]]; then
                CLUSTER_MANAGE_INFO_HOST_bc+=" $c"
                break
            fi
        done
    done
    #
    CLUSTER_MANAGE_INFO=${CLUSTER_MANAGE_INFO_HOST_bc}
    #
    #
    # 输出
    echo ${CLUSTER_MANAGE_INFO}
    return
    #
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
    if [[ ${FUCK} == YES ]]; then
        if [[ ${SERVICE_OPERATION} == 'rm' ]] && [[ ${SERVICE_OPERATION} == 'modify' ]]; then
            # 保存服务端口备用
            PORTS_RM=''
            while read P_LINE
            do
                PORTS_RM="${PORTS_RM} $(F_SEARCH_ONLINE_SERVICE_PUBLISH_PORTS  ${P_LINE})"
            done < ${SERVICE_ONLINE_LIST_FILE_TMP}---${SERVICE_NAME}
        fi
        # 显示命令
        echo -e '# 正在执行以下指令：\n'
        echo "${DOCKER_FULL_CMD}"
        #
        if [[ ${DEPLOY_BY_STEP} == YES ]]; then
            echo 
            # 在while read循环中的read命令会失效，需要加上 < /dev/tty
            #read -p "按任意键继续，或按【Ctrl+C】键终止"
            read -p "按任意键继续，或按【Ctrl+C】键终止"  < /dev/tty
            #
            # 执行命令
            echo  ${DOCKER_FULL_CMD} | bash
            SH_ERROR_CODE=$?
        else
            # 执行命令，并写日志
            DEPLOY_LOG_file="${DEPLOY_LOG}--${SERVICE_NAME}.log"
            echo "正在执行，请等待......"
            echo  ${DOCKER_FULL_CMD} | bash  > ${DEPLOY_LOG_file}  2>&1
            SH_ERROR_CODE=$?
            cat  ${DEPLOY_LOG_file}
            # mail
            if [[ ${SH_ERROR_CODE} != 0 && -n "${MY_USER_EMAIL}" ]]; then
                ${SEND_MAIL}  --subject "【${RUN_ENV}】${GAN_WHAT_FUCK} Log - ${SERVICE_NAME}"  --content "请看附件\n"  --attach "${DEPLOY_LOG_file}"  "${MY_USER_EMAIL}"
            fi
        fi
        #
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
            rm|status|detail|logs)
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
                echo -e "\n猪猪侠警告：未定义的操作类型\n"
                return 52
                ;;
        esac
        #
    else
        echo -e '# 完整命令如下，请确认，可以拷贝到命令行运行，或使用【-F|--fuck】参数运行：\n'
        echo  ${DOCKER_FULL_CMD}
    fi
    #echo ''
}



# 参数检查
# 检查参数是否符合要求，会对参数进行重新排序，列出的参数会放在其他参数的前面，这样你在输入脚本参数时，不需要关注脚本参数的输入顺序，例如：'$0 aa bb -w wwww ccc'
# 但除了参数列表中指定的参数之外，脚本参数中不能出现以'-'开头的其他参数，例如按照下面的参数要求，这个命令是不能正常运行的：'$0 -w wwww  aaa --- bbb ccc'
# 如果想要在命令中正确运行上面以'-'开头的其他参数，你可以在'-'参数前加一个'--'参数，这个可以正确运行：'$0 -w wwww  aaa -- --- bbb ccc'
# 你可以通过'bash -x'方式运行脚本观察'--'的运行规律
#
TEMP=`getopt -o hlL:FPcmubSrsdoDI:T:t:A:n:GV:aM:  -l help,list,list-run:,fuck,by-step,create,modify,update,rollback,scale,rm,status,detail,logs,debug-port,image-pre-name:,TAG:,tag:,time-ago:,number:,gray,release-version:,all-release,mode: -- "$@"`
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
            ARG_CLUSTER=$2
            shift 2
            #
            F_SEARCH_CLUSTER_MANAGE_INFO ${ARG_CLUSTER}  > /tmp/${SH_NAME}-F_SEARCH_CLUSTER_MANAGE_INFO.txt
            if [[ $? != 0 ]]; then
                exit 51
            fi
            #
            for c in $(cat  /tmp/${SH_NAME}-F_SEARCH_CLUSTER_MANAGE_INFO.txt)
            do
                case ${ARG_CLUSTER} in
                    swarm)
                        #
                        export DOCKER_HOST=${c}
                        docker service ls
                        #
                        export DOCKER_HOST=''
                        ;;
                    k8s)
                        K8S_ORIGIN_CONTEXT=$(kubectl config current-contexts)
                        #
                        kubectl config use-context  ${c}
                        kubectl get services --all
                        #
                        kubectl config use-context  ${K8S_ORIGIN_CONTEXT}
                        ;;
                    compose)
                        #
                        export DOCKER_HOST=${c}
                        docker ps
                        #
                        export DOCKER_HOST=''
                        ;;
                    *)
                        echo -e "\n猪猪侠警告：未定义的集群类型\n"
                        exit 52
                        ;;
                esac
            done
            exit
            ;;
        -F|--fuck)
            FUCK='YES'
            shift
            ;;
        -P|--by-step)
            DEPLOY_BY_STEP='YES'
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
        -o|--logs)
            if [ -z "${SERVICE_OPERATION}" ]; then
                SERVICE_OPERATION='logs'
            else
                echo -e "\n猪猪侠警告：主要参数太多^_^\n"
                exit 51
            fi
            shift
            ;;
        -D|--debug-port)
            ENABLE_DEBUG_PORT='YES'
            shift
            ;;
        -I|--image-pre-name)
            IMAGE_PRE_NAME=$2
            IMAGE_PRE_NAME_ARG="--image-pre-name ${IMAGE_PRE_NAME}"
            shift 2
            ;;
        -T|--TAG)
            THIS_TAG=$2
            shift 2
            ;;
        -t|--tag)
            LIKE_THIS_TAG=$2
            shift 2
            LIKE_THIS_TAG_ARG="--tag ${LIKE_THIS_TAG}"
            ;;
        -A|--time_ago)
            TIME_AGO=$2
            shift 2
            grep -E -q '[1-9]+[0-9]*[dhms]$' <<< ${TIME_AGO}
            if [ $? -ne 0 ]; then
                echo -e "\n猪猪侠警告：参数【-A|--time_ago】参数不合法，请查看帮助【$0 --help】\n"
                exit 51
            fi
            #
            TIME_AGO_ARG="--time_ago ${TIME_AGO}"
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



# 建立base目录
[ -d "${LOG_HOME}" ] || mkdir -p "${LOG_HOME}"
[ -d "${LOLLIPOP_YAML_BASE}" ] || mkdir -p "${LOLLIPOP_YAML_BASE}"


# 删除空行
#sed -i '/^\s*$/d' ${SERVICE_LIST_FILE}
## 删除行中的空格,markdown文件不要这样
#sed -i 's/[ \t]*//g'  ${SERVICE_LIST_FILE}



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
# 按第6列排序（PRIORITY）
> ${SERVICE_LIST_FILE_TMP}.sort
for i in  `awk -F '|' '{split($7,a," ");print NR,a[1]}' ${SERVICE_LIST_FILE_TMP}  |  sort -n -k 2 |  awk '{print $1}'`
do
    awk "NR=="$i'{print}' ${SERVICE_LIST_FILE_TMP}  >> ${SERVICE_LIST_FILE_TMP}.sort
done
cp  ${SERVICE_LIST_FILE_TMP}.sort  ${SERVICE_LIST_FILE_TMP}
# 加表头
sed -i  '1i#| **服务名** | **镜像前置名** | **DOCKER镜像名** | **POD副本数** | **容器PORTS** | **优先级** | **备注** |'  ${SERVICE_LIST_FILE_TMP}
# 屏显
if [[ ${SH_RUN_MODE} == 'normal' ]]; then
    echo -e "${ECHO_NORMAL}========================= 开始发布 =========================${ECHO_CLOSE}"  #--- 60 (60-50-40)
    echo -e "\n【${SH_NAME}】待${SERVICE_OPERATION}服务清单："
    ${FORMAT_TABLE_SH}  --delimeter '|'  --file ${SERVICE_LIST_FILE_TMP}
    #echo -e "\n"
fi



# 干
> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
TOTAL_SERVICES=$(cat ${SERVICE_LIST_FILE_TMP} | grep '^|' | wc -l)
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
    #
    POD_REPLICAS=`echo ${LINE} | cut -d \| -f 5`
    POD_REPLICAS=`eval echo ${POD_REPLICAS}`
    #
    CONTAINER_PORTS=`echo ${LINE} | cut -d \| -f 6`
    CONTAINER_PORTS=`eval echo ${CONTAINER_PORTS}`
    #
    # 7 PRIORITY 这里无需处理
    #
    NOTE=`echo ${LINE} | cut -d \| -f 8`
    NOTE=`echo ${NOTE}`
    #
    #
    # append.1
    SERVICE_LIST_FILE_APPEND_1_TMP="${LOG_HOME}/${SH_NAME}-${SERVICE_LIST_FILE_APPEND_1##*/}---${SERVICE_NAME}"
    cat ${SERVICE_LIST_FILE_APPEND_1} | grep "${SERVICE_NAME}"  >  ${SERVICE_LIST_FILE_APPEND_1_TMP}
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
            HOST_NAME=`echo ${LINE_A} | cut -d \| -f 4`
            HOST_NAME=`eval echo ${HOST_NAME}`
            #
            DEPLOY_PLACEMENT=`echo ${LINE_A} | cut -d \| -f 5`
            DEPLOY_PLACEMENT=`eval echo ${DEPLOY_PLACEMENT}`
        fi
    done < ${SERVICE_LIST_FILE_APPEND_1_TMP}
    #
    if [[ ${GET_IT_A} != 'YES' ]];then
        echo -e "\n猪猪侠警告：在【${SERVICE_LIST_FILE_APPEND_1}】文件中没有找到服务名【${SERVICE_NAME}】，请检查！\n"
        exit 51
    fi
    #
    #
    # append.2
    SERVICE_LIST_FILE_APPEND_2_TMP="${LOG_HOME}/${SH_NAME}-${SERVICE_LIST_FILE_APPEND_2##*/}---${SERVICE_NAME}"
    cat ${SERVICE_LIST_FILE_APPEND_2} | grep "${SERVICE_NAME}"  >  ${SERVICE_LIST_FILE_APPEND_2_TMP}
    GET_IT_B='NO'
    while read LINE_B
    do
        # 跳过以#开头的行或空行
        [[ "$LINE_B" =~ ^# ]] || [[ "$LINE_B" =~ ^[\ ]*$ ]] && continue
        #
        SERVICE_NAME_B=`echo ${LINE_B} | cut -d \| -f 2`
        SERVICE_NAME_B=`echo ${SERVICE_NAME_B}`
        if [[ ${SERVICE_NAME_B} == ${SERVICE_NAME} ]]; then
            #
            GET_IT_B='YES'
            #
            JAVA_OPTIONS=`echo ${LINE_B} | cut -d \| -f 3`
            JAVA_OPTIONS=`eval echo ${JAVA_OPTIONS}`
            JAVA_OPTIONS=${JAVA_OPTIONS//'~'/${HOME}}
            #
            CONTAINER_ENVS=`echo ${LINE_B} | cut -d \| -f 4`
            CONTAINER_ENVS=`eval echo ${CONTAINER_ENVS}`
            CONTAINER_ENVS=${CONTAINER_ENVS//'~'/${HOME}}
            #
            CONTAINER_CMDS=`echo ${LINE_B} | cut -d \| -f 5`
            CONTAINER_CMDS=`eval echo ${CONTAINER_CMDS}`
            CONTAINER_CMDS=${CONTAINER_CMDS//'~'/${HOME}}
        fi
    done < ${SERVICE_LIST_FILE_APPEND_2_TMP}
    #
    #if [[ ${GET_IT_B} != 'YES' ]];then
    #    echo -e "\n猪猪侠警告：在【${SERVICE_LIST_FILE_APPEND_2}】文件中没有找到服务名【${SERVICE_NAME}】，请检查！\n"
    #    exit 51
    #fi
    #
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
            YAML_HOME="${LOLLIPOP_YAML_BASE}/${SERVICE_NAME}"
            [ -d "${YAML_HOME}" ] || mkdir -p "${YAML_HOME}"
            ;;
        compose)
            YAML_HOME="${LOLLIPOP_YAML_BASE}/${SERVICE_NAME}"
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
    echo -e "${ECHO_NORMAL}# ${NUM}/${TOTAL_SERVICES}: ${LINE}${ECHO_CLOSE}"
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
                    if [[ ${COMPOSE_NETWORK_IS_EXT} == 'YES' ]]; then
                        sed -i "s/^    #external:$/    external:/"       ${YAML_HOME}/docker-compose.yaml
                        # docker-compose v2.x 用下面这个，此时用上面那个会有警告（语法变了），不过不影响使用
                        #sed -i "s/^    #external: true/    external: true/"       ${YAML_HOME}/docker-compose.yaml
                        sed -i "s/^    #  name:/      name:/"            ${YAML_HOME}/docker-compose.yaml
                    else
                        sed -i "s/^    #driver: bridge/    driver: bridge/"  ${YAML_HOME}/docker-compose.yaml
                    fi
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
                        HOSTS_IP=$(   echo ${LINE} | awk '{print $1}' )
                        HOSTS_NAME=$( echo ${LINE} | awk '{print $2}' )
                        #
                        case "${CLUSTER}" in
                            swarm)
                                CONTAINER_HOSTS_PUB_OK="${CONTAINER_HOSTS_PUB_OK}  --host ${HOSTS_NAME}:${HOSTS_IP}"
                                ;;
                            k8s)
                                sed -i "/^      hostAliases:/a\      - ip: ${HOSTS_IP}\n        hostnames:\n        - ${HOSTS_NAME}"  ${YAML_HOME}/${SERVICE_X_NAME}.yaml
                                ;;
                            compose)
                                sed -i "/^    extra_hosts:/a\      - \"${HOSTS_NAME}:${HOSTS_IP}\""  ${YAML_HOME}/docker-compose.yaml
                                ;;
                            *)
                                echo -e "\n猪猪侠警告：未定义的集群类型\n"
                                exit 52
                        esac
                    fi
                done < "${CONTAINER_HOSTS_PUB_FILE}"
            fi


            # 3 组装image
            DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG:-'latest'}
            # 命令参数指定版本
            if [ -n "${THIS_TAG}" ]; then
                # 完全匹配服务镜像
                F_SEARCH_IMAGE_TAG  ${SERVICE_NAME}  ${THIS_TAG}
                if [ $? -ne 0 ]; then
                    echo "${SERVICE_NAME} : 失败，镜像版本【${THIS_TAG}】未找到" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
                DOCKER_IMAGE_TAG="${THIS_TAG}"
                #
            elif [[ -n ${TIME_AGO} ]]; then
                ${DOCKER_IMAGE_SEARCH_SH}  ${IMAGE_PRE_NAME_ARG}  ${LIKE_THIS_TAG_ARG}  ${TIME_AGO_ARG}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_TIME_AGO_TAG-result.txt--${SERVICE_NAME}  ${SERVICE_NAME}
                DOCKER_IMAGE_TAG=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_TIME_AGO_TAG-result.txt--${SERVICE_NAME} | cut -d " " -f 3)
                if [[ -z ${DOCKER_IMAGE_TAG} ]]; then
                    echo "${SERVICE_NAME} : 失败，无匹配镜像【${LIKE_THIS_TAG_ARG} ${TIME_AGO_ARG}】" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
            elif [[ -z ${TIME_AGO} ]] && [[ -n ${LIKE_THIS_TAG} ]]; then
                ${DOCKER_IMAGE_SEARCH_SH}  ${IMAGE_PRE_NAME_ARG}  ${LIKE_THIS_TAG_ARG}  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_THIS_TAG-result.txt--${SERVICE_NAME}  ${SERVICE_NAME}
                # 可能有多个，但只取第一个
                DOCKER_IMAGE_TAG=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_THIS_TAG-result.txt--${SERVICE_NAME} | cut -d " " -f 3)
                if [[ -z ${DOCKER_IMAGE_TAG} ]]; then
                    echo "${SERVICE_NAME} : 失败，无匹配镜像【${LIKE_THIS_TAG_ARG}】" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
            else
                # 默认镜像版本
                F_SEARCH_IMAGE_TAG  ${SERVICE_NAME}  ${DOCKER_IMAGE_TAG}
                if [ $? -ne 0 ]; then
                    echo "${SERVICE_NAME} : 失败，镜像版本【${DOCKER_IMAGE_TAG}】未找到" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
            fi
            #
            DOCKER_IMAGE_FULL_URL="${DOCKER_REPO_SERVER}/${DOCKER_IMAGE_PRE_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
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
            CONTAINER_PORTS_NUM=`echo ${CONTAINER_PORTS} | grep -o ',' | wc -l`
            for ((i=CONTAINER_PORTS_NUM; i>=0; i--))
            do
                # 无端口
                if [[ -z ${CONTAINER_PORTS} ]]; then
                    echo "端口为空，故不会开放任何外部端口"
                    break
                fi
                #
                FIELD=$((i+1))
                CONTAINER_PORTS_SET=`echo ${CONTAINER_PORTS} | cut -d ',' -f ${FIELD}`
                CONTAINER_PORTS_SET_outside=`echo ${CONTAINER_PORTS} | cut -d ',' -f ${FIELD} | cut -d : -f 1`
                CONTAINER_PORTS_SET_outside=`echo ${CONTAINER_PORTS_SET_outside}`
                CONTAINER_PORTS_SET_inside=`echo ${CONTAINER_PORTS} | cut -d ',' -f ${FIELD} | cut -d : -f 2`
                CONTAINER_PORTS_SET_inside=`echo ${CONTAINER_PORTS_SET_inside}`
                #
                if [[ -z ${CONTAINER_PORTS_SET_inside} ]]; then
                    echo -e "\n猪猪侠警告：配置文件错误，请检查【CONTAINER_PORTS】。inside端口不能为空\n"
                    exit 52
                fi
                #
                # 开放Debug端口
                if [[ ${ENABLE_DEBUG_PORT} == 'YES' ]]; then
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
            #
            # 将变量值中的【,】替换为空格，并在前后加上引号
            #DEBUG_X_PORTS='"'${DEBUG_X_PORTS/,/ }'"'


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
            JAVA_OPTIONS_NUM=`echo ${JAVA_OPTIONS} | grep -o ',' | wc -l`
            for ((i=JAVA_OPTIONS_NUM; i>=0; i--))
            do
                if [ "x${JAVA_OPTIONS}" = 'x' ]; then
                    break
                fi
                FIELD=$((i+1))
                JAVA_OPTIONS_SET=`echo ${JAVA_OPTIONS} | cut -d ',' -f ${FIELD}`
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
            CONTAINER_ENVS_NUM=`echo ${CONTAINER_ENVS} | grep -o ',' | wc -l`
            for ((i=CONTAINER_ENVS_NUM; i>=0; i--))
            do
                if [ "x${CONTAINER_ENVS}" = 'x' ]; then
                    break
                fi
                FIELD=$((i+1))
                CONTAINER_ENVS_SET=`echo ${CONTAINER_ENVS} | cut -d ',' -f ${FIELD}`
                #
                CONTAINER_ENVS_SET_n=`echo ${CONTAINER_ENVS} | cut -d ',' -f ${FIELD} | cut -d = -f 1`
                CONTAINER_ENVS_SET_n=`echo ${CONTAINER_ENVS_SET_n}`
                #
                CONTAINER_ENVS_SET_v=`echo ${CONTAINER_ENVS} | cut -d ',' -f ${FIELD} | cut -d = -f 2`
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
                    # 组装
                    case "${CLUSTER}" in
                        swarm)
                            CONTAINER_ENVS_OK="${CONTAINER_ENVS_OK}  --env ${CONTAINER_ENVS_SET_n}=\"${CONTAINER_ENVS_SET_v}\""
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
            done
            #
            # for swarm
            CONTAINER_ENVS_OK=$( echo ${CONTAINER_ENVS_OK} )


            # 8 组装CMD
            CONTAINER_CMDS_OK=''
            #
            CONTAINER_CMDS_NUM=`echo ${CONTAINER_CMDS} | grep -o ',' | wc -l`
            for ((i=CONTAINER_CMDS_NUM; i>=0; i--))
            do
                if [ "x${CONTAINER_CMDS}" = 'x' ]; then
                    break
                fi
                FIELD=$((i+1))
                CONTAINER_CMDS_SET=`echo ${CONTAINER_CMDS} | cut -d ',' -f ${FIELD}`
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
            HOST_NAME_OK=""
            if [[ -n ${HOST_NAME} ]]; then
                # 正则校验
                #if [[ ! ${HOST_NAME} =~ ^(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$ ]]; then
                if [[ ! ${HOST_NAME} =~ ^[0-9a-z]([0-9a-z\-]{0,61}[0-9a-z])?(\.[0-9a-z](0-9a-z\-]{0,61}[0-9a-z])?)*$ ]]; then
                    echo -e "\n猪猪侠警告：主机名【${HOST_NAME}】不符合规范\n"
                    exit 52
                fi
                # 直接组装
                case ${CLUSTER} in
                    swarm)
                        HOST_NAME_OK="--hostname ${HOST_NAME}"
                        ;;
                    k8s)
                        sed -i "s/      hostname:.*/      hostname: ${HOST_NAME}/"  "${YAML_HOME}/${SERVICE_X_NAME}.yaml"
                        ;;
                    compose)
                        sed -i "s/    hostname:.*/    hostname: ${HOST_NAME}/"  "${YAML_HOME}/docker-compose.yaml"
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
                        ${HOST_NAME_OK}  \
                        ${DOCKER_IMAGE_FULL_URL}  \
                        ${CONTAINER_CMDS_OK}"
                    ;;
                k8s)
                    DOCKER_FULL_CMD="kubectl apply -f ${YAML_HOME}/${SERVICE_X_NAME}.yaml"
                    ;;
                compose)
                    #DOCKER_FULL_CMD="echo  \
                    #    ; ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                    #        \"[ ! -d ${COMPOSE_SERVICE_HOME} ] && mkdir -p ${COMPOSE_SERVICE_HOME}\"  \
                    #    ; rsync -r  -e \"ssh -p ${COMPOSE_SSH_PORT}\"  \
                    #        ${YAML_HOME}/docker-compose.yaml  \
                    #        ${COMPOSE_SSH_HOST_OR_WITH_USER}:${COMPOSE_SERVICE_HOME}/  \
                    #    && ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                    #        \"cd ${COMPOSE_SERVICE_HOME}  \
                    #        &&  docker-compose pull  \
                    #        &&  ${DOCKER_SERVICE_RM}  \
                    #        &&  docker-compose up -d\"
                    #   "
                    #
                    # 初始命令构建
                    DOCKER_FULL_CMD="ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER} \
                        '[ ! -d ${COMPOSE_SERVICE_HOME} ] && mkdir -p ${COMPOSE_SERVICE_HOME}' \
                        ; rsync -r -e 'ssh -p ${COMPOSE_SSH_PORT}' \
                        ${YAML_HOME}/docker-compose.yaml \
                        ${COMPOSE_SSH_HOST_OR_WITH_USER}:${COMPOSE_SERVICE_HOME}/ \
                        && ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER} \
                        'cd ${COMPOSE_SERVICE_HOME} "

                    # 检查并添加网络创建命令
                    if [ "${COMPOSE_NETWORK_IS_EXT}" = 'YES' ]; then
                        DOCKER_FULL_CMD+="&& if ! docker network ls --format '{{.Name}}' | grep -q '^${COMPOSE_NETWORK}$'; then docker network create ${COMPOSE_NETWORK}; fi "
                    fi

                    # 添加后续命令
                    DOCKER_FULL_CMD+="&& docker-compose pull \
                        && ${DOCKER_SERVICE_RM} \
                        && docker-compose up -d'"
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
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=53
                continue
            fi
            #
            if [ -n "${THIS_TAG}" ]; then
                # 更新指定完全匹配服务镜像
                F_SEARCH_IMAGE_TAG  ${SERVICE_NAME}  ${THIS_TAG}
                if [ $? -ne 0 ]; then
                    echo "${SERVICE_X_NAME} : 失败，镜像版本【${THIS_TAG}】未找到" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
                #
                DOCKER_IMAGE_TAG_UPDATE=${THIS_TAG}
                #
            elif [[ -n ${TIME_AGO} ]]; then
                ${DOCKER_IMAGE_SEARCH_SH}  ${IMAGE_PRE_NAME_ARG}  ${LIKE_THIS_TAG_ARG}  ${TIME_AGO_ARG}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_TIME_AGO_TAG-result.txt--${SERVICE_NAME}  ${SERVICE_NAME}
                DOCKER_IMAGE_TAG_UPDATE=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_TIME_AGO_TAG-result.txt--${SERVICE_NAME} | cut -d " " -f 3)
                if [[ -z ${DOCKER_IMAGE_TAG_UPDATE} ]]; then
                    echo "${SERVICE_X_NAME} : 失败，无匹配镜像【${LIKE_THIS_TAG_ARG} ${TIME_AGO_ARG}】" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
            elif [[ -z ${TIME_AGO} ]] && [[ -n ${LIKE_THIS_TAG} ]]; then
                ${DOCKER_IMAGE_SEARCH_SH}  ${IMAGE_PRE_NAME_ARG}  ${LIKE_THIS_TAG_ARG}  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_THIS_TAG-result.txt--${SERVICE_NAME}  ${SERVICE_NAME}
                # 可能有多个，但只取第一个
                DOCKER_IMAGE_TAG_UPDATE=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_THIS_TAG-result.txt--${SERVICE_NAME} | cut -d " " -f 3)
                if [[ -z ${DOCKER_IMAGE_TAG_UPDATE} ]]; then
                    echo "${SERVICE_X_NAME} : 失败，无匹配镜像【${LIKE_THIS_TAG_ARG}】" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=54
                    continue
                fi
            else
                # 更新今日发布的服务镜像
                TODAY=`date +%Y.%m.%d`
                ${DOCKER_IMAGE_SEARCH_SH}  ${IMAGE_PRE_NAME_ARG}  --tag ${TODAY}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_TODAY_TAG-result.txt--${SERVICE_NAME}  ${SERVICE_NAME}
                DOCKER_IMAGE_TAG_UPDATE=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_TODAY_TAG-result.txt--${SERVICE_NAME} | cut -d " " -f 3)
                if [[ -z ${DOCKER_IMAGE_TAG_UPDATE} ]]; then
                    echo "${SERVICE_X_NAME} : 跳过，今日无更新" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                    ERROR_CODE=55
                    continue
                fi
            fi
            #
            DOCKER_IMAGE_FULL_URL="${DOCKER_REPO_SERVER}/${DOCKER_IMAGE_PRE_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG_UPDATE}"
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
                        ; scp -P ${COMPOSE_SSH_PORT}  ${LOG_HOME}/${SERVICE_X_NAME}-update.sh  ${COMPOSE_SSH_HOST_OR_WITH_USER}:${COMPOSE_SERVICE_HOME}/  \
                        ; ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                            \"cd ${COMPOSE_SERVICE_HOME}  \
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
                echo "${SERVICE_X_NAME} : 失败，服务不在运行中" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=53
                continue
            fi
            #
            TODAY=`date +%Y.%m.%d`
            ${DOCKER_IMAGE_SEARCH_SH}  ${IMAGE_PRE_NAME_ARG}  --tag ${TODAY}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_TODAY_TAG-result.txt--${SERVICE_NAME}  ${SERVICE_NAME}
            DOCKER_IMAGE_TAG_TODAY=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_TODAY_TAG-result.txt--${SERVICE_NAME} | cut -d " " -f 3)
            #
            if [[ -z ${DOCKER_IMAGE_TAG_TODAY} ]]; then
                echo "${SERVICE_X_NAME} : 跳过，今日无更新" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=55
                continue
            else
                if [[ -n ${THIS_TAG} ]]; then
                    # 完全匹配服务镜像
                    F_SEARCH_IMAGE_TAG  ${SERVICE_NAME}  ${THIS_TAG}
                    if [ $? -ne 0 ]; then
                        echo "${SERVICE_NAME} : 失败，镜像版本【${THIS_TAG}】未找到" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                        ERROR_CODE=54
                        continue
                    fi
                    DOCKER_IMAGE_TAG_ROLLBACK=${THIS_TAG}
                elif [[ -n ${TIME_AGO} ]]; then
                    ${DOCKER_IMAGE_SEARCH_SH}  ${IMAGE_PRE_NAME_ARG}  ${LIKE_THIS_TAG_ARG}  ${TIME_AGO_ARG}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_TIME_AGO_TAG-result.txt--${SERVICE_NAME}  ${SERVICE_NAME}
                    DOCKER_IMAGE_TAG_ROLLBACK=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_TIME_AGO_TAG-result.txt--${SERVICE_NAME} | cut -d " " -f 3)
                    if [[ -z ${DOCKER_IMAGE_TAG_ROLLBACK} ]]; then
                        echo "${SERVICE_X_NAME} : 失败，无历史匹配镜像【${LIKE_THIS_TAG_ARG} ${TIME_AGO_ARG}】" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                        ERROR_CODE=54
                        continue
                    fi
                elif [[ -z ${TIME_AGO} ]] && [[ -n ${LIKE_THIS_TAG} ]]; then
                    ${DOCKER_IMAGE_SEARCH_SH}  ${IMAGE_PRE_NAME_ARG}  ${LIKE_THIS_TAG_ARG}  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_THIS_TAG-result.txt--${SERVICE_NAME}  ${SERVICE_NAME}
                    # 可能有多个，但只取第一个
                    DOCKER_IMAGE_TAG_ROLLBACK=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_LIKE_THIS_TAG-result.txt--${SERVICE_NAME} | cut -d " " -f 3)
                    if [[ -z ${DOCKER_IMAGE_TAG_ROLLBACK} ]]; then
                        echo "${SERVICE_X_NAME} : 失败，无历史匹配镜像【${LIKE_THIS_TAG_ARG}】" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                        ERROR_CODE=54
                        continue
                    fi
                else
                    ${DOCKER_IMAGE_SEARCH_SH}  ${IMAGE_PRE_NAME_ARG}  --exclude ${TODAY}  --newest 1  --output ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_NOT_TODAY_TAG-result.txt--${SERVICE_NAME}  ${SERVICE_NAME}
                    DOCKER_IMAGE_TAG_ROLLBACK=$(cat ${LOG_HOME}/${SH_NAME}-SEARCH_IMAGE_NOT_TODAY_TAG-result.txt--${SERVICE_NAME} | cut -d " " -f 3)
                    if [[ -z ${DOCKER_IMAGE_TAG_ROLLBACK} ]]; then
                        echo "${SERVICE_X_NAME} : 跳过，无历史镜像" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                        ERROR_CODE=55
                        continue
                    fi
                fi
            fi
            #
            DOCKER_IMAGE_FULL_URL="${DOCKER_REPO_SERVER}/${DOCKER_IMAGE_PRE_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG_ROLLBACK}"
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
                        ; scp -P ${COMPOSE_SSH_PORT}  ${LOG_HOME}/${SERVICE_X_NAME}-update.sh  ${COMPOSE_SSH_HOST_OR_WITH_USER}:${COMPOSE_SERVICE_HOME}/  \
                        ; ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                            \"cd ${COMPOSE_SERVICE_HOME}  \
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
                echo "跳过，脚本参数错误"
                echo "${SERVICE_X_NAME} : 跳过，脚本参数错误" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
                ERROR_CODE=51
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
                                \"cd ${COMPOSE_SERVICE_HOME}  \
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
                                \"cd ${COMPOSE_SERVICE_HOME}  \
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
                                \"cd ${COMPOSE_SERVICE_HOME}  \
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
        logs)
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
                        DOCKER_FULL_CMD="${DOCKER_FULL_CMD} ;  docker service logs -f ${GET_LINE}"
                        ;;
                    k8s)
                        DOCKER_FULL_CMD="${DOCKER_FULL_CMD} ;  echo '========== Deployments ==========' && kubectl logs -f deployments ${GET_LINE} ; echo ; echo '========== Services ==========' && kubectl describe services ${GET_LINE}"
                        ;;
                    compose)
                        DOCKER_FULL_CMD="echo  \
                            ; ssh -p ${COMPOSE_SSH_PORT} ${COMPOSE_SSH_HOST_OR_WITH_USER}  \
                                \"cd ${COMPOSE_SERVICE_HOME}  \
                                &&  docker-compose logs -f  \"
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
if ! [[ ${FUCK} == YES ]]; then
    exit
fi
#
if [[ ${SERVICE_OPERATION} =~ status|detail|logs ]]; then
    exit
fi


# 输出结果
#
# create:
# 53  "失败，服务已在运行中"
# 54  "失败，镜像版本【${DOCKER_IMAGE_TAG} 】未找到"
# update:
# 53  "失败，服务不在运行中"
# 55  "跳过，今日无更新"
# 54  "失败，镜像版本【${THIS_TAG}】未找到"
# 54  "失败，镜像版本【%${LIKE_THIS_TAG}%】未找到"
# rm:
# 53  "失败，服务不在运行中"
# scale
# 51  "跳过，脚本参数错误"
# 53  "失败，服务不在运行中"
# rollback:
# 53  "失败，服务不在运行中"
# 55  "跳过，今日无更新"
# 55  "跳过，无历史镜像"
# F_FUCK:
# 50  "成功"
# 54  "失败"
#
CHECK_DO_COUNT=${NUM}
SUCCESS_DO_COUNT=`cat ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE} | grep -o '成功' | wc -l`
NOTNEED_DO_COUNT=`cat ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE} | grep -o '跳过' | wc -l`
ERROR_DO_COUNT=`cat ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE} | grep -o '失败' | wc -l`
let NOT_DO_COUNT=${TOTAL_SERVICES}-${CHECK_DO_COUNT}
TIME_END=`date +%Y-%m-%dT%H:%M:%S`
case ${SH_RUN_MODE} in
    normal)
        #
        MESSAGE_END="DOCKER SERVICE ${SERVICE_OPERATION} 已完成！ 共企图 ${SERVICE_OPERATION} ${TOTAL_SERVICES} 个项目，成功 ${SERVICE_OPERATION} ${SUCCESS_DO_COUNT} 个项目，跳过 ${NOTNEED_DO_COUNT} 个项目，${ERROR_DO_COUNT} 个项目失败，因其他原因未执行 ${SERVICE_OPERATION} ${NOT_DO_COUNT} 个项目。"
        # 输出到屏幕及文件
        > ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "干：**${GAN_WHAT_FUCK}**" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "== DOCKER SERVICE ${SERVICE_OPERATION} 报告 ==" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo -e "${ECHO_REPORT}==================== DOCKER SERVICE ${SERVICE_OPERATION} 报告 ====================${ECHO_CLOSE}"
        #
        echo "所在环境：${RUN_ENV}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "造 浪 者：${MY_USER_XINGMING}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "造浪账号：${MY_USER_NAME}@${USER_INFO_FROM}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "发送邮箱：${MY_USER_EMAIL}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "开始时间：${TIME}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "结束时间：${TIME_END}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "镜像TAG ：${DOCKER_IMAGE_TAG}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "灰度标志：${GRAY_TAG}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "发布版本：${RELEASE_VERSION}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "${SERVICE_OPERATION}清单：" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        # 输出到文件
        echo "--------------------------------------------------" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        cat  ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}            >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        echo "--------------------------------------------------" >> ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        # 输出到屏幕
        ${FORMAT_TABLE_SH}  --delimeter ':'  --title "**服务名称**:**${SERVICE_OPERATION}**"  --file ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE}
        #
        echo "日志Local地址：${LOG_HOME}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
        #echo "日志Web地址：${LOG_DOWNLOAD_SERVER}/file/${DATE_TIME}" | tee -a ${DOCKER_CLUSTER_SERVICE_DEPLOY_HISTORY_CURRENT_FILE}
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
        ${DINGDING_SEND_DEPLOY_SH}  "【Info:${LOLLIPOP_PLATFORM_NAME}:${RUN_ENV}】" "${MSG[@]}" > /dev/null
        ;;
    function)
        #
        if [ `cat ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE} | wc -l` -eq 0 ]; then
            # 结果为空
            exit 59
        fi
        #
        cat  ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE} > ${DOCKER_CLUSTER_SERVICE_DEPLOY_OK_LIST_FILE_function}
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


