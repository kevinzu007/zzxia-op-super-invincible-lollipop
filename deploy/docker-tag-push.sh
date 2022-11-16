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

# 引入env
. ${SH_PATH}/deploy.env
#DOCKER_REPO=
#DOCKER_REPO_USER=
#DOCKER_REPO_PASSWORD=
#DOCKER_IMAGE_BASE=

# 本地env
TIME=${TIME:-`date +%Y-%m-%dT%H:%M:%S`}
TIME_START=${TIME}
#
IMAGE_VER=$(date -d "${TIME}" +%Y.%m.%d.%H%M%S)
PROJECT_LIST_FILE="${SH_PATH}/project.list"
PROJECT_LIST_FILE_TMP="/tmp/${SH_NAME}-project.tmp.list.$(date +%S)"
# sh
FORMAT_TABLE_SH="${SH_PATH}/../op/format_table.sh"


# 删除空行（以及只有tab、空格的行）
#sed -i '/^\s*$/d'  ${PROJECT_LIST_FILE}
## 删除行中的空格
#sed -i 's/[ \t]*//g'  ${PROJECT_LIST_FILE}


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
    用途：为项目镜像打版本号，并推送到docker仓库（推送 明确版本 + latest版本）
    依赖：
        ${SH_PATH}/deploy.env
        ${PROJECT_LIST_FILE}
    注意:
        * 输入命令时，参数顺序不分先后
    用法:
        $0  [-h|--help]
        $0  [-l|--list]
        $0  [-t|--tag {版本号}]  <{项目1}  {项目2} ... {项目n}>
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -l|--list       项目镜像列表
        -t|--tag        设置镜像版本号，默认版本号为：【日期+时间】
    示例：
        $0  -h
        $0  -l
        #
        $0                            #--- 为所有项目的镜像设置默认版本号，并推送到docker仓库
        $0  -t 1.11  项目a 项目b      #--- 设置【项目a、项目b】的版本号为【1.11】，并推送到docker仓库
        $0           项目a 项目b      #--- 设置【项目a、项目b】的版本号为默认版本号，并推送到docker仓库
    "
}



# 参数检查
TEMP=`getopt -o hlt:  -l help,list,tag: -- "$@"`
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
            echo '**项目名** | **镜像名**'  > /tmp/docker-tag-push-for-list.txt
            cat  ${PROJECT_LIST_FILE} | grep -v '^#' | grep  'docker_image' | awk  'BEGIN {FS="|"} {printf "%s | %s\n", $3,$6}' >> /tmp/docker-tag-push-for-list.txt
            ${FORMAT_TABLE_SH}  --delimeter '|'  --file /tmp/docker-tag-push-for-list.txt
            exit
            ;;
        -t|--tag)
            IMAGE_VER=$2
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



# 待搜索项目清单
> "${PROJECT_LIST_FILE_TMP}"
## 参数个数
if [[ $# -eq 0 ]]; then
    cp  ${PROJECT_LIST_FILE}  ${PROJECT_LIST_FILE_TMP}
else
    # 指定项目
    for i in "$@"
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
            if [ "x${PROJECT_NAME}" = "x$i" ]; then
                echo $LINE >> ${PROJECT_LIST_FILE_TMP}
                GET_IT='YES'
                break
            fi
        done < ${PROJECT_LIST_FILE}
        #
        if [[ $GET_IT != 'YES' ]]; then
            echo -e "\n猪猪侠警告：项目【${i}】不在项目列表【${PROJECT_LIST_FILE}】中，请检查！\n"
            exit 51
        fi
    done
fi
# 加表头
sed -i  '1i#| **类别** | **项目名** | **构建方法** | **输出方法** | **镜像名** | **链接node_project** | **GOGOGO发布方式** | **优先级** |'  ${PROJECT_LIST_FILE_TMP}



# login
echo "${DOCKER_REPO_PASSWORD}" | docker login -u "$DOCKER_REPO_USER" --password-stdin  ${DOCKER_REPO}  > /dev/null 2>&1


# 开始
echo ""
i=0
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    PJ_NAME=`echo ${LINE} | cut -d \| -f 3`
    PJ_NAME=`echo ${PJ_NAME}`
    IMAGE_NAME=`echo ${LINE} | cut -d \| -f 6`
    IMAGE_NAME=`echo ${IMAGE_NAME}`
    #
    # docker tag + push
    i=`expr $i + 1`
    echo -e "${ECHO_NORMAL}-------------------------------------------------${ECHO_CLOSE}"
    echo -e "${ECHO_NORMAL}$i - ${PJ_NAME} - ${IMAGE_NAME} :${ECHO_CLOSE}"
    echo -e "${ECHO_NORMAL}-------------------------------------------------${ECHO_CLOSE}"
    echo ""
    # latest版
    docker tag   ${IMAGE_NAME}:latest  ${DOCKER_IMAGE_BASE}/${IMAGE_NAME}:latest
    docker push  ${DOCKER_IMAGE_BASE}/${IMAGE_NAME}:latest
    # 特定版本号
    docker tag   ${IMAGE_NAME}:latest  ${DOCKER_IMAGE_BASE}/${IMAGE_NAME}:${IMAGE_VER}
    docker push  ${DOCKER_IMAGE_BASE}/${IMAGE_NAME}:${IMAGE_VER}
    if [[ $? -ne 0 ]]; then
        echo -e "\n猪猪侠警告：项目【${PJ_NAME}】镜像PUSH失败，请检查！\n"
        return 54
    fi
done < ${PROJECT_LIST_FILE_TMP}


echo -e "\nPUSH 完成！"
echo -e "IMAGE版本号为：\n    ${IMAGE_VER}\n    latest"

