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
SERVICE_LIST_FILE="${SH_PATH}/docker-cluster-service.list"
SERVICE_LIST_FILE_TMP="/tmp/${SH_NAME}-docker-cluster-service.tmp.list.$(date +%S)"
SEARCH_RESULT_FILE="/tmp/${SH_NAME}-result.txt"
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
    用途：查询仓库清单、tag清单，删除仓库或tag
    依赖：
        ${SH_PATH}/env.sh
        ${SERVICE_LIST_FILE}
    注意：
        * 输入命令时，参数顺序不分先后
    用法:
        $0 [-h|--help]
        $0 [-l|--list-repo]  <-n|--name {%仓库名%}>                        #-- 列出仓库
        $0 [-L|--list-tag]   [-n|--name {%仓库名%}]  <-t {%镜像版本%}>     #-- 列出仓库tag
        $0 [-r|--rm-repo]    <-n|--name {%仓库名%}>                        #-- 删除仓库
        $0 [-R|--rm-tag]     [-n|--name {%仓库名%}]  <-t {%镜像版本%}>     #-- 删除仓库tag
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
        -o|--output     输出搜索结果到指定【路径/文件】
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
        $0  -R  -n ^imageX  -t 2023.04.*tt$      #-- 删除正则匹配【^imageX】的仓库里，正则匹配【2023.04.*tt$】的tag
    "
}




# 输出匹配仓库名
# 用法：F_GET_REPO <%仓库名%>
F_GET_REPO()
{
    F_REPO_NAME=$1
    F_REPO_LIST_FILE="/tmp/${SH_NAME}-F_GET_REPO-list.txt--${F_REPO_NAME}"
    F_GET_ERR_FILE="/tmp/${SH_NAME}-F_GET_REPO-err.txt--${F_REPO_NAME}"
    > ${F_REPO_LIST_FILE}
    curl -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD} -s -X GET ${DOCKER_REPO_URL_BASE}/_catalog  > ${F_REPO_LIST_FILE}
    if [[ $? -ne 0 ]]; then
        echo -e "\n猪猪侠警告：访问【${DOCKER_REPO_SERVER}】服务器异常\n" 1>&2
        return 53
    fi
    #
    # 仓库极少可能为空
    #
    cat ${F_REPO_LIST_FILE} | jq .repositories[] | sed 's/"//g' | sed '/^\s*$/d' > ${F_REPO_LIST_FILE}.1
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
    F_REPO_TAG=$2
    F_REPO_TAG_LIST_FILE="/tmp/${SH_NAME}-F_GET_REPO_TAG-list.txt--${F_REPO_NAME}"
    F_REPO_TAG_ERR_FILE="/tmp/${SH_NAME}-F_GET_REPO_TAG-err.txt--${F_REPO_NAME}"
    > ${F_REPO_TAG_LIST_FILE}
    curl -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD} -s -X GET ${DOCKER_REPO_URL_BASE}/${F_REPO_NAME}/tags/list  > ${F_REPO_TAG_LIST_FILE}
    if [[ $? -ne 0 ]]; then
        echo -e "\n猪猪侠警告：访问【${DOCKER_REPO_SERVER}】服务器异常\n" 1>&2
        return 53
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
    cat ${F_REPO_TAG_LIST_FILE} | jq .tags[] | grep -v 'latest' | sed 's/"//g' | sed '/^\s*$/d'  > ${F_REPO_TAG_LIST_FILE}.1
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
    F_GET_REPO_TAG_HEAD_FILE="/tmp/${SH_NAME}-F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST-head.txt--${F_REPO_NAME}"
    F_GET_REPO_TAG_BODY_FILE="/tmp/${SH_NAME}-F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST-body.txt--${F_REPO_NAME}"
    > ${F_GET_REPO_TAG_HEAD_FILE}
    > ${F_GET_REPO_TAG_BODY_FILE}
    curl -s -v -X GET  \
        -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD}  \
        -H 'Accept: application/vnd.docker.distribution.manifest.v2+json'  \
        ${DOCKER_REPO_URL_BASE}/${F_REPO_NAME}/manifests/${F_REPO_TAG}  > ${F_GET_REPO_TAG_BODY_FILE}  2>${F_GET_REPO_TAG_HEAD_FILE}
    if [[ $? -ne 0 ]]; then
        echo -e "\n猪猪侠警告：访问【${DOCKER_REPO_SERVER}】服务器异常\n" 1>&2
        return 53
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
        echo -e "\n猪猪侠警告：仓库tag不存在，提示：【MANIFEST_UNKNOWN】\n" 1>&2
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
    F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST_FILE="/tmp/digest-and-blob.txt--${F_REPO_NAME}"
    F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST  ${F_REPO_NAME}  ${F_REPO_TAG}  > ${F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST_FILE}
    ERR_NO=$?
    if [[ ${ERR_NO} != 0 ]]; then
        return ${ERR_NO}
    fi
    #
    F_REPO_TAG_DIGEST=$(cat ${F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST_FILE} | awk '{print $1}')
    F_REPO_TAG_BLOB_DIGEST=$(cat ${F_GET_REPO_TAG_DIGEST_AND_TAGBLOB_DIGEST_FILE} | awk '{print $2}')
    #if [[ -z ${F_REPO_TAG_DIGEST} ]] || [[ -z ${F_REPO_TAG_BLOB_DIGEST} ]]; then
    #    echo -e "\n猪猪侠警告：仓库tag不存在\n" 1>&2
    #    return 53
    #fi
    #
    # 如果两个tag对应的是同一个 blob及manifest ，则第一个tag删除成功后，第二个tag就不存在了，所以再删除第二个会失败
    # del blob
    curl  -s -X DELETE  \
        -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD}  \
        ${DOCKER_REPO_URL_BASE}/${F_REPO_NAME}/blobs/${F_REPO_TAG_BLOB_DIGEST}
    # del manifest
    curl  -s -X DELETE  \
        -u ${DOCKER_REPO_USER}:${DOCKER_REPO_PASSWORD}  \
        ${DOCKER_REPO_URL_BASE}/${F_REPO_NAME}/manifests/${F_REPO_TAG_DIGEST}
    return 0
}




# 参数检查
TEMP=`getopt -o hlLrRn:t:  -l help,list-repo,list-tag,rm-repo,rm-tag,name:,tag:  -- "$@"`
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
            ;;
        -R|--rm-tag)
            ACTION='rm-tag'
            shift
            ;;
        -n|--name)
            LIKE_THIS_NAME=$2
            shift 2
            ;;
        -t|--tag)
            LIKE_THIS_TAG=$2
            shift 2
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
        REPO_LIST_TMP="/tmp/${SH_NAME}-repo.list.tmp"
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
        echo "没搞"
        ;;
    rm-tag)
        REPO_LIST_TMP="/tmp/${SH_NAME}-repo.list.tmp"
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
            REPO_TAG_LIST_TMP="/tmp/${SH_NAME}-repo-tag.list.tmp"
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
            while read T
            do
                echo "++++++++++++++++++++++++++++++"
                echo "删除：仓库【${R}】- tag【${T}】"
                #
                # 如果两个tag对应的是同一个 blob及manifest ，则第一个tag删除成功后，第二个tag就不存在了，所以再删除第二个会失败
                # 所以，如何确保正确删除？
                # 以后有时间再解决！！！
                F_DELETE_REPO_TAG  ${R}  ${T}
                if [[ $? != 0 ]]; then
                    echo -e "\n猪猪侠警告：删除【${R}:${T}】时出错了！\n"
                    exit 1
                fi
                echo "OK"
            done < ${REPO_TAG_LIST_TMP}--${R_SED}
        done < ${REPO_LIST_TMP}
        #
        ;;
    *)
        echo -e "\n猪猪侠警告：缺少主要运行参数或参数不合法，请看帮助！\n"
        return 52
        ;;
esac



