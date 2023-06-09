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


# 用法：
F_HELP()
{
    echo "
    用途：启动、停止、重启服务
    依赖：
    注意：运行在deploy节点上
    用法:
        $0  [-h|--help]
        $0  [-u|--up|-d|--down|-r|--restart]   #-- 启动、停止、重启服务
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help        此帮助
        -u|--up          启动服务
        -d|--down        停止服务
        -r|--restart     重启服务
    示例:
        $0  -u        #--- 启动服务
        $0  -d        #--- 停止服务
        $0  -r        #--- 重启服务
    "
}


case $1 in
    -h|--help)
        F_HELP
        exit
        ;;
    -u|--up)
        PID_GAN=$(ps -ef | grep  gan-api-server.py | grep -v 'grep' | awk '{print $2}')
        if [[ -z ${PID_GAN} ]]; then
            nohup  python3 ./gan-api-server.py  >> ./gan-api-server.py.log 2>&1 &
            echo "服务已启动！"
            exit
        else
            echo -e "\n猪猪侠警告：服务已在运行中，PID：${PID_GAN}\n"
            exit 1
        fi
        ;;
    -d|--down)
        PID_GAN=$(ps -ef | grep  gan-api-server.py | grep -v 'grep' | awk '{print $2}')
        if [[ -z ${PID_GAN} ]]; then
            echo -e "\n猪猪侠警告：服务不在运行中！\n"
            exit 1
        else
            kill -9 ${PID_GAN}
            echo "服务已停止！"
            exit
        fi
        ;;
    -r|--restart)
        PID_GAN=$(ps -ef | grep  gan-api-server.py | grep -v 'grep' | awk '{print $2}')
        if [[ -z ${PID_GAN} ]]; then
            echo -e "\n猪猪侠警告：服务不在运行中！\n"
            nohup  python3 ./gan-api-server.py  >> ./gan-api-server.py.log 2>&1 &
            echo "服务已启动！"
            exit
        else
            kill -9 ${PID_GAN}
            echo "服务已停止！"
            nohup  python3 ./gan-api-server.py  >> ./gan-api-server.py.log 2>&1 &
            echo "服务已启动！"
            exit
        fi
        ;;
esac


