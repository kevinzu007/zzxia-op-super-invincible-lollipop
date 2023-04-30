#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7


# 此文件请根据你自己环境需要的文件进行增删



TIME=`date +%Y-%m-%dT%H:%M%S`
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}


# 默认运行环境相关文件所在目录
ENVS_FILE_DIR="${SH_PATH}/envs.sample"



# 用法：
F_HELP()
{
    echo "
    用法:
    sh $0  [-h|--help]
    sh $0  [-r|--rm]            #--- 删除项目环境文件
    sh $0  [-c|--copy {环境名称}]  <-f|--from {Path-To-envs文件目录}>    #--- 拷贝envs目录中以【---环境名称】结尾的文件到指定路径，比如：【prod|stag|dev|其他任意名称】
    "
}



F_CP ()
{
    #set -e
    # cp到init目录
    cp -rf ${ENVS_FILE_DIR}/3rd_jar                               ./
    cp -f  ${ENVS_FILE_DIR}/dingding_send_markdown-login.py       ./
    cp -f  ${ENVS_FILE_DIR}/dingding_send_markdown.py             ./
    cp -f  ${ENVS_FILE_DIR}/dingding_conver_to_markdown_list.py   ./
    cp -f  ${ENVS_FILE_DIR}/ossfs-backup.service                  ./
    cp -f  ${ENVS_FILE_DIR}/ossfs-internal-backup.service         ./
    #
    cp -f  ${ENVS_FILE_DIR}/install-hosts.yml---${R_ENV}          ./install-hosts.yml
    cp -f  ${ENVS_FILE_DIR}/host-ip.list---${R_ENV}               ./host-ip.list
    cp -f  ${ENVS_FILE_DIR}/bash_aliases---${R_ENV}               ./bash_aliases
    cp -f  ${ENVS_FILE_DIR}/run-env.sh---${R_ENV}                 ./run-env.sh
    cp -f  ${ENVS_FILE_DIR}/mailrc---${R_ENV}                     ./mailrc
    # cp到init子目录
    cp -f  ${ENVS_FILE_DIR}/soft/jdk-*-linux-x64.tar.gz           ./build-envs/java/
    cp -f  ${ENVS_FILE_DIR}/soft/apache-maven-*-bin.tar.gz        ./build-envs/maven/
    cp -f  ${ENVS_FILE_DIR}/soft/node-v*-linux-x64.tar.xz         ./build-envs/node/
    cp -f  ${ENVS_FILE_DIR}/backup-center-project.list            ./backup-center/backup-center-project.list
    cp -f  ${ENVS_FILE_DIR}/pg_db.list                            ./pg/backup/pg_db.list
    #
    cp -f  ${ENVS_FILE_DIR}/nginx.list---${R_ENV}                 ./nginx-config/nginx.list
    cp -f  ${ENVS_FILE_DIR}/fluent.conf---${R_ENV}                ./fluentd-srv/conf/fluent.conf
    cp -f  ${ENVS_FILE_DIR}/kibana-srv-env---${R_ENV}             ./kibana-srv/.env
    cp -f  ${ENVS_FILE_DIR}/elasticsearch-srv-env---${R_ENV}      ./elasticsearch-srv/.env

    # cp到deploy目录
    cp -f  ${ENVS_FILE_DIR}/project.list                             ../deploy/
    cp -f  ${ENVS_FILE_DIR}/project.list.append.1                    ../deploy/
    #
    cp -f  ${ENVS_FILE_DIR}/deploy.env---${R_ENV}                    ../deploy/deploy.env
    cp -f  ${ENVS_FILE_DIR}/nginx.list---${R_ENV}                    ../deploy/nginx.list
    cp -f  ${ENVS_FILE_DIR}/docker-cluster-service.list---${R_ENV}   ../deploy/docker-cluster-service.list
    cp -f  ${ENVS_FILE_DIR}/docker-cluster-service.list.append.1---${R_ENV}   ../deploy/docker-cluster-service.list.append.1
    cp -f  ${ENVS_FILE_DIR}/docker-cluster-service.list.append.2---${R_ENV}   ../deploy/docker-cluster-service.list.append.2
    cp -f  ${ENVS_FILE_DIR}/docker-arg-pub.list---${R_ENV}           ../deploy/docker-arg-pub.list
    cp -f  ${ENVS_FILE_DIR}/container-hosts-pub.list---${R_ENV}      ../deploy/container-hosts-pub.list
    cp -f  ${ENVS_FILE_DIR}/java-options-pub.list---${R_ENV}         ../deploy/java-options-pub.list

    # cp到deploy主机，即本机
    cp -f  ${ENVS_FILE_DIR}/ansible-hosts---${R_ENV}                 /etc/ansible/hosts
}



F_RM ()
{
    # init目录
    rm -rf ./3rd_jar
    rm -f  ./dingding_send_markdown-login.py
    rm -f  ./dingding_send_markdown.py
    rm -f  ./dingding_conver_to_markdown_list.py 
    rm -f  ./ossfs-internal-backup.service
    rm -f  ./ossfs-backup.service
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
    rm -f  ../deploy/project.list.append.1
    #
    rm -f  ../deploy/deploy.env
    rm -f  ../deploy/nginx.list
    rm -f  ../deploy/docker-cluster-service.list
    rm -f  ../deploy/docker-cluster-service.list.append.1
    rm -f  ../deploy/docker-cluster-service.list.append.2
    rm -f  ../deploy/docker-arg-pub.list
    rm -f  ../deploy/container-hosts-pub.list
    rm -f  ../deploy/java-options-pub.list

    # deploy主机，即本机
    rm -f  /etc/ansible/hosts
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


# 获取运行参数
R_MODE=''
while true
do
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
                if [[ -z ${R_ENV} ]]; then
                    echo -e "\n猪猪侠警告：参数错误，请查看帮助【$0 --help】\n"
                    exit 1
                fi
            else
                echo -e "\n猪猪侠警告：主要参数只能有一个，请查看帮助【$0 --help】\n"
                exit 1
            fi
            shift 2
            ;;
        -f|--from)
            ENVS_FILE_DIR=$2
            ENVS_FILE_DIR=${ENVS_FILE_DIR%*/}
            if [[ ! -d ${ENVS_FILE_DIR} ]]; then
                echo -e "\n猪猪侠警告：目录【${ENVS_FILE_DIR}】不存在，请检查\n"
                exit 1
            fi
            shift 2
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



case ${R_MODE} in
    F_RM)
        F_RM
        ;;
    F_CP)
        #
        if [[ ! -f ${ENVS_FILE_DIR}/deploy.env---${R_ENV} ]]; then
            echo -e "\n猪猪侠警告：请检查以【---${R_ENV}】结尾的文件是否准备好，例如：【${ENVS_FILE_DIR}/deploy.env---${R_ENV}】\n"
            exit 1
        fi
        #
        F_CP
        ;;
    *)
        echo -e "\n猪猪侠警告：未知参数，请查看帮助【$0 --help】\n"
        exit 1
        ;;
esac



