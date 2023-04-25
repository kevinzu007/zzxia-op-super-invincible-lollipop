#!/bin/bash

echo
echo "用法： $0  <csv日志清单文件>    #-- 默认导入今天所有的日志"
echo

LOG_PATH="/usr/local/pgsql/data/log"
LOG_FILE_LIST="pg_log.list"
LOG_ANALYSE_DB="pg_ana_log"
LOG_ANALYSE_TABLE="pg_csvlog_shell"


TIME=${TIME:-`date +%Y-%m-%dT%H:%M:%S`}
TIME_START=${TIME}
DATE_DAY=`date -d "${TIME}" +%Y%m%d`
LOG_ANALYSE_TABLE="${LOG_ANALYSE_TABLE}_${DATE_DAY}"

if [[ $# == 0 ]]; then
    ls -l ${LOG_PATH}/postgresql-$(date -d "${TIME}" +%Y-%m-%d)_*csv | awk '{print $9}' > ${LOG_FILE_LIST}
else
    LOG_FILE_LIST=$1
fi

echo ""
echo "##################################################"
echo "说明："
echo "数据库名：${LOG_ANALYSE_DB}"
echo "数据库名：${LOG_ANALYSE_TABLE}"
echo "数据库日志文件路径：${LOG_PATH}"
echo "数据库日志文件清单："
cat ${LOG_FILE_LIST}
echo ""
read -t 10 -p '按任意键继续......'

echo "##################################################"
echo "创建库表"
/usr/local/pgsql/bin/psql << EOF
    DROP DATABASE  "${LOG_ANALYSE_DB}";
    CREATE DATABASE  "${LOG_ANALYSE_DB}";
    \c  "${LOG_ANALYSE_DB}"
    CREATE TABLE IF NOT EXISTS  "${LOG_ANALYSE_TABLE}" (
      log_time timestamp(3) with time zone,
      user_name text,
      database_name text,
      process_id integer,
      connection_from text,
      session_id text,
      session_line_num bigint,
      command_tag text,
      session_start_time timestamp with time zone,
      virtual_transaction_id text,
      transaction_id bigint,
      error_severity text,
      sql_state_code text,
      message text,
      detail text,
      hint text,
      internal_query text,
      internal_query_pos integer,
      context text,
      query text,
      query_pos integer,
      location text,
      application_name text,
      backend_type text,
      leader_pid integer,
      query_id bigint,
      PRIMARY KEY (session_id, session_line_num)
    );
    comment on column  ${LOG_ANALYSE_TABLE}.log_time           is '日志时间，带毫秒的时间戳';
    comment on column  ${LOG_ANALYSE_TABLE}.user_name          is '当前登录数据库的用户名';
    comment on column  ${LOG_ANALYSE_TABLE}.database_name      is '数据库名';
    comment on column  ${LOG_ANALYSE_TABLE}.process_id         is '进程ID';
    comment on column  ${LOG_ANALYSE_TABLE}.connection_from    is '客户端主机:端口号';
    comment on column  ${LOG_ANALYSE_TABLE}.session_id         is '会话ID 由后台进程启动时间和PID组成';
    comment on column  ${LOG_ANALYSE_TABLE}.session_line_num   is '每个会话的行号，类似history命令';
    comment on column  ${LOG_ANALYSE_TABLE}.command_tag        is '命令标签';
    comment on column  ${LOG_ANALYSE_TABLE}.session_start_time     is '会话开始时间';
    comment on column  ${LOG_ANALYSE_TABLE}.virtual_transaction_id is '虚拟事务ID';
    comment on column  ${LOG_ANALYSE_TABLE}.transaction_id         is '事务ID';
    comment on column  ${LOG_ANALYSE_TABLE}.error_severity     is '错误等级';
    comment on column  ${LOG_ANALYSE_TABLE}.sql_state_code     is 'SQLSTATE 代码';
    comment on column  ${LOG_ANALYSE_TABLE}.message            is '消息 SQL语句';
    comment on column  ${LOG_ANALYSE_TABLE}.detail             is '错误消息详情';
    comment on column  ${LOG_ANALYSE_TABLE}.hint               is '提示';
    comment on column  ${LOG_ANALYSE_TABLE}.internal_query     is '导致错误的内部查询（如果有）';
    comment on column  ${LOG_ANALYSE_TABLE}.internal_query_pos is '错误位置所在的字符计数';
    comment on column  ${LOG_ANALYSE_TABLE}.context            is '错误上下文';
    comment on column  ${LOG_ANALYSE_TABLE}.query              is '导致错误的用户查询（如果有且被log_min_error_statement启用）';
    comment on column  ${LOG_ANALYSE_TABLE}.query_pos          is '错误位置所在的字符计数';
    comment on column  ${LOG_ANALYSE_TABLE}.location           is '在 PostgreSQL 源代码中错误的位置（如果log_error_verbosity被设置为verbose）';
    comment on column  ${LOG_ANALYSE_TABLE}.application_name   is '应用名';
    comment on column  ${LOG_ANALYSE_TABLE}.backend_type       is '后端类型（新加）';
    comment on column  ${LOG_ANALYSE_TABLE}.leader_pid         is 'Leader进程ID（新加）';
    comment on column  ${LOG_ANALYSE_TABLE}.query_id           is '查询ID（新加）';
    \q
EOF

read -t 20 -p '按任意键继续......'

echo "##################################################"
echo "导入csv"
while read file
do
    echo "----- ${file} -----"
    /usr/local/pgsql/bin/psql << EOF
    \c ${LOG_ANALYSE_DB}
    copy  ${LOG_ANALYSE_TABLE}  from  '${file}'  with csv;
    \q
EOF
done < ${LOG_FILE_LIST}

echo ""
echo "OK !"



