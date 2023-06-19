#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################

# 用途：将日志发送到指定邮箱
# 注意：脚本拷贝到/etc/cron.daily/下
# 依赖：/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
#       mailx



# 引入env
# cron必须主动引入
. /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
RUN_ENV=${RUN_ENV:-'dev'}
EMAIL=${EMAIL:-"zzxia@xxx.com"}

# 本地env
MAIL_ATTACH='/tmp/my.log'
MAIL_SUBJECT="【${RUN_ENV}】服务器日志：${MAIL_ATTACH} - ${HOSTNAME} - `date +'%F %T'`"
MAIL_CONTENT="请看附件"



if [ "x${RUN_ENV}" = "xdev" -o "x${RUN_ENV}" = "xstag" ]; then
    exit
fi

#if [ "x`du ${MAIL_ATTACH} | awk '{print $1}'`" != "x0" ]; then
if [ `cat ${MAIL_ATTACH} | wc -l` -gt 1 ]; then
    echo -e "cat ${MAIL_ATTACH}\n---\n`cat ${MAIL_ATTACH}`" | mailx -s "${MAIL_SUBJECT}"  ${EMAIL}  >/dev/null 2>&1
    > ${MAIL_ATTACH}
    chmod 0666 ${MAIL_ATTACH}
fi


