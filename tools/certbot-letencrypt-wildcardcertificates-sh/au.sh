#!/bin/bash

# 原项目地址：https://github.com/ywdblog/certbot-letencrypt-wildcardcertificates-alydns-au
# 已做修改


# certbot 传入以下变量:
# 相关文档：https://eff-certbot.readthedocs.io/en/stable/using.html
#           https://www.jianshu.com/p/a8f065e875d9
echo  "正在验证的域： ${CERTBOT_DOMAIN}"
echo  "验证字符串  _acme-challenge TXT：  ${CERTBOT_VALIDATION}"
echo  "当前挑战之后剩余的挑战数量:  ${CERTBOT_REMAINING_CHALLENGES}"
echo  "以逗号分隔的列表，列出了针对当前证书提出挑战的所有域:  ${CERTBOT_ALL_DOMAINS}"


echo "引入相关变量变量（猪猪侠）"
.  ${MY_PRIVATE_ENVS_DIR}/certbot-letencrypt-wildcardcertificates-sh.sec.env
# 或写在这里：
####### 根据自己的情况修改 Begin ##############
#
##PHP 命令行路径，如果有需要可以修改
#phpcmd="/usr/bin/php"
##Python 命令行路径，如果有需要可以修改
#pythoncmd="/usr/bin/python"
#
##填写阿里云的AccessKey ID及AccessKey Secret
##如何申请见https://help.aliyun.com/knowledge_detail/38738.html
#ALY_KEY=""
#ALY_TOKEN=""
#
##填写腾讯云的SecretId及SecretKey
##如何申请见https://console.cloud.tencent.com/cam/capi
#TXY_KEY=""
#TXY_TOKEN=""
#
##填写华为云的 Access Key Id 及 Secret Access Key
##如何申请见https://support.huaweicloud.com/devg-apisign/api-sign-provide.html
#HWY_KEY=""
#HWY_TOKEN=""
#
##GoDaddy的SecretId及SecretKey
##如何申请见https://developer.godaddy.com/getstarted
#GODADDY_KEY=""
#GODADDY_TOKEN=""
#
################# END ##############

PATH=$(cd `dirname $0`; pwd)

# 命令行参数
# 第一个参数：使用什么语言环境
# 第二个参数：使用那个 DNS 的 API
# 第三个参数：add or clean
plang=$1 #python or php
pdns=$2 #aly, txy, hwy, godaddy
paction=$3 #add or clean

#内部变量
cmd=""
key=""
token=""

if [[ "$paction" != "clean" ]]; then
    paction="add"
fi

case $plang in
    "php")
        cmd=$phpcmd
        if [[ "$pdns" == "aly" ]]; then
            dnsapi=$PATH"/php-version/alydns.php"
            key=$ALY_KEY
            token=$ALY_TOKEN
        elif [[ "$pdns" == "txy" ]]; then
            dnsapi="$PATH/php-version/txydns.php"
            key=$TXY_KEY
            token=$TXY_TOKEN
        elif [[ "$pdns" == "hwy" ]]; then
            # TODO
            dnsapi=""
            key=$HWY_KEY
            token=$HWY_TOKEN
            exit
        elif [[ "$pdns" == "godaddy" ]] ;then
            dnsapi="$PATH/php-version/godaddydns.php"
            key=$GODADDY_KEY
            token=$GODADDY_TOKEN
        else
            echo "Not support this dns services"
            exit
        fi
        ;;
    "python")
        cmd=$pythoncmd
        if [[ "$pdns" == "aly" ]]; then
            dnsapi=$PATH"/python-version/alydns.py"
            key=$ALY_KEY
            token=$ALY_TOKEN
        elif [[ "$pdns" == "txy" ]] ;then
            dnsapi=$PATH"/python-version/txydns.py"
            key=$TXY_KEY
            token=$TXY_TOKEN
        elif [[ "$pdns" == "hwy" ]]; then
            dnsapi="$PATH/python-version/hwydns.py"
            key=$HWY_KEY
            token=$HWY_TOKEN
        elif [[ "$pdns" == "godaddy" ]] ;then
            dnsapi=$PATH"/python-version/godaddydns.py"
            key=$GODADDY_KEY
            token=$GODADDY_TOKEN
        else
            echo "Not support this dns services"
            exit
        fi
        ;;
esac

$cmd $dnsapi $paction $CERTBOT_DOMAIN "_acme-challenge" $CERTBOT_VALIDATION $key $token >>"/var/log/certd.log"

if [[ "$paction" == "add" ]]; then
        # DNS TXT 记录刷新时间
        /bin/sleep 20
fi

