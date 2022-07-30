#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7


TIME=`date +%Y-%m-%dT%H:%M%S`
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}


# 默认运行环境相关文件所在目录
ENVS_FILE_DIR="${SH_PATH}/envs"



# 用法：
F_HELP()
{
    echo "
    用法:
    sh $0 [-h|--help]
    sh $0 [-r|--rm]            #--- 删除项目环境文件
    sh $0 <-f|--from {Path-To-envs文件目录}>  [-c|--copy {环境名称}]    #--- 拷贝envs目录中以【---环境名称】结尾的文件到指定路径，比如：【prod|stag|dev|其他任意名称】
    "
}



F_RM ()
{
    # init目录
    rm -rf ./envs/3rd_jar
    rm -f  ./envs/dingding_by_markdown_file-login.py
    rm -f  ./envs/dingding_by_markdown_file.py
    rm -f  ./envs/dingding_markdown.py 
    rm -f  ./envs/ossfs-internal-backup.service
    rm -f  ./envs/ossfs-backup.service
    #
    rm -f  ./install-hosts.yml
    rm -f  ./host-ip.list
    rm -f  ./bash_aliases
    rm -f  ./run-env.sh
    rm -f  ./mailrc
    # init子目录
    rm -f  ./build-envs/java/jdk-*-linux-x64.tar.gz
    rm -f  ./build-envs/maven/apache-maven-*-bin.tar.gz
    rm -f  ./build-envs/node/node-v*-linux-x64.tar.xz
    rm -f  ./backup-center/backup-center-project.list
    rm -f  ./pg/backup/pg_db.list
    #
    rm -f  ./nginx-config/nginx.list
    rm -f  ./fluentd-srv/conf/fluent.conf
    rm -f  ./kibana-srv/.env
    rm -f  ./elasticsearch-srv/.env

    # deploy目录
    rm -f  ../deploy/project.list
    #
    rm -f  ../deploy/deploy.env
    rm -f  ../deploy/nginx.list
    rm -f  ../deploy/docker-cluster-service.list
    rm -f  ../deploy/docker-arg-pub.list
    rm -f  ../deploy/container-hosts-pub.list
    rm -f  ../deploy/java-options-pub.list

    # deploy主机，即本机
    rm -f  /etc/ansible/hosts
}



F_CP ()
{
    set -e
    # cp到init目录
    cp -rf ./envs/3rd_jar                             ./
    cp -f  ./envs/dingding_by_markdown_file-login.py  ./
    cp -f  ./envs/dingding_by_markdown_file.py        ./
    cp -f  ./envs/dingding_markdown.py                ./
    cp -f  ./envs/ossfs-backup.service                ./
    cp -f  ./envs/ossfs-internal-backup.service       ./
    #
    cp -f  ./envs/install-hosts.yml---${ENV}          ./install-hosts.yml
    cp -f  ./envs/host-ip.list---${ENV}               ./host-ip.list
    cp -f  ./envs/bash_aliases---${ENV}               ./bash_aliases
    cp -f  ./envs/run-env.sh---${ENV}                 ./run-env.sh
    cp -f  ./envs/mailrc---${ENV}                     ./mailrc
    # cp到init子目录
    cp -f  ./envs/soft/jdk-*-linux-x64.tar.gz      ./build-envs/java/
    cp -f  ./envs/soft/apache-maven-*-bin.tar.gz   ./build-envs/maven/
    cp -f  ./envs/soft/node-v*-linux-x64.tar.xz    ./build-envs/node/
    cp -f  ./envs/backup-center-project.list       ./backup-center/backup-center-project.list
    cp -f  ./envs/pg_db.list                       ./pg/backup/pg_db.list
    #
    cp -f  ./envs/nginx.list---${ENV}              ./nginx-config/
    cp -f  ./envs/fluent.conf---${ENV}             ./fluentd-srv/conf/fluent.conf
    cp -f  ./envs/kibana-srv-env---${ENV}          ./kibana-srv/.env
    cp -f  ./envs/elasticsearch-srv-env---${ENV}   ./elasticsearch-srv/.env

    # cp到deploy目录
    cp -f  ./envs/project.list                           ../deploy/
    #
    cp -f  ./envs/deploy.env---${ENV}                    ../deploy/deploy.env
    cp -f  ./envs/nginx.list---${ENV}                    ../deploy/nginx.list
    cp -f  ./envs/docker-cluster-service.list---${ENV}   ../deploy/docker-cluster-service.list
    cp -f  ./envs/docker-arg-pub.list---${ENV}           ../deploy/docker-arg-pub.list
    cp -f  ./envs/container-hosts-pub.list---${ENV}      ../deploy/container-hosts-pub.list
    cp -f  ./envs/java-options-pub.list---${ENV}         ../deploy/java-options-pub.list

    # cp到deploy主机，即本机
    cp -f  ./envs/ansible-hosts---${ENV}             /etc/ansible/hosts
}



# 参数检查
TEMP=`getopt -o hrc:f:  -l help,rm,copy:,from: -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    F_HELP
    exit 51
fi
#
eval set -- "${TEMP}"


# go
R_MODE=''
case "$1" in
    "-h"|"--help")
        F_HELP
        exit
        ;;
    -r|--rm)
        if [[ -z ${R_MODE} ]]; then
            R_MODE=F_RM
        else
            echo -e "\n猪猪侠警告：主要参数只能有一个，请查看帮助【$0 --help】\n"
            exit 1
        fi
        shift
        ;;
    -c|--copy)
        if [[ -z ${R_MODE} ]]; then
            R_MODE=F_CP
            R_ENV=$2
        else
            echo -e "\n猪猪侠警告：主要参数只能有一个，请查看帮助【$0 --help】\n"
            exit 1
        fi
        shift 2
        ;;
    -f|--from)
        ENVS_FILE_DIR=$2
        if [[ ! -d ${ENVS_FILE_DIR} ]]; then
            echo -e "\n猪猪侠警告：目录【${ENVS_FILE_DIR}】不存在，请检查\n"
            exit 1
        fi
        shift 2
        ;;
    *)
        echo -e "\n猪猪侠警告：未知参数，请查看帮助【$0 --help】\n"
        exit 1
        ;;
esac


if [[ ! -d ${ENVS_FILE_DIR}/deploy.env---${R_ENV} ]]; then
    echo -e "\n猪猪侠警告：请检查以【---${R_ENV}】结尾的文件是否准备好，例如：【${ENVS_FILE_DIR}/deploy.env---${R_ENV}】\n"
    exit 1
fi


case ${R_MODE} in
    F_RM)
        F_RM
        ;;
    F_CP)
        F_CP
        ;;
    *)
        echo -e "\n猪猪侠警告：未知参数，请查看帮助【$0 --help】\n"
        exit 1
        ;;
esac



