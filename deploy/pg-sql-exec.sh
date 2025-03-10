#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7

set -e
set -o


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 引入env
. ${SH_PATH}/env.sh

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
PGSQL_CMD='/usr/local/pgsql/bin/pgsql'
SQL_LIST="${SH_PATH}/log/sql-script.list"


# 检查重复运行
[ `ps -ef | grep "${0##*/}" | grep -v grep | wc -l` -ne 2 ] && echo -e '\n\n注意：其他用户正在运行此程序，请稍后再试！' && exit 1



# 用法：
F_HELP()
{
    echo "
    用途：执行sql脚本
          --go        执行以 .sql 结尾的sql脚本文件
          --rollback  执行以 .sql.rollback 结尾的sql回滚脚本文件
    用法:
    sh $0 [-h|--help]
    sh $0 [--go|--rollback] [sql脚本目录]
    "
}



# 参数检查
case "$1" in
    "-h"|"--help")
        F_HELP
        exit 0
        ;;
    "--go")
        [ "x$2" = "x" ] && echo '参数2不能为空' && exit 1
        [ -d $2 ] && echo '目录不存在，请检查！' && exit 1
        ls -1 $2/*sql | sort -n  > ${SQL_LIST}
        ;;
    "--rollback")
        [ "x$2" = "x" ] && echo '参数2不能为空' && exit 1
        [ -d $2 ] && echo '目录不存在，请检查！' && exit 1
        ls -1 $2/*sql.rollback | sort -n -r  > ${SQL_LIST}
        ;;
    *)
        F_HELP
        echo '骚年，请输入正确的脚本命令参数！'
        exit 1
        ;;
esac



# 生成db列表 - 排除系统数据库及其他噪音
${PGSQL_CMD} -h ${PG_SERVER} -c "\l" | cut -d \| -f 1 | sed -e '1,3d' -e '/rows)/d' | sed -e '/template/d' -e '/postgres/d' | sed -e '/^\s*$/d' -e 's/[ \t]*//g'  > ${PG_DB_LIST}



#
for LINE in `cat ${SQL_LIST}`
do
    SQL_FILE=${LINE}

    #
    No=`echo ${LINE##*/} | cut -d - -f 1`
    [ "x${No}" = x ] && continue
    [[ ${No} =~ [0-9]+$ ]] || echo "文件开头【${No}】不是数字" && continue

    #
    DB=`echo ${LINE##*/} | cut -d - -f 2`
    #
    echo ---------- ${DB} ----------
    # 列表匹配
    if [ "x${DB}" != "x" ]; then
        search_r=$( grep -v '^#' ${PG_DB_LIST} | awk -F '|' '{print $4}' | grep ${DB} )
        GET_IT=N
        for i in ${search_r}
        do
            if [ "x$i" = "x${DB}" ]; then
                GET_IT=Y
                break
            fi
        done
        if [ "x${GET_IT}" = "xN" ]; then
            echo -e "\n数据库【${DB}】不在目标列表中，请检查！\n"
            exit 1
        fi
    else
        echo "数据库名为空，跳过！"
        continue
    fi

    #
    ${PGSQL_CMD} -h ${PG_SERVER} -d ${DB} -L ./${SQL_FILE}.log -f ./${SQL_FILE}
    [ $? -eq 0 ] && echo SUCCESS || echo FAIL
done



