#!/bin/bash

# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}" || { echo -e "\n猪猪侠警告：这个错误是不可能的，这里是为了规避语法警告！\n" ; exit 53 ; }

# 自动从/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh引入以下变量

# 引入/etc/cert.sec.env"
if [ -f "/etc/cert.sec.env" ]; then
    source "/etc/cert.sec.env"
else
    echo "Warning: /etc/cert.sec.env 没发现，注意：第一次必须存在！"
fi

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
DINGDING_SEND_LIST_SH="/usr/local/bin/dingding_conver_to_markdown_list.sh"

# 查找 acme.sh
ACME_SH=""
if [ -f "/root/.acme.sh/acme.sh" ]; then
    ACME_SH="/root/.acme.sh/acme.sh"
elif [ -f "$HOME/.acme.sh/acme.sh" ]; then
    ACME_SH="$HOME/.acme.sh/acme.sh"
else
    # 尝试从 PATH 查找
    ACME_SH=$(which acme.sh)
fi

if [ -z "$ACME_SH" ]; then
    echo -e "\n猪猪侠警告：acme.sh 未安装，请安装先！\n"
    exit 1
fi


# 用法：
F_HELP()
{
    echo "
    用途：用于申请与更新Letsencrypt泛域名证书 (Use acme.sh)
    依赖：
        acme.sh
        /etc/cert.sec.env
        ${DINGDING_SEND_DEPLOY_SH}
    注意：
        * 输入命令时，参数顺序不分先后
    用法:
        $0  -h|--help
        $0  {--dns <dns_provider>}  {-r|--request <域名>}  [{-e|--email <邮箱>}]  [-t|--test]
        $0  {--dns <dns_provider>}  {-u|--update <域名>}  [-t|--test]
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
        -h|--help         此帮助
        --dns             指定 acme.sh dns api 方式，例如: dns_cf (Cloudflare), dns_ali (阿里云), dns_dp (腾讯云) 等，想获取更多，请从官网查找(https://github.com/acmesh-official/acme.sh/wiki/dnsapi)
        -r|--request      申请泛域名证书
        -u|--update       renew泛域名证书
        -e|--email        指定证书邮件地址 (用于注册账户)
        -t|--test         测试模式 (--staging --debug)
    示例:
        $0  -h
        $0  --dns dns_cf  -r aaa.com  -e my@aaa.com  -t     #--- 测试申请泛域名证书
        $0  --dns dns_cf  -r aaa.com  -e my@aaa.com         #--- 申请泛域名证书
        $0  --dns dns_cf  -u aaa.com                        #--- renew泛域名证书
    "
}


# 申请
F_CERT_REQUEST()
{
    # 注册账户 (如果需要)
    if [ ! -z "${EMAIL}" ]; then
         $ACME_SH --register-account -m ${EMAIL}
    fi

    # 构造命令
    CMD="$ACME_SH --issue --dns ${DNS_PROVIDER} -d ${THIS_DOMAIN} -d *.${THIS_DOMAIN} ${ACME_OPT}"
    
    echo "执行命令: $CMD"
    eval $CMD 2>&1 | tee "/tmp/${SH_NAME}.log"
    
    RET=${PIPESTATUS[0]}
    if [ $RET -eq 0 ]; then
        return 0
    else
        return 1
    fi
}



# renew
F_CERT_UPDATE()
{
    # 构造命令
    CMD="$ACME_SH --renew -d ${THIS_DOMAIN} ${ACME_OPT}"

    echo "执行命令: $CMD"
    eval $CMD 2>&1 | tee "/tmp/${SH_NAME}.log"

    RET=${PIPESTATUS[0]}
    if [ $RET -eq 0 ]; then
        return 0
    elif [ $RET -eq 2 ]; then
        # acme.sh returns 2 if not time to renew
        echo -e "\n猪猪侠警告：证书还在有效期，跳过！\n"
        return 2
    else
        return 1
    fi
}


# cp & ansible
F_GO()
{
    # acme.sh生成证书路径一般在 ~/.acme.sh/domain/
    # 注意: acme.sh 默认可能生成 ecc 证书，路径在 domain_ecc
    # 这里我们先尝试找 ecc 目录，没有再找普通目录
    
    ACME_DOMAIN_DIR="$HOME/.acme.sh/${THIS_DOMAIN}_ecc"
    if [ ! -d "$ACME_DOMAIN_DIR" ]; then
        ACME_DOMAIN_DIR="$HOME/.acme.sh/${THIS_DOMAIN}"
    fi
    
    if [ ! -d "$ACME_DOMAIN_DIR" ]; then
         echo -e "\n猪猪侠警告：找不到证书目录 $ACME_DOMAIN_DIR\n"
         return 1
    fi

    # cp
    CERT_TMP="/tmp/cert/${THIS_DOMAIN}"
    [ -d "${CERT_TMP}" ] || mkdir -p "${CERT_TMP}"
    
    # 复制证书文件
    # acme.sh文件命名: domain.key, domain.cer (fullchain: fullchain.cer, ca: ca.cer)
    # 我们映射回原脚本的命名习惯: 
    # privkey.pem -> domain.key
    # fullchain.pem -> domain.crt (and domain-ca.crt as per original script logic)
    
    cp -f "${ACME_DOMAIN_DIR}/${THIS_DOMAIN}.key"   "${CERT_TMP}/${THIS_DOMAIN}.key"
    cp -f "${ACME_DOMAIN_DIR}/fullchain.cer"        "${CERT_TMP}/${THIS_DOMAIN}.crt"
    cp -f "${ACME_DOMAIN_DIR}/fullchain.cer"        "${CERT_TMP}/${THIS_DOMAIN}-ca.crt"

    echo "证书已复制到 ${CERT_TMP}"

    # scp
    ansible nginx -m copy -a "src=${CERT_TMP}/  dest=/srv/cert/${THIS_DOMAIN}/  owner=root group=root mode=644 backup=yes follow=yes"

    # reload nginx
    ansible nginx -m shell -a "nginx -t  \
        && systemctl reload nginx  \
        && echo -e 'Nginx证书更新成功，Nginx reload成功！\n'  \
        && ${DINGDING_SEND_LIST_SH}  '【OK:证书更新:Nginx】'  '证书更新成功，Nginx reload成功！'  \
        || ( echo -e '证书更新成功，但Nginx reload 失败，请检查！\n'  \
        ; ${DINGDING_SEND_LIST_SH}  '【Err:证书更新:Nginx】'  '证书更新成功，但Nginx reload 失败，请检查！' )"
}



# 参数检查
# update parameters to support --dns
TEMP=`getopt -o htr:u:e:  -l help,test,dns:,request:,update:,email: -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 51
fi



# start
eval set -- "${TEMP}"
#

ACME_OPT=''
DNS_PROVIDER=''

while true
do
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -t|--test)
            ACME_OPT="${ACME_OPT} --staging --debug"
            shift
            ;;
        --dns)
            DNS_PROVIDER=$2
            shift 2
            ;;
        -e|--email)
            EMAIL=$2
            shift 2
            ;;
        -r|--request)
            THIS_DOMAIN=$2
            MODE="request"
            shift 2
            ;;
        -u|--update)
            THIS_DOMAIN=$2
            MODE="update"
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

if [ -z "$DNS_PROVIDER" ] && [ "$MODE" == "request" ]; then
    echo -e "\n猪猪侠警告：必须指定DNS提供商 (--dns)\n"
    exit 51
fi

if [ -z "$THIS_DOMAIN" ]; then
     echo -e "\n猪猪侠警告：必须指定域名 (-r 或 -u)\n"
     exit 51
fi


if [ "$MODE" == "request" ]; then
            # Check if cert exists handled by acme.sh usually, but we can do a check if we want.
            # acme.sh handles it.
            
            echo "申请证书：*.${THIS_DOMAIN} "
            F_CERT_REQUEST
            RET=$?
            if [ $RET -eq 0 ]; then
                echo -e "\n泛域名证书申请成功！\n"
                ${DINGDING_SEND_LIST_SH}  "【Info:证书申请:*.${THIS_DOMAIN}】"  "泛域名证书申请成功！"
                # 拷贝到web服务器
                F_GO
                exit 50
            else
                echo -e "\n泛域名证书申请失败，请检查！\n日志：/tmp/${SH_NAME}.log \n"
                ${DINGDING_SEND_LIST_SH}  "【Err:证书申请:*.${THIS_DOMAIN}】"  "泛域名证书申请失败，请检查！"  "日志：/tmp/${SH_NAME}.log"
                exit 54
            fi
elif [ "$MODE" == "update" ]; then
            echo "renew证书：*.${THIS_DOMAIN} "
            F_CERT_UPDATE
            RET=$?
            if [ $RET -eq 0 ]; then
                echo -e "\n泛域名证书renew成功！\n"
                ${DINGDING_SEND_LIST_SH}  "【Info:证书更新:*.${THIS_DOMAIN}】"  "泛域名证书renew成功！"
                # 拷贝到web服务器
                F_GO
                exit 50
            elif [ $RET -eq 2 ]; then
                 echo -e "\n证书还在有效期，跳过！\n"
                 exit 55
            else
                echo -e "\n泛域名证书更新失败，请检查！\n日志：/tmp/${SH_NAME}.log \n"
                ${DINGDING_SEND_LIST_SH}  "【Err:证书更新:*.${THIS_DOMAIN}】"   "证书更新失败，请检查！"  "日志：/tmp/${SH_NAME}.log"
                exit 54
            fi
fi
