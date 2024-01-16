#!/bin/bash


# 指定用户下运行
if [ ${USER} != 'root' ]; then
    echo '请在root用户下运行！'
    exit 1
fi


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 自动从/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh引入以下变量

# 引入env

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
## 自动申请更新泛域名证书sh路径
AU_SH="${SH_PATH}/certbot-letencrypt-wildcardcertificates-sh/au.sh"
DINGDING_SEND_LIST_SH="/usr/local/bin/dingding_conver_to_markdown_list.sh"


# 用法：
F_HELP()
{
    echo "
    用途：用于申请与更新Letsencrypt泛域名证书
    依赖：
        certbot
        ${AU_SH}
    注意：
        * 本脚本基于项目https://github.com/ywdblog/certbot-letencrypt-wildcardcertificates-alydns-au
        * 输入命令时，参数顺序不分先后
    用法:
        $0  [-h|--help]
        $0  [-y|--yun [aly|hwy|godaddy]]  [-r|--request|-u|--update {域名}]  [-e|--email {邮箱}]  <-t|--test>   #--- 申请或renew泛域名证书
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是一个整体，是必选项，默认是必选项（即没有括号【[]、<>】时也是必选项），一般用于表示参数对，此时不可乱序，单个参数也可以使用括号
        <>   : 代表是一个整体，是可选项，默认是必选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help         此帮助
        -y|--yun          指定dns解析商，aly：阿里云；txy：腾讯云；hwy：华为云；godaddy，需要设置certbot-letencrypt-wildcardcertificates-sh/au.sh中相应的key、secret
        -r|--request      申请泛域名证书
        -u|--update       renew泛域名证书，要求同上
        -e|--email        指定证书邮件地址
        -t|--test         以--dry-run方式运行演练测试
    示例:
        $0  -h
        $0  -y aly  -r aaa.com  -e my@aaa.com  -t     #--- 测试申请泛域名证书，dns域名解析商是阿里云，域名是aaa.com，邮箱是my@aaa.com
        $0  -y aly  -r aaa.com  -e my@aaa.com         #--- 申请泛域名证书，dns域名解析商是阿里云，域名是aaa.com，邮箱是my@aaa.com
        $0  -y aly  -u aaa.com  -e my@aaa.com         #--- renew泛域名证书，dns域名解析商是阿里云，域名是aaa.com，邮箱是my@aaa.com
    "
}


# 时间差计算函数
F_TimeDiff ()
{
    # 时间格式：2019-01-08T19:41:59
    FV_StartTime=$1
    FV_EndTime=$2
    #
    FV_ST=$(date -d "${FV_StartTime}" +%s)
    FV_ET=$(date -d "${FV_EndTime}"   +%s)
    #
    FV_SecondsDiff=$((FV_ET - FV_ST))
    #
    if [ ${FV_SecondsDiff} -ge 0 ];then
        #
        FV_Days=$(( FV_SecondsDiff / 86400 ))
        FV_Hours=$((FV_SecondsDiff/3600%24))
        FV_Minutes=$((FV_SecondsDiff/60%60))
        FV_Seconds=$((FV_SecondsDiff%60))

        echo "耗时: ${FV_Days} Days ${FV_Hours} Hours ${FV_Minutes} Minutes ${FV_Seconds} Seconds"
        return 0
    else
        echo "Error, 请检查。 ---可能原因：1、时间格式不合格； 2、date2小于date1 ！"
        return 1
    fi
}



# 申请
F_CERT_REQUEST()
{
    certbot  certonly  ${CERTBOT_OPT}  \
        --agree-tos  \
        -m ${EMAIL}  \
        -d ${THIS_DOMAIN} -d *.${THIS_DOMAIN}  \
        --manual --preferred-challenges dns  \
        --manual-auth-hook "${AU_SH} python ${YUN} add"  \
        --manual-cleanup-hook "${AU_SH} python ${YUN} clean"  \
        --manual-public-ip-logging-ok  2>&1  \
        | tee "/tmp/${SH_NAME}.log"
    # 成功:
    # - Congratulations! Your certificate and chain have been saved at:
    #   /etc/letsencrypt/live/ccunion.net/fullchain.pem
    # 测试成功：
    #  - The dry run was successful.
    if [[ `grep -A 1 'Your certificate and chain have been saved at' "/tmp/${SH_NAME}.log"  \
        | grep "${THIS_DOMAIN}" >/dev/null 2>&1  \
        ; echo $?` == 0 ]]; then
        # '证书申请成功'
        return 0
        #
    elif [[ `grep 'The dry run was successful' "/tmp/${SH_NAME}.log" >/dev/null 2>&1  \
        ; echo $?` == 0 ]]; then
        return 9
        #
    elif [[ `grep 'The dry run was failed' "/tmp/${SH_NAME}.log" >/dev/null 2>&1  \
        ; echo $?` == 0 ]]; then
        return 8
        #
    else
        # "证书申请失败"
        return 1
        #
    fi
}



# renew
F_CERT_UPDATE()
{
    certbot  renew  ${CERTBOT_OPT}  \
        --agree-tos  -m ${EMAIL}  \
        --cert-name ${THIS_DOMAIN}  \
        --manual --preferred-challenges dns  \
        --manual-auth-hook "${AU_SH} python ${YUN} add"  \
        --manual-cleanup-hook "${AU_SH} python ${YUN} clean" 2>&1  \
        | tee "/tmp/${SH_NAME}.log"
    #
    # ！！！以下部分，时而会变，如果出现异常，请检查日志，并修改判断条件！！！
    #
    # 成功：
    ## Congratulations, all renewals succeeded:
    ##   /etc/letsencrypt/live/gc-life.com/fullchain.pem (success)
    ## 还在有效期：
    ## The following certificates are not due for renewal yet:
    ##  /etc/letsencrypt/live/ccunion.net/fullchain.pem expires on 2020-08-12 (skipped)
    # 失败：
    ## Processing /etc/letsencrypt/renewal/baowanjia.com.conf
    ## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ## OCSP check failed for /etc/letsencrypt/archive/baowanjia.com/cert1.pem (are we offline?)
    ## Cert not yet due for renewal
    ##
    ## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ##
    ## The following certificates are not due for renewal yet:
    ##   /etc/letsencrypt/live/baowanjia.com/fullchain.pem expires on 2021-02-10 (skipped)
    ## No renewals were attempted.
    # 测试成功：
    ## Congratulations, all renewals succeeded. The following certificates have been renewed:
    ##   /etc/letsencrypt/live/ccunion.net/fullchain.pem (success)
    ## ** DRY RUN: simulating 'certbot renew' close to cert expiry
    ## **          (The test certificates above have not been saved.)
    # 测试失败：
    ## All renewal attempts failed. The following certificates could not be renewed:
    ##   /etc/letsencrypt/live/gc-life.com/fullchain.pem (failure)
    ## ** DRY RUN: simulating 'certbot renew' close to cert expiry
    ## **          (The test certificates above have not been saved.)
    if [[ `grep -A 3 'all renewals succeeded' "/tmp/${SH_NAME}.log"  \
        | grep -A 2 "${THIS_DOMAIN}"  \
        | grep 'The test certificates above have not been saved' >/dev/null 2>&1  \
        ; echo $?` == 0 ]]; then
        # 测试成功
        return 9
        #
    elif [[ `grep -A 3 'All renewal attempts failed. The following certificates could not be renewed' "/tmp/${SH_NAME}.log"  \
        | grep -A 2 "${THIS_DOMAIN}"  \
        | grep 'The test certificates above have not been saved' >/dev/null 2>&1  \
        ; echo $?` == 0 ]]; then
        # 测试失败
        return 8
        #
    elif [[ `grep -A 1 'all renewals succeeded' "/tmp/${SH_NAME}.log"  \
        | grep "${THIS_DOMAIN}" >/dev/null 2>&1  \
        ; echo $?` == 0 ]]; then
        # '证书renew成功'
        return 0
        #
    elif [[ `grep 'OCSP check failed'  "/tmp/${SH_NAME}.log"` != 0 ]]  \
        && [[ `grep -A 1 'The following certificates are not due for renewal yet'  "/tmp/${SH_NAME}.log"  \
        | grep "${THIS_DOMAIN}"  \
        | grep 'skipped' >/dev/null 2>&1  \
        ; echo $?` == 0 ]]; then
        # "证书还在有效期"
        return 2
        #
    else
        # "证书renew失败"
        # "证书renew时OCSP失败一般是暂时的)"
        return 1
        #
    fi
}


F_YUN()
{
    case $1 in
        aly|txy|hwy|godaddy)
            # ok
            return 0
            ;;
        *)
            echo -e "猪猪侠警告：参数错误，只能使用以下几种参数：\n  aly : 代表阿里云\n  txy : 代表腾讯云\n  hwy : 代表华为云\n  godaddy : 代表godaddy\n"
            return 1
            ;;
    esac
}


# cp
F_GO()
{
    # cp
    CERT_TMP="/tmp/cert/${THIS_DOMAIN}"
    [ -d "${CERT_TMP}" ] || mkdir -p "${CERT_TMP}"
    cp -f /etc/letsencrypt/live/${THIS_DOMAIN}/privkey.pem    ${CERT_TMP}/${THIS_DOMAIN}.key
    cp -f /etc/letsencrypt/live/${THIS_DOMAIN}/fullchain.pem  ${CERT_TMP}/${THIS_DOMAIN}.crt
    cp -f /etc/letsencrypt/live/${THIS_DOMAIN}/fullchain.pem  ${CERT_TMP}/${THIS_DOMAIN}-ca.crt

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
TEMP=`getopt -o hty:r:u:e:  -l help,test,yun:,request:,update:,email: -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 51
fi



# start
eval set -- "${TEMP}"
#
# 获取次要命令参数
SH_ARGS_NUM=$#
SH_ARGS[0]="占位"
for ((i=1;i<=SH_ARGS_NUM;i++)); do
    eval K=\$$i
    SH_ARGS[$i]=$K
    #echo SH_ARGS数组$i列的值是: ${SH_ARGS[$i]}
done
#
CERTBOT_OPT=''
SH_ARGS_ARR_NUM=${#SH_ARGS[@]}
for ((i=1;i<SH_ARGS_ARR_NUM;i++))
do
    case ${SH_ARGS[$i]} in
        -h|--help)
            F_HELP
            exit
            ;;
        -t|--test)
            CERTBOT_OPT="${CERTBOT_OPT}  --dry-run"
            ;;
        -y|--yun)
            j=$((i+1))
            YUN=${SH_ARGS[$j]}
            # yun
            F_YUN ${YUN}
            if [[ $? == 1 ]]; then
                echo -e "\n猪猪侠警告：dns云服务商参数错误！\n"
                exit 51
            fi
            ;;
        -e|--email)
            EMAIL=$2
            shift 2
            EMAIL_REGULAR='^[a-zA-Z0-9]+[a-zA-Z0-9_\.]*@([a-zA-Z0-9]+[a-zA-Z0-9\-]*[a-zA-Z0-9]\.)*[a-z]+$'
            if [[ ! "${EMAIL}" =~ ${EMAIL_REGULAR} ]]; then
                echo -e "\n猪猪侠警告：【${EMAIL}】邮件地址不合法\n"
                exit 51
            fi
            ;;
        --)
            break
            ;;
        *)
            # 跳过
            ;;
    esac
done
#

if [[ -z ${YUN} ]]; then
    echo -e "\n猪猪侠警告：必要参数【-y|--yun】缺失，请查看帮助【$0 --help】\n"
    exit 51
fi

# 获取主要参数，运行
while true
do
    #
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -t|--test)
            shift
            ;;
        -y|--yun)
            shift 2
            ;;
        -r|--request)
            THIS_DOMAIN=$2
            shift 2
            #
            certbot  certificates | grep "*.${THIS_DOMAIN}" > /dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                echo -e "\n【*.${THIS_DOMAIN}】泛域名证书已存在，退出！\n"
                exit 53
            fi
            #
            echo "申请证书：*.${THIS_DOMAIN} "
            F_CERT_REQUEST
            case $? in
                0)
                    echo -e "\n泛域名证书申请成功！\n"
                    ${DINGDING_SEND_LIST_SH}  "【Info:证书申请:*.${THIS_DOMAIN}】"  "泛域名证书申请成功！"
                    # 拷贝到web服务器
                    #F_GO
                    exit 50
                    ;;
                1)
                    echo -e "\n泛域名证书申请失败，请检查！\n日志：/tmp/${SH_NAME}.log \n"
                    ${DINGDING_SEND_LIST_SH}  "【Err:证书申请:*.${THIS_DOMAIN}】"  "泛域名证书申请失败，请检查！"  "日志：/tmp/${SH_NAME}.log"
                    exit 54
                    ;;
                9)
                    echo -e "\n证书申请：测试结果为成功，可以放心使用！\n"
                    exit 50
                    ;;
                8)
                    echo -e "\n证书申请：测试结果为失败，请检查！\n"
                    exit 54
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未知函数返回值，请检查！\n"
                    exit 1
                    ;;
            esac
            ;;
        -u|--update)
            THIS_DOMAIN=$2
            shift 2
            # 是否存在该证书
            certbot  certificates | grep "*.${THIS_DOMAIN}" > /dev/null 2>&1
            if [[ $? -ne 0 ]]; then
                echo -e "\n【*.${THIS_DOMAIN}】泛域名证书不存在，请先申请证书，退出！\n"
                exit 53
            fi
            #
            echo "renew证书：*.${THIS_DOMAIN} "
            F_CERT_UPDATE
            case $? in
                0)
                    echo -e "\n泛域名证书renew成功！\n"
                    ${DINGDING_SEND_LIST_SH}  "【Info:证书更新:*.${THIS_DOMAIN}】"  "泛域名证书renew成功！"
                    # 拷贝到web服务器
                    #F_GO
                    exit 50
                    ;;
                2)
                    echo -e "\n证书还在有效期，跳过！\n"
                    exit 55
                    ;;
                1)
                    echo -e "\n泛域名证书更新失败，请检查！\n日志：/tmp/${SH_NAME}.log \n"
                    ${DINGDING_SEND_LIST_SH}  "【Err:证书更新:*.${THIS_DOMAIN}】"   "证书更新失败，请检查！"  "日志：/tmp/${SH_NAME}.log"
                    exit 54
                    ;;
                9)
                    echo -e "\n证书更新：测试结果为成功，可以放心使用！\n"
                    #exit 9
                    exit 50
                    ;;
                8)
                    echo -e "\n证书更新：测试结果为失败，请检查！\n"
                    exit 54
                    ;;
                *)
                    echo -e "\n猪猪侠警告：未知函数返回值，请检查！\n"
                    exit 1
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


