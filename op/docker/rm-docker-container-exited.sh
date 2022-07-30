#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7


#docker ps -a | grep -v 'CONTAINER' | grep -v 'Up'
#yy=$?
#
#if [ $yy = 0 ] ;then
#    docker ps -a | grep -v 'CONTAINER' | grep -v 'Up' | awk '{print $1}' | xargs docker rm
#    echo 'OK containers had delete'
#else
#    echo 'no containers in "Exit" status'
#fi


# 指定用户下运行
if [ ${USER} != 'root' ]; then
    echo '请在root用户下运行！'
    exit 1
fi

# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 引入env

# 本地env



# 帮助
F_HELP()
{
    echo "
    用途：删除已经退出docker容器
    依赖：
    注意：
        * 输入命令时，参数顺序不分先后
    用法：
        $0 [-h|--help]
        $0 <-q|--quiet>  [ <-k|--keyword {关键字}>  <-t|--tag {镜像tag}>  <-d|--days {天数}> ]
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        #
        -h|--help           此帮助
        -f|--filter         过滤条件(e.g. 'until=<timestamp>')
        -q|--quiet          静默方式
    示例：
        $0 -k gcl          #--- 删除镜像名称中包含字符【gcl】的所有镜像
    "
}


# 参数检查
TEMP=`getopt -o hf:q  -l help,filter:,quiet -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 1
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
        -f|--filter)
            FILTER="--filter $2" 
            shift 2
             ;;
        -q|--quiet)
            QUIET='--force'
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo -e "\n猪猪侠警告：未知参数，请查看帮助【$0 --help】\n"
            exit 1
            ;;
    esac
done


docker container prune  ${FILTER}  ${QUIET}




