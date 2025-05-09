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
    sed -i -E -e '/^\[defaults\]/b' -e '$a\[defaults]'                   /etc/ansible/ansible.cfg
    sed -i -E '/^inventory[[:space:]]*=.*/d'                             /etc/ansible/ansible.cfg
    sed -i -E  '/\[defaults\]/a\inventory = /etc/ansible/inventories/'   /etc/ansible/ansible.cfg
    cp -f  ./ansible-inventory---${R_ENV}                                /etc/ansible/inventories/ansible-inventory
    
    # cp到init/2-os-base/目录
    cp -f  ./zzxia-op-super-invincible-lollipop.run-env.sh---${R_ENV}    /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
    cp -f  ./zzxia-op-super-invincible-lollipop.run-env.sh---${R_ENV}    ${DEST_DIR}/init/2-os-base/zzxia-op-super-invincible-lollipop.run-env.sh
    cp -f  ./host-ip.list---${R_ENV}                                     ${DEST_DIR}/init/host-ip.list
    cp -f  ./mailrc---${R_ENV}                                           ${DEST_DIR}/init/2-os-base/mailrc
    
    # cp到deploy目录
    cp -f  ./project.list                                                ${DEST_DIR}/deploy/
    cp -f  ./project.list.append.1                                       ${DEST_DIR}/deploy/
    cp -f  ./env.sh---${R_ENV}                                           ${DEST_DIR}/deploy/env.sh
    cp -f  ./docker-cluster-service.list---${R_ENV}                      ${DEST_DIR}/deploy/docker-cluster-service.list
    cp -f  ./docker-cluster-service.list.append.1---${R_ENV}             ${DEST_DIR}/deploy/docker-cluster-service.list.append.1
    cp -f  ./docker-cluster-service.list.append.2---${R_ENV}             ${DEST_DIR}/deploy/docker-cluster-service.list.append.2
    cp -f  ./docker-arg-pub.list---${R_ENV}                              ${DEST_DIR}/deploy/docker-arg-pub.list
    cp -f  ./container-hosts-pub.list---${R_ENV}                         ${DEST_DIR}/deploy/container-hosts-pub.list
    cp -f  ./java-options-pub.list---${R_ENV}                            ${DEST_DIR}/deploy/java-options-pub.list
    
    # 其他
    cp -f  ./nginx.list---${R_ENV}                                       ${DEST_DIR}/deploy/nginx.list
    cp -f  ./nginx.list---${R_ENV}                                       ${DEST_DIR}/init/nginx/nginx-config/nginx.list
    cp -f  ./pg_db.list                                                  ${DEST_DIR}/init/pg/manage/pg_db.list
    cp -f  ./pgbadger.env---${R_ENV}                                     ${DEST_DIR}/init/pgbadger/pgbadger_report/pgbadger.env
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
            .  ./zzxia-op-super-invincible-lollipop.run-env.sh---${R_ENV}
            DEST_DIR=${ZZXIA_OP_SUPER_INVINCIBLE_LOLLIPOP_HOME}
            if [[ ! -f ${DEST_DIR}/gan.sh ]]; then
                echo -e "\n猪猪侠警告：配置文件【./zzxia-op-super-invincible-lollipop.run-env.sh---${R_ENV}】中指定的项目路径参数【ZZXIA_OP_SUPER_INVINCIBLE_LOLLIPOP_HOME】有误，请检查\n"
                exit 1
            fi
            #
            F_CP
            #
            echo -e "\n猪猪侠警告：请重新登录以使【/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh】中的变量生效！\n"
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


