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
. ${SH_PATH}/../deploy/env.sh
#DOCKER_REPO_USER=
#DOCKER_REPO_PASSWORD=
#DOCKER_REPO_SERVER=
#DOCKER_REPO_URL_BASE=

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
SAFETY_OPT='N'          #-- 一个镜像ID与多个标签关联时，仍然删除，无API支持
LOG_HOME="/tmp/${SH_NAME}"


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
    用途：查询仓库清单或tag清单，删除仓库或tag
    依赖：
        ${SH_PATH}/env.sh
    注意：
        * 输入命令时，参数顺序不分先后
    用法:
        $0 [-h|--help]
        $0 [-l|--list-repo]  <-n|--name {%仓库名%}>                                                                #-- 列出仓库
        $0 [-L|--list-tag]   <-n|--name {%仓库名%}>  <-t|--tag {%镜像标签%}>                                       #-- 列出仓库tag
        $0 [-r|--rm-repo]    <-n|--name {%仓库名%}>                                                                #-- 删除仓库，无API，假的
        $0 [-R|--rm-tag]     <-n|--name {%仓库名%}>  <-t|--tag {%镜像标签%}>  <-k|--keep {数量}>  <-s|--safety>    #-- 删除仓库tag
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是一个整体，是必选项，默认是必选项（即没有括号【[]、<>】时也是必选项），一般用于表示参数对，此时不可乱序，单个参数也可以使用括号
        <>   : 代表是一个整体，是可选项，默认是必选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help       此帮助
        -l|--list-repo  列出仓库清单
        -L|--list-tag   列出仓库tag清单
        -r|--rm-repo    删除仓库
        -R|--rm-tag     删除仓库tag
        -n|--name       仓库(镜像)名，支持正则
        -t|--tag        版本tag，支持正则
        -k|--keep       保留最新tag数量
        -s|--safety     安全执行，默认：直接删除镜像标签对应的【manifest】镜像ID，如果镜像标签的manifest镜像ID与多个镜像标签关联，则相关标签也会一并删除。如果启用此参数，则会跳过。悲剧是无相关API支持，假的。但是如果你一定要安全执行的化，你可以直接登录到 docker registry 服务器上，直接删除相关仓库目录，比如删除【redis】的【7.0】镜像标签： rm -f {docker_registry的data路径}/docker/registry/v2/repositories/public/redis/_manifests/tags/7.0，删除之后，在服务器上运行资源回收命令就会清理掉相关的Blob资源，实现空间释放！
    示例：
        $0  -h
        # 列出
        $0  -l                             #-- 列出所有仓库
        $0  -l  -n imageX                  #-- 列出正则匹配【imageX】的仓库
        $0  -L  -n imageX                  #-- 列出正则匹配【imageX】的仓库的tag
        $0  -L  -n imageX  -t 2023.04      #-- 列出正则匹配【imageX】的仓库里，正则匹配【2023.04】的tag
        # 删除
        $0  -r                             #-- 删除所有仓库
        $0  -r  -n imageX                  #-- 删除正则匹配【imageX】的仓库
        $0  -R  -n imageX                  #-- 删除正则匹配【imageX】的仓库的tag
        $0  -R  -n imageX  -t 2023.04      #-- 删除正则匹配【imageX】的仓库里，正则匹配【2023.04】的tag
        $0  -R  -n ^imageX  -t 2023.04.*tt$    #-- 删除正则匹配【^imageX】的仓库里，正则匹配【2023.04.*tt$】的tag
        $0  -R  -n imageX  -k 3                #-- 删除正则匹配【imageX】的仓库的tag，但保留最近3个tag
        $0  -R  -k 3                           #-- 删除所有仓库的tag，但保留最近3个tag
        $0  -R  -k 3  -f                       #-- 删除所有仓库的tag，但保留最近3个tag，安全方式执行，无API支持，假的
    "
}




# 输出匹配仓库名
# 用法：F_GET_REPO <%仓库名%>
F_GET_REPO()
{
    F_REPO_NAME=$1      #-- 可以为空
    F_REPO_LIST_FILE="${LOG_HOME}/F_GET_REPO-list.txt"
    F_GET_ERR_FILE="${LOG_HOME}/F_GET_REPO-err.txt"
    > ${F_REPO_LIST_FILE}
    curl -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD} -s -X GET ${DOCKER_REPO_URL_BASE}/_catalog  > ${F_REPO_LIST_FILE}
    if [[ $? -ne 0 ]]; then
        echo -e "\n猪猪侠警告：访问【${DOCKER_REPO_SERVER}】服务器异常\n" 1>&2
        return 54
    fi
    #
    # 仓库极少可能为空
    #
    cat ${F_REPO_LIST_FILE} | jq .repositories[] | sed 's/"//g' | sed '/^\s*$/d' | sort  > ${F_REPO_LIST_FILE}.1
    #
    # 过滤
    if [[ -n ${F_REPO_NAME} ]]; then
        # 输出
        grep -E "${F_REPO_NAME}"  ${F_REPO_LIST_FILE}.1
        if [[ $? != 0 ]]; then
            return 55
        else
            return 0
        fi
    else
        if [[ $(cat ${F_REPO_LIST_FILE}.1 | wc -l) == 0 ]]; then
            return 55
        else
            # 输出
            cat  ${F_REPO_LIST_FILE}.1
            return 0
        fi
    fi
}


# 输出所有匹配的仓库tag
# 用法：F_GET_REPO_TAG  [{仓库名}]  <{%tag%}>
F_GET_REPO_TAG()
{
    F_REPO_NAME=$1
    F_REPO_TAG=$2      #-- 可以为空
    #
    F_REPO_NAME_SED=${R//\//_}
    F_REPO_TAG_LIST_FILE="${LOG_HOME}/F_GET_REPO_TAG-list.txt--${F_REPO_NAME_SED}"
    F_REPO_TAG_ERR_FILE="${LOG_HOME}/F_GET_REPO_TAG-err.txt--${F_REPO_NAME_SED}"
    > ${F_REPO_TAG_LIST_FILE}
    curl -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD} -s -X GET ${DOCKER_REPO_URL_BASE}/${F_REPO_NAME}/tags/list  > ${F_REPO_TAG_LIST_FILE}
    if [[ $? -ne 0 ]]; then
        echo -e "\n猪猪侠警告：访问【${DOCKER_REPO_SERVER}】服务器异常\n" 1>&2
        return 54
    fi
    #
    # 理论上不会出现下面情况
    #if [[ $(cat ${F_REPO_TAG_LIST_FILE} | grep -q '404 page not found' ; echo $?) == 0 ]]; then
    if [[ $(cat ${F_REPO_TAG_LIST_FILE} | grep -q 'repository name not known to registry' ; echo $?) == 0 ]]; then
        echo -e "\n猪猪侠警告：仓库【${F_REPO_NAME}】不存在\n" 1>&2
        return 53
    fi
    #
    if [[ $(cat ${F_REPO_TAG_LIST_FILE} | grep -q '"tags":null' ; echo $?) == 0 ]]; then
        # tags 为空
        return 55
    fi
    #
    cat ${F_REPO_TAG_LIST_FILE} | jq .tags[] | sed 's/"//g' | sed '/^\s*$/d' | sort  > ${F_REPO_TAG_LIST_FILE}.1
    #
    # 过滤
    if [[ -n ${F_REPO_TAG} ]]; then
        # 输出
        grep -E "${F_REPO_TAG}"  ${F_REPO_TAG_LIST_FILE}.1
        if [[ $? != 0 ]]; then
            return 55
        else
            return 0
        fi
    else
        if [[ ! -s ${F_REPO_TAG_LIST_FILE}.1 ]]; then
            return 55
        else
            # 输出
            cat  ${F_REPO_TAG_LIST_FILE}.1
            return 0
        fi
    fi
}



# 输出仓库 tag digest 及 tag blob digest
# 用法：F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST  [{仓库名}]  [{tag}]
F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST()
{
    F_REPO_NAME=$1
    F_REPO_TAG=$2
    F_GET_REPO_TAG_HEAD_FILE="${LOG_HOME}/F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST-head.txt--${F_REPO_NAME}"
    F_GET_REPO_TAG_BODY_FILE="${LOG_HOME}/F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST-body.txt--${F_REPO_NAME}"
    > ${F_GET_REPO_TAG_HEAD_FILE}
    > ${F_GET_REPO_TAG_BODY_FILE}
    curl -s -v -X GET  \
        -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD}  \
        -H 'Accept: application/vnd.docker.distribution.manifest.v2+json'  \
        ${DOCKER_REPO_URL_BASE}/${F_REPO_NAME}/manifests/${F_REPO_TAG}  > ${F_GET_REPO_TAG_BODY_FILE}  2>${F_GET_REPO_TAG_HEAD_FILE}
    if [[ $? -ne 0 ]]; then
        echo -e "\n猪猪侠警告：访问【${DOCKER_REPO_SERVER}】服务器异常\n" 1>&2
        return 54
    fi
    # 删除特殊字符【^M】等
    sed  -i -E  -e "s/\\x1B\[([0-9]{1,2}(;[0-9]{1,2})?){0,2}[m|A-Z]//g"  -e "s/\\x0D//g"  ${F_GET_REPO_TAG_HEAD_FILE}
    #
    if [[ $(cat ${F_GET_REPO_TAG_BODY_FILE} | grep -q '404 page not found' ; echo $?) == 0 ]]; then
        echo -e "\n猪猪侠警告：仓库不存在，提示：【404 page not found】\n" 1>&2
        return 53
    fi
    #
    if [[ $(cat ${F_GET_REPO_TAG_BODY_FILE} | grep -q 'MANIFEST_UNKNOWN' ; echo $?) == 0 ]]; then
        echo -e "\n猪猪侠警告：仓库tag不存在，提示：【MANIFEST_UNKNOWN】，可能此TAG与其他已删除的TAG关联到同一个镜像ID造成\n" 1>&2
        return 53
    fi
    #
    F_REPO_TAG_DIGEST=$(cat ${F_GET_REPO_TAG_HEAD_FILE} | grep 'Docker-Content-Digest' | head -n 1 | awk '{print $3}')
    F_REPO_TAGBLOB_DIGEST=$(cat ${F_GET_REPO_TAG_BODY_FILE} | grep 'digest' | head -n 1 | awk '{print $2}' | sed 's/"//g')
    #
    echo  ${F_REPO_TAG_DIGEST}  ${F_REPO_TAGBLOB_DIGEST}
    return 0
}



# 删除仓库
# 用法：F_DELETE_REPO  [{仓库名}]
F_DELETE_REPO()
{
    F_REPO_NAME=$1
}



# 删除仓库tag
# 用法：F_DELETE_REPO_TAG  [{仓库名}]  [{tag}]
F_DELETE_REPO_TAG()
{
    F_REPO_NAME=$1
    F_REPO_TAG=$2
    F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST_FILE="${LOG_HOME}/repo-tag-digest-and-blob.txt"
    > ${F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST_FILE}
    F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST  ${F_REPO_NAME}  ${F_REPO_TAG}  > ${F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST_FILE}
    ERR_NO=$?
    if [[ ${ERR_NO} != 0 ]]; then
        # 如果仓库或标签不存在，直接返回
        if [[ ${ERR_NO} == 53 ]]; then
            #echo -e "\n猪猪侠警告：仓库或标签TAG不存在\n" 1>&2
            return 0
        else
            return ${ERR_NO}
        fi
    fi
    #
    # 多个标签TAG可以关联同一个【manifest】镜像ID；一个【manifest】镜像ID关联多个镜像实体Blob层（实际数据，非常占空间）；多个【manifest】镜像ID可能共享部分Blob层，这个理解很重要！
    #
    # 如果一个【manifest】镜像ID与两个标签TAG关联，此时执行删除这个【manifest】镜像ID，那么与之对应的这两个标签TAG也会被删除。
    # 删除标签的【manifest】镜像ID对应的【blob】，就是删除镜像ID对应的所有实体Blob层。如果这些Blob层有一些被其他【manifest】镜像ID关联，那么关联的其他镜像将会异常，所以不推荐使用这种方式清理镜像实体Blob来达到清理空间的目的，而是在服务器上运行`docker exec -it docker_registry_container_id  registry garbage-collect /etc/docker/registry/config.yml`，实现自动清理没有关联【manifest】的【blob】，实现垃圾回收。
    #
    # 注意：如果你非要手动删除blob，则你需要先删除blob，再删除manifest，否则会出错！！！
    # 所以：我们只需要删除标签的【manifest】镜像ID，【blob】由服务器自动处理就好了；还有，如果连个标签TAG关联同一个镜像ID，删除其中一个标签TAG，另外一个也会消失，这个你必须要知道，官方没有好的解决办法！

    # 删除【blob】
    #
    #F_REPO_TAG_BLOB_DIGEST=$(cat ${F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST_FILE} | awk '{print $2}')
    #curl  -s -X DELETE  \
    #    -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD}  \
    #    ${DOCKER_REPO_URL_BASE}/${F_REPO_NAME}/blobs/${F_REPO_TAG_BLOB_DIGEST}

    # 删除【manifest】镜像ID
    #
    F_REPO_TAG_DIGEST=$(cat ${F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST_FILE} | awk '{print $1}')
    #
    ## 这些是ChatGPT给我瞎胡闹的，docker registry并没有提供相关API，服了，注释掉他
    ## 镜像ID关联多个标签时，是否强制删除
    #if [[ ${SAFETY_OPT} = "Y" ]]; then
    #    # 获取所有指向相同镜像 ID 的标签
    #    F_RELATED_TAGS=$(curl -s -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD} -X GET ${DOCKER_REPO_URL_BASE}/${F_REPO_NAME}/manifests/${F_REPO_TAG_DIGEST} | jq -r '.tag[]' | grep -v "${F_REPO_TAG}")
    #    # 检查是否有其他标签指向相同的镜像 ID
    #    if [[ -n "${F_RELATED_TAGS}" ]]; then
    #        echo -e "\n猪猪侠警告：跳过删除标签${F_REPO_TAG}，因为有其他标签指向相同的镜像 ID。相关标签：${F_RELATED_TAGS}\n" 1>&2
    #        return 0
    #    fi
    #fi
    #
    curl  -s -X DELETE  \
        -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD}  \
        ${DOCKER_REPO_URL_BASE}/${F_REPO_NAME}/manifests/${F_REPO_TAG_DIGEST}
    return 0
}



# 参数检查
TEMP=`getopt -o hlLrRn:t:k:s  -l help,list-repo,list-tag,rm-repo,rm-tag,name:,tag:,keep:,safety  -- "$@"`
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
        -l|--list-repo)
            ACTION='list-repo'
            shift
            ;;
        -L|--list-tag)
            ACTION='list-tag'
            shift
            ;;
        -r|--rm-repo)
            ACTION='rm-repo'
            shift
            echo "Docker registry未提供相关API，搞不了！"
            echo 
            echo "但是，你可以直接登录到 docker registry 服务器上，直接删除相关仓库目录，比如redis： rm -rf {docker_registry的data路径}/docker/registry/v2/repositories/public/redis，删除之后，在服务器上运行资源回收命令就会清理掉相关的Blob资源，实现空间释放！"
            exit
            ;;
        -R|--rm-tag)
            ACTION='rm-tag'
            shift
            ;;
        -n|--name)
            # ${LIKE_THIS_NAME} 为空，则匹配所有
            LIKE_THIS_NAME=$2
            shift 2
            ;;
        -t|--tag)
            # ${LIKE_THIS_TAG} 为空，则匹配所有
            LIKE_THIS_TAG=$2
            shift 2
            ;;
        -k|--keep)
            # ${KEEP_TAG_NUM}为空，则保留0个
            KEEP_TAG_NUM=$2
            shift 2
            grep -q '^[[:digit:]]\+$' <<< ${KEEP_TAG_NUM}
            if [ $? -ne 0 ]; then
                echo -e "\n猪猪侠警告：参数【-k|--keep】参数不合法，请查看帮助【$0 --help】\n"
                exit 51
            fi
            ;;
        -s|--safety)
            SAFETY_OPT='Y'
            shift
            echo "Docker registry未提供相关API，搞不了！"
            echo.
            echo "但是，你可以直接登录到 docker registry 服务器上，直接删除相关仓库目录，比如删除【redis】的【7.0】镜像标签： rm -rf {docker_registry的data路径}/docker/registry/v2/repositories/public/redis/_manifests/tags/7.0，删除之后，在服务器上运行资源回收命令就会清理掉相关的Blob资源，实现空间释放！"
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


# 建立base目录
[ -d "${LOG_HOME}" ] || mkdir -p  "${LOG_HOME}"


#
case ${ACTION} in
    list-repo)
        F_GET_REPO  ${LIKE_THIS_NAME}
        r=$?
        if [[ $r == 55 ]]; then
            echo -e "\n猪猪侠警告：匹配仓库【${LIKE_THIS_NAME}】结果为空！\n"
        elif [[ $r != 0 ]]; then
            echo -e "\n猪猪侠警告：匹配仓库【${LIKE_THIS_NAME}】时出错了！\n"
            exit 1
        fi
        ;;
    list-tag)
        REPO_LIST_TMP="${LOG_HOME}/repo.list.tmp"
        > ${REPO_LIST_TMP}
        #
        F_GET_REPO  ${LIKE_THIS_NAME}  > ${REPO_LIST_TMP}
        r=$?
        if [[ $r == 55 ]]; then
            echo -e "\n猪猪侠警告：匹配仓库【${LIKE_THIS_NAME}】结果为空！\n"
        elif [[ $r != 0 ]]; then
            echo -e "\n猪猪侠警告：匹配仓库【${LIKE_THIS_NAME}】时出错了！\n"
            exit 1
        fi
        #
        N=0
        while read R
        do
            let N=$N+1
            echo "=================================================="
            echo "$N 仓库：${R}:"
            #
            F_GET_REPO_TAG  ${R}  ${LIKE_THIS_TAG}
            r=$?
            if [[ $r == 55 ]]; then
                echo -e "\n猪猪侠警告：匹配TAG【${LIKE_THIS_TAG}】结果为空！\n"
            elif [[ $r != 0 ]]; then
                echo -e "\n猪猪侠警告：匹配TAG【${LIKE_THIS_TAG}】时出错了！\n"
                #exit 1
            fi
        done < ${REPO_LIST_TMP}
        #
        ;;
    rm-repo)
        echo "Docker registry未提供相关API"
        ;;
    rm-tag)
        REPO_LIST_TMP="${LOG_HOME}/repo.list.tmp"
        > ${REPO_LIST_TMP}
        #
        F_GET_REPO  ${LIKE_THIS_NAME}  > ${REPO_LIST_TMP}
        r=$?
        if [[ $r == 55 ]]; then
            echo -e "\n猪猪侠警告：匹配仓库【${LIKE_THIS_NAME}】结果为空！\n"
        elif [[ $r != 0 ]]; then
            echo -e "\n猪猪侠警告：匹配仓库【${LIKE_THIS_NAME}】时出错了！\n"
            exit 1
        fi
        #
        N=0
        while read R
        do
            let N=$N+1
            REPO_TAG_LIST_TMP="${LOG_HOME}/repo-tag.list.tmp"
            #
            echo "=================================================="
            echo "$N 仓库：${R}"
            R_SED=${R//\//_}
            #
            > ${REPO_TAG_LIST_TMP}--${R_SED}
            F_GET_REPO_TAG  ${R}  ${LIKE_THIS_TAG}  > ${REPO_TAG_LIST_TMP}--${R_SED}
            r=$?
            if [[ $r == 55 ]]; then
                echo -e "\n猪猪侠警告：匹配TAG【${LIKE_THIS_TAG}】结果为空！\n"
            elif [[ $r != 0 ]]; then
                echo -e "\n猪猪侠警告：匹配TAG【${LIKE_THIS_TAG}】时出错了！\n"
                exit 1
            fi
            #
            LINE_TOTAL=$(cat ${REPO_TAG_LIST_TMP}--${R_SED} | wc -l)
            KEEP_TAG_NUM=${KEEP_TAG_NUM:-0}
            LINE=0
            while read T
            do
                #echo "++++++++++++++++++++++++++++++"
                let LINE=${LINE}+1
                let DEL_REMAIN_NUM=${LINE_TOTAL}-${LINE}
                if [[ ${DEL_REMAIN_NUM} -ge ${KEEP_TAG_NUM} ]]; then
                    echo "OK  删除【${R}:${T}】"
                    F_DELETE_REPO_TAG  ${R}  ${T}
                    if [[ $? != 0 ]]; then
                        echo -e "\n猪猪侠警告：删除【${R}:${T}】时出错了！\n"
                        exit 1
                    fi
                else
                    break
                fi
            done < ${REPO_TAG_LIST_TMP}--${R_SED}
        done < ${REPO_LIST_TMP}
        #
        ;;
    *)
        echo -e "\n猪猪侠警告：缺少主要运行参数或参数不合法，请看帮助！\n"
        return 52
        ;;
esac



