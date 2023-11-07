#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"


# 引入env
if [[ -f ./pgbadger.env ]]; then
    .  ./pgbadger.env
else
    echo -e "\n猪猪侠警告：环境变量文件【./pgbadger.env】不存在，请根据【./pgbadger.env.sample】生成"
    exit 52
fi
#PGBADGER_CMD=
#PG_LOG_PATH=
#DEST_CP_PATH=

# 本地env
PGBADGER_REPORT_PATH="${SH_PATH}/pg_report"
[[ -d ${PGBADGER_REPORT_PATH} ]] || mkdir  ${PGBADGER_REPORT_PATH}



echo '########################################'


# 日报，周报
echo "开始时间：`date`"
${PGBADGER_CMD}  -q -I  -O ${PGBADGER_REPORT_PATH}  ${PG_LOG_PATH}/postgresql-*.csv
echo "结束时间：`date`"


# 月报
if [[ $(date +%d) == 1 ]]; then
    PRE_MONTH=$(date -d '1 months ago' +%Y-%m)
    ${PGBADGER_CMD}  -q -I  --month-report ${PRE_MONTH}  ${PGBADGER_REPORT_PATH}
    echo "月报完成：`date`"
fi


# cp
rsync -r  ${PGBADGER_REPORT_PATH}  ${DEST_CP_PATH}/


