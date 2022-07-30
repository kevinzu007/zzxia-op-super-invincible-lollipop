#!/bin/bash
# crontab
# 0 0 * * *  /srv/docker/elasticsearch-srv/rm-es-history.sh >> /srv/docker/elasticsearch-srv/rm-es-history.sh.log 2>&1


today=`date +%Y-%m-%d`;
echo "今天是${today}"

# 不指定参数时，默认删除daynum天前以logs-开头的数据
daynum=30

# 指定参数
if [ $# -ge 1 ] ;then
    daynum=$1
fi

esday=`date -d '-'"${daynum}"' day' +%Y.%m.%d`;
echo "${daynum}天前是${esday}"

curl -XDELETE http://127.0.0.1:9200/*-${esday}
echo
echo "${esday} 的log删除执行完成"


