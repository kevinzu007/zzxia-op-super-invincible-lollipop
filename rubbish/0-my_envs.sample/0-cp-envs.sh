#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7


# 此文件请根据你自己环境需要的文件进行增删



TIME=`date +%Y-%m-%dT%H:%M%S`
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}


# 自动从/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh引入以下变量
#RUN_ENV=



# 用法：
F_HELP()
{
    echo "
    用法:
        bash $0  [-h|--help]
        bash $0  [-c|--copy<{运行环境>]    #-- 拷贝当前目录中以【---运行环境】结尾的文件到指定路径，【运行环境】如果没有指定，则从【/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh】中获取
    示例：
        $0  -h            #-- 帮助
        $0  -c            #-- 拷贝【/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh】文件中指定的运行环境的文件到目标路径
        $0  -cdev         #-- 拷贝以【dev】运行环境的文件到目标路径
    "
}




F_CP ()
{
    #set -e
    mkdir -p  /etc/ansible/inventories
    sed -i -E  '/^inventory[ ]* = .*$/d'                                /etc/ansible/ansible.cfg
    sed -i -E  '/\[defaults\]/a\inventory = /etc/ansible/inventories/'  /etc/ansible/ansible.cfg
    cp -f  ./ansible-inventory.rubbish---${R_ENV}                       /etc/ansible/inventories/ansible-inventory.rubbish
    cp -f  ./bash_aliases---${R_ENV}                                    ~/.bash_aliases
    # cp rubbish
    cp -rf ./3rd_jar                                                    ${DEST_DIR}/rubbish/
    #cp -f  ./soft/jdk-*-linux-x64.tar.gz                                ${DEST_DIR}/rubbish/java/
    #cp -f  ./soft/apache-maven-*-bin.tar.gz                             ${DEST_DIR}/rubbish/maven/
    #cp -f  ./soft/node-v*-linux-x64.tar.xz                              ${DEST_DIR}/rubbish/node/
    cp -f  ./ossfs-backup.service                                       ${DEST_DIR}/rubbish/ossfs/
    cp -f  ./ossfs-internal-backup.service                              ${DEST_DIR}/rubbish/ossfs/
    cp -f  ./backup-center-project.list                                 ${DEST_DIR}/rubbish/backup-center/backup-center-project.list
    #
    cp -f  ./install-hosts.yml---${R_ENV}                               ${DEST_DIR}/rubbish/install-hosts.yml
    cp -f  ./fluent.conf---${R_ENV}                                     ${DEST_DIR}/rubbish/fluentd/fluentd-srv/conf/fluent.conf
    cp -f  ./kibana-srv-env---${R_ENV}                                  ${DEST_DIR}/rubbish/kibana/kibana-srv/.env
    cp -f  ./elasticsearch-srv-env---${R_ENV}                           ${DEST_DIR}/rubbish/elasticsearch/elasticsearch-srv/.env
}





# 参数检查
if [[ $# == 0 ]]; then
    echo -e "\n猪猪侠警告：请提供运行参数！\n"
    exit 1
fi
#
TEMP=`getopt -o hc::  -l help,copy:: -- "$@"`
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
        -c|--copy)
            #
            R_ENV=${2:-${RUN_ENV}}
            shift 2
            if [[ -z ${R_ENV} ]]; then
                echo -e "\n猪猪侠警告：运行环境变量【\${R_ENV}】为空，请用命令行参数指定！\n"
                exit 1
            fi
            #
            # 获取【zzxia-op-super-invincible-lollipop|超级无敌棒棒糖】项目路径
            .  /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
            DEST_DIR=${ZZXIA_OP_SUPER_INVINCIBLE_LOLLIPOP_HOME}
            if [[ ! -f ${DEST_DIR}/gan.sh ]]; then
                echo -e "\n猪猪侠警告：配置文件【zzxia-op-super-invincible-lollipop.run-env.sh】中指定的项目路径参数【ZZXIA_OP_SUPER_INVINCIBLE_LOLLIPOP_HOME】有误，请检查\n"
                exit 1
            fi
            #
            F_CP
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


