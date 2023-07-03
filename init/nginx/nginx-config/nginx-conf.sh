#!/bin/bash


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 自动引入/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
.  /etc/profile        #-- 非终端界面不会自动引入，必须主动引入
#RUN_ENV=
#DOMAIN=
#WEBSITE_BASE=
#NGINX_CONF_DEFAULT_DIR=

# 引入env.sh

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
WEB_PROJECT_LIST_FILE="${SH_PATH}/nginx.list"
WEB_PROJECT_LIST_FILE_TMP="/tmp/${SH_NAME}-nginx.tmp.list"
DST_CONF_DIR=${NGINX_CONF_DEFAULT_DIR:-"/etc/nginx/conf.d"}
TMP_CONF_DIR="/tmp/${SH_NAME}-conf.d"
[ -d ${TMP_CONF_DIR} ] && rm -rf   ${TMP_CONF_DIR}
mkdir -p ${TMP_CONF_DIR}

# 删除空行（以及只有tab、空格的行）
#sed -i '/^\s*$/d'  ${WEB_PROJECT_LIST_FILE}
# 删除行中的空格
#sed -i 's/[ \t]*//g'  ${WEB_PROJECT_LIST_FILE}

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
    用途：用以生成项目nginx配置文件，并放置到nginx服务器上
    依赖：
        /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
        ${WEB_PROJECT_LIST_FILE}
    注意：运行在deploy节点上
    用法:
        $0  [-h|--help]
        $0  [-l|--list]
        $0  [ [-p|--protocol http] | [-p|--protocol https  -c|--cert wildcard|single] ]  <{项目1}  {项目2} ... {项目n}>
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -l|--list      列出可构建的项目清单
        -p|--protocol  协议，可选值【http|https】
        -c|--cert      证书类型，可选值【wildcard|single】，分别代表泛域名证书或单域名证书
    示例:
        #
        $0  -h     #--- 帮助
        $0  -l     #--- 列出项目清单
        #
        $0  -p http                              #--- http方式，为所有项目创建配置文件
        $0  -p http                项目a 项目b   #--- http方式，为【项目a、项目b】创建配置文件
        $0  -p https  -c single                  #--- https普通域名证书方式，为所有项目创建配置文件
        $0  -p https  -c wildcard                #--- https泛域名证书方式，为所有项目创建配置文件
        $0  -p https  -c wildcard  项目a 项目b   #--- https泛域名证书方式，为【项目a、项目b】创建配置文件
    "
}



F_HTTP_REALSERVER()
{
    echo "
# ------------start------------
# 80 for Letsencrypts证书申请与更新
server {
    server_name ${FQDN} ;
    listen 80 ;
    access_log /var/log/nginx/${FQDN}-access.log  main ;
    # Do not HTTPS redirect Let'sEncrypt ACME challenge
    location /.well-known/acme-challenge/ {
        auth_basic off;
        allow all;
        root ${WEBSITE_BASE}/${FQDN} ;
        try_files \$uri =404;
        break;
    }
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen       ${FRONT_HTTP_PORT} ;
    server_name  ${FQDN} ;
    root         ${WEBSITE_BASE}/${FQDN} ;
    charset      utf-8;

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;
    # log
    access_log   /var/log/nginx/${FQDN}-access.log  main ;
    error_log    /var/log/nginx/${FQDN}-error.log ;

    # error
    error_page 404 /404.html ;
        location = /40x.html {
    }
    error_page 500 502 503 504 /50x.html ;
        location = /50x.html {
    }

    # 不缓存index.html
    location = /index.html {
        add_header Cache-Control \"no-cache, no-store\";
    }

    # 附加项==============

    # 特殊情况============
    #
}
# ------------end------------
    "  > ${TMP_CONF_DIR}/${MODE}/${FQDN}.conf
}



F_HTTP_PROXYSERVER()
{
    echo "
# ------------start------------
# 80 for Letsencrypts证书申请与更新
server {
    server_name ${FQDN} ;
    listen 80 ;
    access_log /var/log/nginx/${FQDN}-access.log  main ;
    # Do not HTTPS redirect Let'sEncrypt ACME challenge
    location /.well-known/acme-challenge/ {
        auth_basic off;
        allow all;
        root ${WEBSITE_BASE}/${FQDN} ;
        try_files \$uri =404;
        break;
    }
    location / {
        return 301 https://\$host\$request_uri;
    }
}

# http
upstream ${PJ} {
    server  ${PJ}-1:${BACKEND_PORT} weight=5 ;
    server  ${PJ}-2:${BACKEND_PORT} weight=5 ;
}

server {
    listen       ${FRONT_HTTP_PORT} ;
    server_name  ${FQDN} ;
    root         ${WEBSITE_BASE}/${FQDN} ;
    charset      utf-8;

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;
    # log
    access_log   /var/log/nginx/${FQDN}-access.log  main ;
    error_log    /var/log/nginx/${FQDN}-error.log ;

    # Letsencrypts证书申请
    location /.well-known/acme-challenge/ {
        auth_basic off;
        allow all;
        root ${WEBSITE_BASE}/${FQDN} ;
        try_files \$uri =404;
        break;
    }

    # proxy需要------------
    location / {
        proxy_pass  ${BACKEND_PROTOCOL}://${PJ} ;

        #Proxy Settings
        include  /etc/nginx/conf.d/proxy_params ;
    }
    # proxy end------------

    # error
    error_page 404 /404.html ;
        location = /40x.html {
    }
    error_page 500 502 503 504 /50x.html ;
        location = /50x.html {
    }

    # 附加项==============

    # 特殊情况============
    #
}
# ------------end------------
    "  > ${TMP_CONF_DIR}/${MODE}/${FQDN}.conf
}




F_HTTPS_REALSERVER_S()
{
    echo "
# ------------start------------
# 80 for Letsencrypts证书申请与更新
server {
    server_name ${FQDN} ;
    listen 80 ;
    access_log /var/log/nginx/${FQDN}-access.log  main ;
    # Do not HTTPS redirect Let'sEncrypt ACME challenge
    location /.well-known/acme-challenge/ {
        auth_basic off;
        allow all;
        root ${WEBSITE_BASE}/${FQDN} ;
        try_files \$uri =404;
        break;
    }
    location / {
        return 301 https://\$host\$request_uri;
    }
}

# https
server {
    listen       ${FRONT_HTTPS_PORT}  ssl ;
    server_name  ${FQDN} ;
    root         ${WEBSITE_BASE}/${FQDN} ;
    charset      utf-8;

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;
    # log
    access_log   /var/log/nginx/${FQDN}-access.log  main ;
    error_log    /var/log/nginx/${FQDN}-error.log ;

    # ssl
    ssl_certificate  /etc/letsencrypt/live/${FQDN}/fullchain.pem ;
    ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem ;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    # DHE不安全，ECDHE才行，否则安全检测是B
    #ssl_ciphers ECDHE+RSAGCM:ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:!aNULL!eNull:!EXPORT:!DES:!3DES:!MD5:!DSS;
    ssl_ciphers "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256:HIGH:!aNULL:!MD5:!ADH:!RC4:!DH" ;
    # ssl缓存
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 60m;
    # ssl代校验
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;  #一般为ca证书
    # dns解析指定
    #resolver 233.5.5.5 233.6.6.6 8.8.8.8 4.4.4.4  valid=300s;
    #resolver_timeout 2s;

    # 不缓存index.html
    location = /index.html {
        add_header Cache-Control \"no-cache, no-store\";
    }

    # error
    error_page 404 /404.html ;
        location = /40x.html {
    }
    error_page 500 502 503 504 /50x.html ;
        location = /50x.html {
    }

    # 附加项==============

    # 特殊情况============
    #
}
# ------------end------------
    "  > ${TMP_CONF_DIR}/${MODE}/${FQDN}.conf
}



F_HTTPS_PROXYSERVER_S()
{
    echo "
# ------------start------------
# 80 for Letsencrypts证书申请与更新
server {
    server_name ${FQDN} ;
    listen 80 ;
    access_log /var/log/nginx/${FQDN}-access.log  main ;
    # Do not HTTPS redirect Let'sEncrypt ACME challenge
    location /.well-known/acme-challenge/ {
        auth_basic off;
        allow all;
        root ${WEBSITE_BASE}/${FQDN} ;
        try_files \$uri =404;
        break;
    }
    location / {
        return 301 https://\$host\$request_uri;
    }
}

# https
upstream ${PJ} {
    server  ${PJ}-1:${BACKEND_PORT} weight=5 ;
    server  ${PJ}-2:${BACKEND_PORT} weight=5 ;
}
#
server {
    listen       ${FRONT_HTTPS_PORT}  ssl ;
    server_name  ${FQDN} ;
    root         ${WEBSITE_BASE}/${FQDN} ;
    charset      utf-8;

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;
    # log
    access_log   /var/log/nginx/${FQDN}-access.log  main ;
    error_log    /var/log/nginx/${FQDN}-error.log ;

    # ssl
    ssl_certificate  /etc/letsencrypt/live/${FQDN}/fullchain.pem ;
    ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem ;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    # DHE不安全，ECDHE才行，否则安全检测是B
    #ssl_ciphers ECDHE+RSAGCM:ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:!aNULL!eNull:!EXPORT:!DES:!3DES:!MD5:!DSS;
    ssl_ciphers "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256:HIGH:!aNULL:!MD5:!ADH:!RC4:!DH" ;
    # ssl缓存
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 60m;
    # ssl代校验
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;  #一般为ca证书
    # dns解析指定
    #resolver 233.5.5.5 233.6.6.6 8.8.8.8 4.4.4.4  valid=300s;
    #resolver_timeout 2s;

    # proxy需要------------
    location / {
        proxy_pass  ${BACKEND_PROTOCOL}://${PJ} ;

        #Proxy Settings
        include  /etc/nginx/conf.d/proxy_params ;
    }
    # proxy end------------

    # error
    error_page 404 /404.html ;
        location = /40x.html {
    }
    error_page 500 502 503 504 /50x.html ;
        location = /50x.html {
    }

    # 附加项==============

    # 特殊情况============
    #
}
# ------------end------------
    "  > ${TMP_CONF_DIR}/${MODE}/${FQDN}.conf
}



F_HTTPS_REALSERVER_W()
{
    echo "
# ------------start------------
#
server {
    listen       ${FRONT_HTTPS_PORT}  ssl ;
    server_name  ${FQDN} ;
    root         ${WEBSITE_BASE}/${FQDN} ;
    charset      utf-8;

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;
    # log
    access_log   /var/log/nginx/${FQDN}-access.log  main ;
    error_log    /var/log/nginx/${FQDN}-error.log ;

    # ssl
    ssl_certificate  /srv/cert/${DOMAIN}/${DOMAIN}.crt ;
    ssl_certificate_key /srv/cert/${DOMAIN}/${DOMAIN}.key ;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    # DHE不安全，ECDHE才行，否则安全检测是B
    #ssl_ciphers ECDHE+RSAGCM:ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:!aNULL!eNull:!EXPORT:!DES:!3DES:!MD5:!DSS;
    ssl_ciphers "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256:HIGH:!aNULL:!MD5:!ADH:!RC4:!DH" ;
    # ssl缓存
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 60m;

    # 不缓存index.html
    location = /index.html {
        add_header Cache-Control \"no-cache, no-store\";
    }

    # error
    error_page 404 /404.html ;
        location = /40x.html {
    }
    error_page 500 502 503 504 /50x.html ;
        location = /50x.html {
    }

    # 附加项==============

    # 特殊情况============
    #
}
# ------------end------------
    "  > ${TMP_CONF_DIR}/${MODE}/${FQDN}.conf
}



F_HTTPS_PROXYSERVER_W()
{
    echo "
# ------------start------------
upstream ${PJ} {
    server  ${PJ}-1:${BACKEND_PORT} weight=5 ;
    server  ${PJ}-2:${BACKEND_PORT} weight=5 ;
}

server {
    listen       ${FRONT_HTTPS_PORT}  ssl ;
    server_name  ${FQDN} ;
    root         ${WEBSITE_BASE}/${FQDN} ;
    charset      utf-8;

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;
    # log
    access_log   /var/log/nginx/${FQDN}-access.log  main ;
    error_log    /var/log/nginx/${FQDN}-error.log ;

    # ssl
    ssl_certificate  /srv/cert/${DOMAIN}/${DOMAIN}.crt ;
    ssl_certificate_key /srv/cert/${DOMAIN}/${DOMAIN}.key ;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    # DHE不安全，ECDHE才行，否则安全检测是B
    #ssl_ciphers ECDHE+RSAGCM:ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:!aNULL!eNull:!EXPORT:!DES:!3DES:!MD5:!DSS;
    ssl_ciphers "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256:HIGH:!aNULL:!MD5:!ADH:!RC4:!DH" ;
    # ssl缓存
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 60m;

    # proxy需要------------
    location / {
        proxy_pass  ${BACKEND_PROTOCOL}://${PJ} ;

        #Proxy Settings
        include  /etc/nginx/conf.d/proxy_params ;
    }
    # proxy end------------

    # error
    error_page 404 /404.html ;
        location = /40x.html {
    }
    error_page 500 502 503 504 /50x.html ;
        location = /50x.html {
    }

    # 附加项==============

    # 特殊情况============
    #
}
# ------------end------------
    "  > ${TMP_CONF_DIR}/${MODE}/${FQDN}.conf
}



# 参数检查
TEMP=`getopt -o hlp:c:  -l help,list,protocol:,cert: -- "$@"`
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
            cat  "${WEB_PROJECT_LIST_FILE}"
            exit
            ;;
        -p|--protocol)
            PROTOCOL=$2
            shift 2
            case ${PROTOCOL} in
                http|https)
                    echo
                    ;;
                *)
                    echo -e "\n猪猪侠警告：【-p|--protocol】参数值仅支持 http|https \n"
                    exit 51
                    ;;
            esac
            ;;
        -c|--cert)
            CERT=$2
            shift 2
            case ${CERT} in
                w|wildcard|s|single)
                    echo
                    ;;
                *)
                    echo -e "\n猪猪侠警告：【-c|--cert】参数值仅支持 w|wildcard|s|single \n"
                    exit 51
                    ;;
            esac
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


# 待搜索的WEB项目清单
> ${WEB_PROJECT_LIST_FILE_TMP}
## 参数个数
if [[ $# -eq 0 ]]; then
    cp  ${WEB_PROJECT_LIST_FILE}  ${WEB_PROJECT_LIST_FILE_TMP}
else
    # 指定项目
    echo '#| **项目名** | **域名A记录** | **http端口** | **https端口** | **方式** | **后端协议端口** | **附加项** | **域名A记录IP** |' > ${WEB_PROJECT_LIST_FILE_TMP}
    for i in "$@"
    do
        #
        GET_IT='N'
        while read LINE
        do
            # 跳过以#开头的行或空行
            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
            #
            WEB_PROJECT_NAME=`echo $LINE | awk -F '|' '{print $2}'`
            WEB_PROJECT_NAME=`echo ${WEB_PROJECT_NAME}`
            if [ "x${WEB_PROJECT_NAME}" = x$i ]; then
                echo $LINE >> ${WEB_PROJECT_LIST_FILE_TMP}
                GET_IT='Y'
                break
            fi
        done < ${WEB_PROJECT_LIST_FILE}
        #
        if [ $GET_IT = 'N' ]; then
            echo -e "\n猪猪侠警告：项目【${i}】不在WEB项目列表【${WEB_PROJECT_LIST_FILE}】中，请检查！\n"
            exit 51
        fi
    done
fi



#
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    PJ=`echo $LINE | cut -f 2 -d \| `
    PJ=`echo $PJ`
    DOMAIN_A=`echo $LINE | cut -f 3 -d \| `
    DOMAIN_A=`echo $DOMAIN_A`
    FRONT_HTTP_PORT=`echo $LINE | cut -f 4 -d \| `
    FRONT_HTTP_PORT=`echo $FRONT_HTTP_PORT`
    FRONT_HTTPS_PORT=`echo $LINE | cut -f 5 -d \| `
    FRONT_HTTPS_PORT=`echo $FRONT_HTTPS_PORT`
    MODE=`echo $LINE | cut -f 6 -d \| `
    MODE=`echo $MODE`
    BACKEND_PROTOCOL_PORT=`echo $LINE | cut -f 7 -d \| `
    BACKEND_PROTOCOL_PORT=`echo $BACKEND_PROTOCOL_PORT`
    if [[ -n ${BACKEND_PROTOCOL_PORT} ]]; then
        BACKEND_PROTOCOL=`echo ${BACKEND_PROTOCOL_PORT} | cut -d : -f 1`
        BACKEND_PROTOCOL=`echo ${BACKEND_PROTOCOL}`
        BACKEND_PORT=`echo ${BACKEND_PROTOCOL_PORT} | cut -d : -f 2`
        BACKEND_PORT=`echo ${BACKEND_PORT}`
    fi
    ITEMS=`echo $LINE | cut -f 8 -d \| `
    ITEMS=`echo $ITEMS`
    # MODE目录
    [ ! -d "${TMP_CONF_DIR}/${MODE}" ] && mkdir "${TMP_CONF_DIR}/${MODE}"
    #
    if [[ -z $DOMAIN_A ]]; then
        FQDN=${PJ}
    else
        if [ "x${RUN_ENV}" = "xprod" ]; then
            FQDN="${DOMAIN_A}.${DOMAIN}"
        else
            FQDN="${RUN_ENV}-${DOMAIN_A}.${DOMAIN}"
        fi
    fi
    # do
    case ${PROTOCOL} in
        http)
            #
            case ${MODE} in
                realserver)
                    #
                    F_HTTP_REALSERVER
                    ;;
                proxyserver)
                    F_HTTP_PROXYSERVER
                    #
                    ;;
            esac
            ;;
        https)
            #
            case ${MODE} in
                realserver)
                    #
                    case ${CERT} in
                        w|wildcard)
                            F_HTTPS_REALSERVER_W
                            ;;
                        s|single)
                            F_HTTPS_REALSERVER_S
                            ;;
                    esac
                    ;;
                proxyserver)
                    #
                    case ${CERT} in
                        w|wildcard)
                            F_HTTPS_PROXYSERVER_W
                            ;;
                        s|single)
                            F_HTTPS_PROXYSERVER_S
                            ;;
                    esac
                    ;;
            esac
            #
            ;;
    esac
    #
    # 附加项
    ITEMS_NUM=`echo ${ITEMS} | grep -o , | wc -l`
    for ((i=${ITEMS_NUM}; i>=0; i--))
    do
        # 空
        if [ -z "${ITEMS}" ]; then
            break
        fi
        FIELD=$((i+1))
        ITEMS_SET=`echo ${ITEMS} | cut -d , -f ${FIELD}`
        ITEMS_SET=`echo ${ITEMS_SET}`
        # 空
        if [ -z "${ITEMS_SET}" ]; then
            continue
        fi
        #
        case "${ITEMS_SET}" in
            autoindex)
                # 开启目录浏览
                sed -i 's@.*附加项==============.*@&\n    ## 目录浏览\n    include /etc/nginx/conf.d/dir_params;@' ${TMP_CONF_DIR}/${MODE}/${FQDN}.conf
                ;;
            auth_basic)
                # 开启验证
                sed -i 's@.*附加项==============.*@&\n    ## 验证\n    include /etc/nginx/conf.d/auth_params;@' ${TMP_CONF_DIR}/${MODE}/${FQDN}.conf
                ;;
            upload_size*)
                # 文件上传
                UPLOAD_SIZE=`echo "${ITEMS_SET}" | cut -d '=' -f 2`
                sed -i "s@.*附加项==============.*@&\n    ## 文件上传\n    client_max_body_size ${UPLOAD_SIZE};@" ${TMP_CONF_DIR}/${MODE}/${FQDN}.conf
                ;;
            try_files)
                # try_files (因为【#】的404问题)
                sed -i 's/.*# 特殊情况============.*/&\n    ## 因为【#】问题，避免404\n    try_files \$uri \$uri\/ \/index.html;/' ${TMP_CONF_DIR}/${MODE}/${FQDN}.conf
                ;;
            *)
                echo -e "\n猪猪侠警告：【\${ITEMS_SET}】出现未定义的参数值【${ITEMS_SET}】，已忽略，请检查【${WEB_PROJECT_LIST_FILE} --> 附加项】，或自行在【SH_NAME】中定义你要的附加项参数，你可以的！\n"
                ;;
        esac
    done
    #
    # ========== 特殊处理START ==========                                                                                                                                                     
    #
    # 最好不要有
    #
    # ========== 特殊处理END ==========
    #
done < "${WEB_PROJECT_LIST_FILE_TMP}"


# copy to server
## conf
if [ -d "${TMP_CONF_DIR}/realserver" ]; then
    ansible  nginx_real  -m copy -a "src=${TMP_CONF_DIR}/realserver/  dest=${DST_CONF_DIR}/  owner=root group=root mode=644 backup=yes follow=yes"
fi
#
if [ -d "${TMP_CONF_DIR}/proxyserver" ]; then
    ansible  nginx_proxy -m copy -a "src=${TMP_CONF_DIR}/proxyserver/ dest=${DST_CONF_DIR}/  owner=root group=root mode=644 backup=yes follow=yes"
fi
#
ansible  nginx -m copy -a "src=${SH_PATH}/dir_params dest=${DST_CONF_DIR}/dir_params  owner=root group=root mode=644 backup=yes follow=yes"
ansible  nginx -m copy -a "src=${SH_PATH}/auth_params dest=${DST_CONF_DIR}/auth_params  owner=root group=root mode=644 backup=yes follow=yes"
ansible  nginx_proxy -m copy -a "src=${SH_PATH}/proxy_params dest=${DST_CONF_DIR}/proxy_params  owner=root group=root mode=644 backup=yes follow=yes"


# reload nginx
ansible nginx -m shell -a "nginx -t && systemctl reload nginx && echo -e 'Nginx reload - 成功 \n' || echo -e 'Nginx 配置文件测试 - 失败 \n'"



