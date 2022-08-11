#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# 指定用户下运行
if [ ${USER} != 'postgres' ]; then
    echo '请在postgres用户下运行！'
    exit 1
fi

# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 引入env
# 自动从/etc/profile.d/run-env.sh引入以下变量
. /etc/profile.d/run-env.sh      #--- 计划任务中运行时，须source引入
#RUN_ENV=

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}

# sh
DINGDING_MARKDOWN_PY="/usr/local/bin/dingding_conver_to_markdown_list.py"
PGSQL_CMD_BASE='/usr/local/pgsql/bin'



# 用法：
F_HELP()
{
    echo "
    用途：用于pg数据库备份or还原，一次仅处理一个数据库。
    依赖：
        /etc/profile.d/run-env.sh
        ${DINGDING_MARKDOWN_PY}
    注意：必须在postgres账户下运行
    用法:
        $0  [-h|--help]
        $0  [-b--backup]    [PATH_TO_FILENAME]  [数据库名]     #--- 备份，文件格式为gzip，备份时会自动在指定的名字后面自动加上.gz
        $0  [-r|--restore]  [PATH_TO_FILENAME]  [数据库名]     #--- 恢复，文件须为gzip格式
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        #
        -h|--help
        --backup    [备份路径文件名] [数据库名]   备份
        --resotore  [备份路径文件名] [数据库名]   还原
    示例:

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



# 备份
F_BACKUP()
{
    FV_BACKUP_TO_PATH_FILENAME=$1
    FV_DB_NAME=$2
    # 备份文件名是否合法
    if ! [[ ${FV_BACKUP_TO_PATH_FILENAME} =~ .*[a-zA-Z0-9]+$ ]]; then
        echo -e "\n猪猪侠警告：备份文件名不合法，必须符合 .*[a-zA-Z0-9]+$ 正则要求，请检查\n"
        exit 1
    fi
    # 目录权限检查
    TEMP_DIR=${FV_BACKUP_TO_PATH_FILENAME%/*}
    if [ -d "${TEMP_DIR}" ]; then
        touch ${TEMP_DIR}/test_write >/dev/null 2>&1
        if [ $? != 0 ]; then
            echo -e "\n猪猪侠警告：目录${TEMP_DIR}写入测试失败，请检查\n"
            return 1
        fi
        rm -f ${TEMP_DIR}/test_write
    else
        echo -e "\n猪猪侠警告：目录${TEMP_DIR}不存在，请检查\n"
        return 1
    fi
    # 数据库是否存在
    ${PGSQL_CMD_BASE}/psql  -c '\l' | cut -d \| -f 1 | sed -e '1,3d' -e '/rows)/d' | sed -e '/template/d' -e '/postgres/d' | sed -e '/^\s*$/d' -e 's/[ \t]*//g' >/tmp/pg_db.list
    grep "^${FV_DB_NAME}$" /tmp/pg_db.list
    if [ $? != 0 ]; then
        echo -e "\n猪猪侠警告：数据库${FV_DB_NAME}没找到，备份个锤子\n"
        return 1
    fi
    # backup
    ${PGSQL_CMD_BASE}/pg_dump ${FV_DB_NAME} | gzip > ${FV_BACKUP_TO_PATH_FILENAME}.gz
    if [ $? = 0 ]; then
        return 0
    else
        return 1
    fi
}



# 恢复
F_RESTORE()
{
    # arg
    FV_BACKUP_FILE=$1
    FV_DB_NAME=$2
    # 文件检查
    if [ ! -f "${FV_BACKUP_FILE}" ]; then
        echo -e "\n猪猪侠警告：文件${FV_BACKUP_FILE}不存在或无权限，请检查\n"
        return 1
    fi
    # 数据库是否存在
    ${PGSQL_CMD_BASE}/psql  -c '\l' | cut -d \| -f 1 | sed -e '1,3d' -e '/rows)/d' | sed -e '/template/d' -e '/postgres/d' | sed -e '/^\s*$/d' -e 's/[ \t]*//g' >/tmp/pg_db.list
    grep "^${FV_DB_NAME}$" /tmp/pg_db.list
    if [ $? = 0 ]; then
        # 存在
        dropdb ${FV_DB_NAME}
        sleep 3
    else
        # 不存在
        read -p "猪猪侠警告：在执行数据库删除时，没有找到数据库${FV_DB_NAME}，要继续还原此数据库吗？(Y|N)："  KEY
        if [ "x${KEY}" != 'xY' ]; then
            echo -e "\n好的，我已退出程序 ($0)\n"
            return 1
        fi
    fi
    # restore
    createdb ${FV_DB_NAME}
    gunzip -c ${FV_BACKUP_FILE} | psql ${FV_DB_NAME}
    if [ $? = 0 ]; then
        return 0
    else
        return 1
    fi
}




# 参数检查
TEMP=`getopt -o hb:r:  -l help,backup:,restore: -- "$@"`

if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 1
fi

eval set -- "${TEMP}"


while true
do
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -b|--backup)
            BACKUP_TO_PATH_FILENAME="$2"
            shift 2
            DB_NAME="$2"
            if [ -z ${DB_NAME} ]; then
                echo -e "\n猪猪侠警告：参数错误，数据库名不能为空\n"
                exit 1
            fi
            #
            F_BACKUP ${BACKUP_TO_PATH_FILENAME} ${DB_NAME}
            if [ $? = 0 ]; then
                echo -e "\n猪猪侠警告：数据库${DB_NAME}备份成功，备份文件为${BACKUP_TO_PATH_FILENAME}.gz\n"
                # send msg
                TIME_END=`date +%Y-%m-%dT%H:%M:%S`
                TIME_COST=`F_TimeDiff "${TIME_START}" "${TIME_END}"`
                ${DINGDING_MARKDOWN_PY}  "【Info:PG备份:${RUN_ENV}】"  "数据库${DB_NAME}备份成功！ ${TIME_COST}"
                exit
            else
                echo -e "\n猪猪侠警告：数据库${DB_NAME}备份失败\n"
                # send msg
                TIME_END=`date +%Y-%m-%dT%H:%M:%S`
                TIME_COST=`F_TimeDiff "${TIME_START}" "${TIME_END}"`
                ${DINGDING_MARKDOWN_PY}  "【Info:PG备份:${RUN_ENV}】"  "数据库${DB_NAME}备份失败！ ${TIME_COST}"
                exit 1
            fi
            ;;
        -r|--restore)
            BACKUP_FILE=$2
            shift 2
            DB_NAME=$2
            if [ -z ${DB_NAME} ]; then
                echo -e "\n猪猪侠警告：参数错误，数据库名不能为空\n"
                exit 1
            fi
            echo "正在进行数据库还原......"
            #
            F_RESTORE ${BACKUP_FILE} ${DB_NAME}
            if [ $? = 0 ]; then
                echo -e "\n猪猪侠警告：数据库${DB_NAME}还原成功\n"
                # send msg
                TIME_END=`date +%Y-%m-%dT%H:%M:%S`
                TIME_COST=`F_TimeDiff "${TIME_START}" "${TIME_END}"`
                ${DINGDING_MARKDOWN_PY}  "【Info:PG还原:${RUN_ENV}】"  "数据库${DB_NAME}还原成功！ ${TIME_COST}"
                exit
            else
                echo -e "\n猪猪侠警告：数据库${DB_NAME}还原失败\n"
                # send msg
                TIME_END=`date +%Y-%m-%dT%H:%M:%S`
                TIME_COST=`F_TimeDiff "${TIME_START}" "${TIME_END}"`
                ${DINGDING_MARKDOWN_PY}  "【Info:PG还原:${RUN_ENV}】"  "数据库${DB_NAME}还原失败！ ${TIME_COST}"
                exit 1
            fi
            ;;
        --)
            shift
            break
            ;;
        *)
            echo -e "\n猪猪侠警告：未知参数，请查看帮助【$0 --help】\n"
            exit 1
            ;;
    esac
done



