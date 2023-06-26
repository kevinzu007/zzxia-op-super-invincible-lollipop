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


# 自动引入/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
#NGINX_CONFIG_SH_HOME=

# 引入env.sh

# 本地env
ANSIBLE_HOST_FOR_PG_BACKUP_RESTORE='pg_m'
ANSIBLE_HOST_FOR_NGINX_CERT_REQUEST='nginx_letsencrypt'



# 用法：
F_HELP()
{
    echo "
    用途：用于远程安装部署。模块说明如下：
    注意：在deploy节点上运行，需要一堆关联脚本
    用法:
        $0 [-h|--help]    #--- 帮助
        $0 [-d|--do build|build-para|gogogo|deploy|deploy-docker|deploy-web|ngx-dns|ngx-root|ngx-conf|ngx-cert|ngx-cert-w|pg-b-r|aliyun-dns|godaddy-dns]  <参数1> ... <参数n>     #--- 参数1...n 是 \$1 模块的参数
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -d|--do        某功能模块
                       - build        【build.sh】：项目打包
                       - build-para   【build-parallel.sh】：并行项目打包
                       - gogogo       【gogogo.sh】：项目打包并部署上线
                       - deploy       【deploy.sh】：服务部署上线、回滚
                       - deploy-docker【docker-cluster-service-deploy.sh】：docker服务部署上线、回滚
                       - deploy-web   【web-release.sh】：网站代码部署上线、回滚
                       - ngx-dns      【nginx-dns.sh】：网站域名A记录添加或修改
                       - ngx-root     【nginx-root.sh】：网站root目录初始化
                       - ngx-conf     【nginx-conf.sh】：网站nginx配置设置
                       - ngx-cert     【nginx-cert-letsencrypt-a.sh】：网站域名证书申请
                       - ngx-cert-w   【cert-letsencrypt-wildcart.sh】：泛域名证书申请与更新
                       - pg-b-r       【pg_list_backup_or_restore.sh】：备份或还原pg_m上的数据库
                       - aliyun-dns   【aliyun-dns.sh】：修改aliyun dns
                       - godaddy-dns  【godaddy-dns.sh】：修改godaddy dns
    示例:
        #
        $0  -h
        $0  -d deploy-web  -h                 #--- 运行web-release.sh命令帮助
        $0  -d deploy-web  -r                 #--- 运行web-release.sh命令，发布所有前端项目
        $0  -d deploy-web  -r  项目a 项目b    #--- 运行web-release.sh命令，发布所有前端【项目a、项目b】
    "
}



# 参数检查
#TEMP=`getopt -o hd:  -l help,do: -- "$@"`
#if [ $? != 0 ]; then
#    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
#    exit 1
#fi
#
#eval set -- "${TEMP}"


# 获取参数
case "$1" in
    -h|--help)
        F_HELP
        exit
        ;;
    -d|--do)
        DO=$2
        shift 2
        ;;
    #--)
    #    shift
    #    break
    #    ;;
    *)
        echo -e "\n猪猪侠警告：未知参数，请查看帮助【$0 --help】\n"
        exit 1
        ;;
esac


# go
CMD_ARG=$*
case "${DO}" in
    "-h"|"--help")
        F_HELP
        exit
        ;;
    "build")
        bash ${SH_PATH}/deploy/build.sh  ${CMD_ARG}
        ;;
    "build-para")
        bash ${SH_PATH}/deploy/build-parallel.sh  ${CMD_ARG}
        ;;
    "gogogo")
        bash ${SH_PATH}/deploy/gogogo.sh  ${CMD_ARG}
        ;;
    "deploy")
        bash ${SH_PATH}/deploy/deploy.sh  ${CMD_ARG}
        ;;
    "deploy-docker")
        bash ${SH_PATH}/deploy/docker-cluster-service-deploy.sh  ${CMD_ARG}
        ;;
    "deploy-web")
        bash ${SH_PATH}/deploy/web-release.sh  ${CMD_ARG}
        ;;
    "ngx-dns")
        bash ${SH_PATH}/init/nginx/nginx-config/nginx-dns.sh  ${CMD_ARG}
        ;;
    "ngx-root")
        bash ${SH_PATH}/init/nginx/nginx-config/nginx-root.sh  ${CMD_ARG}
        ;;
    "ngx-conf")
        bash ${SH_PATH}/init/nginx/nginx-config/nginx-conf.sh  ${CMD_ARG}
        ;;
    "ngx-cert")
        ansible ${ANSIBLE_HOST_FOR_NGINX_CERT_REQUEST} -m command -a "bash  ${NGINX_CONFIG_SH_HOME}/nginx-cert-letsencrypt-a.sh  ${CMD_ARG}"
        ;;
    "ngx-cert-w")
        bash ${SH_PATH}/op/cert-letsencrypt-wildcart.sh  ${CMD_ARG}
        ;;
    "pg-b-r")
        ansible ${ANSIBLE_HOST_FOR_PG_BACKUP_RESTORE} -m shell  -a "bash /backup/pg/pg_list_backup_or_restore.sh  ${CMD_ARG}"
        ;;
    "aliyun-dns")
        bash ${SH_PATH}/op/aliyun-dns.sh  ${CMD_ARG}
        ;;
    "godaddy-dns.sh")
        bash ${SH_PATH}/op/godaddy-dns.sh  ${CMD_ARG}
        ;;
    *)
        echo -e "\n骚年，请输入正确的脚本命令参数！【请查看帮助：\$0 --help】\n"
        exit 1
        ;;
esac



