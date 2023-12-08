#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# 用途：用户登录时发送消息通知
# 注意：脚本拷贝到/etc/profile.d/下
# 依赖：/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
#       /usr/local/bin/dingding_send_markdown-login.sh



# 引入env
# 自动从/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh引入以下变量
RUN_ENV=${RUN_ENV:-'dev'}
EMAIL=${EMAIL:-"kevinzu@xxx.com"}
TRUST_IPS=${TRUST_IPS:-'办公室:111.111.111., 家:222.222.22'}

# 本地env
LOG_FILE='/tmp/my.log'
if [ ! -f "${LOG_FILE}" ]; then
    touch "${LOG_FILE}"
    chmod 0666 "${LOG_FILE}"
fi
# sh
DINGDING_MARKDOWN_LOGIN_SH='/usr/local/bin/dingding_send_markdown-login.sh'


# 钉钉
F_SEND_DINGDING()
{
    ${DINGDING_MARKDOWN_LOGIN_SH}  \
        --title "【Alert:SSH登录:${RUN_ENV}】"  \
        --message "$( echo -e "### `echo ${USER} \(sudo:${SUDO_USER}\) ` \n### `echo ${IP}` \n### `echo ${AREA}` \n\n---\n\n` w | sed '1,2d' `" )"
}

# 邮件
F_SEND_MAIL()
{
    echo -e " 用户名：${USER} \n 用户IP：${IP} \n 来  自：${AREA}\n---\n` w | sed '1,2d' `" | mailx  -s "【${RUN_ENV}】SSH登录：${USER} (sudo:${SUDO_USER})"  ${EMAIL}  >/dev/null 2>&1
}

# 日志
F_MY_LOG()
{
    echo -e "| `date +'%FT%T'` | ${HOSTNAME} | 用户名: ${USER}(sudo:${SUDO_USER}) | SSH登录 | 用户IP: ${IP} 来自: ${AREA} |" >> ${LOG_FILE}
    w >> ${LOG_FILE}
}

# 回显
F_ECHO()
{
    echo -e " 用户名：${USER} \n 用户IP：${IP} \n 来  自：${AREA} "
}

# 信任IP
F_TRUST_IP()
{
    F_MY_LOG
    WEEK_N=`date +%w`
    if [ ${WEEK_N} = 6 -o ${WEEK_N} = 0 ]; then
        F_SEND_DINGDING & >/dev/null 2>&1
    else
        F_ECHO
    fi
}

# 其他IP
F_OTHER_IP()
{
    AREA=` curl -s "http://www.cip.cc/${IP}" | grep '数据二' | awk -F ":" '{print $2}' | awk '{gsub(/^\s+|\s+$/, ""); print}' | awk '{gsub(/\s+/, ""); print}' `
    #AREA=` curl -s https://api.ip.sb/geoip/${IP} | jq '.country,.region,.city' 2>/dev/null | sed -n 's/\"/ /gp' | awk 'NR == 1{printf "%s->",$0} NR == 2{printf "%s->",$0} NR == 3{printf     "%s\n",$0}' `
    if [ "x${AREA}" = "x" -o "x${AREA}" = "xnull" ]; then
        AREA="获取地理位置失败【IP：${F_IP}】"
    fi
    AREA=`echo ${AREA} | sed 's/\"//g'`
    F_MY_LOG
    F_SEND_DINGDING & >/dev/null 2>&1
}



# 必须软件jq
if [ "`which jq >/dev/null 2>&1 ; echo $?`" != "0" ]; then
    echo -e "| `date +'%FT%T'` | ${HOSTNAME} | 用户名: ${USER}(sudo:${SUDO_USER}) | echo $0 | echo '请安装软件jq' |" >> ${LOG_FILE}
    ${DINGDING_MARKDOWN_LOGIN_SH}  \
        --title "【Error:用户登录:${RUN_ENV}】"  \
        --message "$( echo -e "### 请安装软件jq" )"
fi


#
IP=`echo ${SSH_CLIENT} | awk '{print $1}'`
#
if [ "x${IP}" = "x" ]; then
    # 本机登录
    # sudo及su时 ${IP} 为空
    IP='IP为空'
    AREA="本机"
    F_MY_LOG
elif [[ "${IP}" =~ ^10\.|^172\.1[6-9]|^172\.2[0-9]|^172\.3[01]|^192\.168 ]]; then
    # 非本机登录
    # 私网登录：内网登录及ansible时，为避免信息风暴，不发消息
    AREA="私网地址"
    F_MY_LOG
elif [[ -z ${TRUST_IPS} ]]; then
    # 非本机登录
    # 其他未知区域
    F_OTHER_IP
else
    TRUST_IPS_NUM=$(echo ${TRUST_IPS} | grep -o , | wc -l)
    GOT_IT='N'
    for ((i=${TRUST_IPS_NUM}; i>=0; i--)); do
        FIELD=$((i+1))
        TRUST_IP_X=$(echo ${TRUST_IPS} | cut -d , -f ${FIELD})
        TRUST_IP_X_n=$(echo ${TRUST_IP_X} | cut -d : -f 1)
        TRUST_IP_X_ip=$(echo ${TRUST_IP_X} | cut -d : -f 2)
        if [[ "x${IP}" == x${TRUST_IP_X_ip}* ]]; then
            # 非本机登录
            # 信任IP登录仅周末发消息
            AREA="${TRUST_IP_X_n}"
            F_TRUST_IP
            GOT_IT='Y'
            break
        fi
    done
    #
    if [[ ${GOT_IT} != 'Y' ]]; then
        # 非本机登录
        # 其他未知区域
        F_OTHER_IP
    fi
fi


