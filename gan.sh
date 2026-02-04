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


# 引入/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
# 检测 MY_PRIVATE_ENVS_DIR 是否存在，不存在则主动加载环境变量（非终端界面不会自动引入）
if [ -z "${RUN_ENV}" ]; then
    if [ -f /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh ]; then
        . /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
    else
        echo -e "\n猪猪侠警告：缺少环境变量文件：/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh\n"
        echo "请在 deploy 服务器上安装/配置该文件，并确保所有必要变量可用。"
        echo
        exit 52
    fi
fi
# 引入使用：
#NGINX_CONFIG_SH_HOME=
#PG_MANAGE_SH_HOME=
#USER_DB_FILE=
#USER_DB_FILE_APPEND_1=

# 引入env.sh

# 本地env
ANSIBLE_HOST_FOR_PG_BACKUP_RESTORE='pg_m'
ANSIBLE_HOST_FOR_NGINX_CERT_REQUEST='nginx_letsencrypt'
NEED_PRIVILEGES='gan'                   #-- 运行此程序需要的权限，如果需要多个权限，则用【&】分隔
if [[ -z ${USER_INFO_FROM} ]]; then
    USER_INFO_FROM=${HOOK_USER_INFO_FROM:-'local'}     #--【local|hook_hand|hook_gitlab】，默认：local
fi
# 引入函数
.  ${SH_PATH}/fuckingdoit/function.sh



# 用法：
F_HELP()
{
    echo "
    用途：用于远程安装部署。模块说明如下：
    依赖：
    注意：在deploy节点上运行，需要一堆关联脚本
    用法:
        $0 -h|--help
        $0 --build|--build-para|--gogogo|--deploy|--deploy-docker|--deploy-web|--ngx-dns|--ngx-root|--ngx-conf|--ngx-cert|--ngx-cert-w|--pg-b-r|--aliyun-dns|--godaddy-dns  [<参数1> ... <参数n>]
    参数规范：
        无包围符号 ：-a                : 必选【选项】
                   ：val               : 必选【参数值】
                   ：val1 val2 -a -b   : 必选【选项或参数值】，且不分先后顺序
        []         ：[-a]              : 可选【选项】
                   ：[val]             : 可选【参数值】
        <>         ：<val>             : 需替换的具体值（用户必须提供）
        %%         ：%val%             : 通配符（包含匹配，如%error%匹配error_code）
        |          ：val1|val2|<valn>  : 多选一
        {}         ：{-a <val>}        : 必须成组出现【选项+参数值】
                   ：{val1 val2}       : 必须成组的【参数值组合】，且必须按顺序提供
    参数说明：
        -h|--help      此帮助
        --build        【build.sh】：项目打包
        --build-para   【build-parallel.sh】：并行项目打包
        --gogogo       【gogogo.sh】：项目打包并部署上线
        --deploy       【deploy.sh】：服务部署上线、回滚
        --deploy-docker【docker-cluster-service-deploy.sh】：docker服务部署上线、回滚
        --deploy-web   【web-release.sh】：网站代码部署上线、回滚
        --ngx-dns      【nginx-dns.sh】：网站域名A记录添加或修改
        --ngx-root     【nginx-root.sh】：网站root目录初始化
        --ngx-conf     【nginx-conf.sh】：网站nginx配置设置
        --ngx-cert     【nginx-cert-letsencrypt-a.sh】：网站域名证书申请
        --ngx-cert-w   【cert-letsencrypt-wildcart.sh】：泛域名证书申请与更新
        --pg-b-r       【pg_list_backup_or_restore.sh】：备份或还原pg_m上的数据库
        --aliyun-dns   【aliyun-dns.sh】：修改aliyun dns
        --godaddy-dns  【godaddy-dns.sh】：修改godaddy dns
    示例:
        #
        $0  -h
        $0  --deploy-web  -h                 #--- 运行web-release.sh命令帮助
        $0  --deploy-web  -r                 #--- 运行web-release.sh命令，发布所有前端项目
        $0  --deploy-web  -r  项目a 项目b    #--- 运行web-release.sh命令，发布所有前端【项目a、项目b】
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


# Check for help
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    F_HELP
    exit
fi


# 运行环境匹配for Hook
if [[ -n ${HOOK_GAN_ENV} ]] && [[ ${HOOK_GAN_ENV} != 'NOT_CHECK' ]] && [[ ${HOOK_GAN_ENV} != ${RUN_ENV} ]]; then
    echo -e "\n猪猪侠警告：运行环境不匹配，跳过（这是正常情况）\n"
    exit
fi


# 必要文件检查（用户/权限管理依赖）
#
# 允许只提供 MY_PRIVATE_ENVS_DIR：自动推导 USER_DB_FILE / USER_DB_FILE_APPEND_1
if [[ -n "${MY_PRIVATE_ENVS_DIR}" ]]; then
    USER_DB_FILE=${USER_DB_FILE:-"${MY_PRIVATE_ENVS_DIR}/user.db"}
    USER_DB_FILE_APPEND_1=${USER_DB_FILE_APPEND_1:-"${MY_PRIVATE_ENVS_DIR}/user.db.append.1"}
fi
if [[ -z "${USER_DB_FILE}" ]] || [[ -z "${USER_DB_FILE_APPEND_1}" ]]; then
    echo -e "\n猪猪侠警告：缺少用户权限相关变量（USER_DB_FILE / USER_DB_FILE_APPEND_1）。\n"
    echo "请检查是否已正确加载：/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh"
    echo "并确认已配置：MY_PRIVATE_ENVS_DIR（或直接配置 USER_DB_FILE / USER_DB_FILE_APPEND_1）。"
    echo
    exit 52
fi
if [[ ! -f "${USER_DB_FILE}" ]]; then
    echo -e "\n猪猪侠警告：用户数据库文件不存在：${USER_DB_FILE}\n"
    echo "请在 ${MY_PRIVATE_ENVS_DIR:-'<MY_PRIVATE_ENVS_DIR>'} 下创建/拷贝 user.db（基础用户信息）。"
    echo
    exit 52
fi
if [[ ! -f "${USER_DB_FILE_APPEND_1}" ]]; then
    echo -e "\n猪猪侠警告：用户权限扩展文件不存在：${USER_DB_FILE_APPEND_1}\n"
    echo "参考样例：${SH_PATH}/init/0-my_private_envs.sample/user.db.append.1"
    echo "请将 user.db.append.1 放到 ${MY_PRIVATE_ENVS_DIR:-'<MY_PRIVATE_ENVS_DIR>'} 并确保格式正确。"
    echo
    exit 52
fi


# 获取用户信息
F_get_user_info
r=$?
if [[ $r != 0 ]]; then
    exit $r
fi


# 检查用户权限
F_check_user_priv
r=$?
if [[ $r != 0 ]]; then
    exit $r
fi


# go
case "$1" in
    "--build")
        shift
        bash ${SH_PATH}/fuckingdoit/build.sh  "$@"
        exit
        ;;
    "--build-para")
        shift
        bash ${SH_PATH}/fuckingdoit/build-parallel.sh  "$@"
        exit
        ;;
    "--gogogo")
        shift
        bash ${SH_PATH}/fuckingdoit/gogogo.sh  "$@"
        exit
        ;;
    "--deploy")
        shift
        bash ${SH_PATH}/fuckingdoit/deploy.sh  "$@"
        exit
        ;;
    "--deploy-docker")
        shift
        bash ${SH_PATH}/fuckingdoit/docker-cluster-service-deploy.sh  "$@"
        exit
        ;;
    "--deploy-web")
        shift
        bash ${SH_PATH}/fuckingdoit/web-release.sh  "$@"
        exit
        ;;
    "--ngx-dns")
        shift
        bash ${SH_PATH}/init/nginx/nginx-config/nginx-dns.sh  "$@"
        exit
        ;;
    "--ngx-root")
        shift
        bash ${SH_PATH}/init/nginx/nginx-config/nginx-root.sh  "$@"
        exit
        ;;
    "--ngx-conf")
        shift
        bash ${SH_PATH}/init/nginx/nginx-config/nginx-conf.sh  "$@"
        exit
        ;;
    "--ngx-cert")
        shift
        ansible ${ANSIBLE_HOST_FOR_NGINX_CERT_REQUEST} -m command -a "bash  ${NGINX_CONFIG_SH_HOME}/nginx-cert-letsencrypt-a.sh  $*"
        exit
        ;;
    "--ngx-cert-w")
        shift
        bash ${SH_PATH}/tools/cert-letsencrypt-wildcart.sh  "$@"
        exit
        ;;
    "--pg-b-r")
        shift
        ansible ${ANSIBLE_HOST_FOR_PG_BACKUP_RESTORE} -m shell  -a "bash ${PG_MANAGE_SH_HOME}/pg_list_backup_or_restore.sh  $*"
        exit
        ;;
    "--aliyun-dns")
        shift
        bash ${SH_PATH}/tools/aliyun-dns.sh  "$@"
        exit
        ;;
    "--godaddy-dns")
        shift
        bash ${SH_PATH}/tools/godaddy-dns.sh  "$@"
        exit
        ;;
    *)
        echo -e "\n骚年，请输入正确的脚本命令参数！【请查看帮助：\$0 --help】\n"
        exit 1
        ;;
esac



