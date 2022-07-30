#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# 用途：配置mailx



# 查找旧的
LINE_START=`grep -n  "##########KEVINZU_START##########" /etc/mail.rc | cut -d ":" -f 1 | head -n 1`
LINE_END=`grep -n  "##########KEVINZU_END##########"     /etc/mail.rc | cut -d ":" -f 1 | head -n 1`
# 删除旧的
if [ -z ${LINE_START}  -o  -z ${LINE_END} ]; then
    echo
elif [ ${LINE_START} -gt ${LINE_END} ]; then
    echo "内部错误"
    exit 1
else
    sed -i "${LINE_START},${LINE_END} d"  /etc/mail.rc
fi

# 追加新的
cat /tmp/mailrc >> /etc/mail.rc


