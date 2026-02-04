#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# 指定用户下运行
if [ ${USER} != 'root' ]; then
    echo '请在root用户下运行！'
    exit 1
fi

# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}" || { echo -e "\n猪猪侠警告：这个错误是不可能的，这里是为了规避语法警告！\n" ; exit 53 ; }

# 引入env

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}

# sh
POSTGRESQL_DAEMON_SH="/root/postgresql_daemon.sh"
PG_BACKUP_OR_RESTORE_BY_USER_POSTGRES_SH="${SH_PATH}/pg_backup_or_restore_by_user_postgres.sh"

# 用法：
F_HELP()
{
    echo "
    用途：用于pg数据库备份or还原，一次仅处理一个数据库。
    依赖：
        ${POSTGRESQL_DAEMON_SH}
        ${PG_BACKUP_OR_RESTORE_BY_USER_POSTGRES_SH}
    注意：需在root账户下运行，会自动设置访问限制、删库、创建、导入、取消限制。
    用法:
        $0  -h|--help
        $0  -b|--backup   <PATH/TO/FILENAME>  <数据库名>     #--- 备份，文件格式为gzip，备份时会自动在指定的名字后面自动加上.gz
        $0  -r|--resotore <PATH/TO/FILENAME>  <数据库名>     #--- 恢复，文件须为gzip格式
    参数规范：
        无包围符号 ：-a                : 必选【选项】
                   ：val               : 必选【参数值】
                   ：val1 val2 -a -b   : 必选【选项或参数值】，且不分先后顺序
        []         ：[-a]              : 可选【选项】
                   ：[val]             : 可选【参数值】
        <>         ：<val>             : 需替换的具体值（用户必须提供）
        %%         ：%val%             : 通配符（包含匹配，如%error%匹配error_code）
        |          ：val1|val2|<valn>  : 多选一
        {}         ：{-a <val>}        : 必须成组出现【选项+参数值】
                   ：{val1 val2}       : 必须成组的【参数值组合】，且必须按顺序提供
    参数说明：
        #
        -b|--backup      备份
        -r|--resotore    还原
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




# 参数检查
TEMP=`getopt -o hb:r:  -l help,backup:,restore: -- "$@"`

if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 1
fi
#
eval set -- "${TEMP}"


while true
do
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -b|--backup)
            BACKUP_TO_PATH_AND_FILENAME="$2"
            shift 2
            shift 1
            DB_NAME="$1"
            if [ -z ${DB_NAME} ]; then
                echo -e "\n猪猪侠警告：参数错误，数据库名不能为空\n"
                exit 1
            fi
            #
            echo "${DB_NAME}："
            su - postgres -c  "cd ${SH_PATH} && bash  ${PG_BACKUP_OR_RESTORE_BY_USER_POSTGRES_SH}  --backup ${BACKUP_TO_PATH_AND_FILENAME} ${DB_NAME}"
            exit
            ;;
        -r|--restore)
            BACKUP_FILE=$2
            shift 2
            shift 1
            DB_NAME=$1
            if [ -z ${DB_NAME} ]; then
                echo -e "\n猪猪侠警告：参数错误，数据库名不能为空\n"
                exit 1
            fi
            #
            echo "正在关闭外部访问权限......"
            # dis_hba
            su - postgres -c  "sed -i '/^host.*0\.0\.0\.0.*/s/^/#/g'  /usr/local/pgsql/data/pg_hba.conf"
            ${POSTGRESQL_DAEMON_SH}  stop
            sleep 5
            ${POSTGRESQL_DAEMON_SH}  start
            sleep 5
            #
            su - postgres -c  "cd ${SH_PATH} && bash  ${PG_BACKUP_OR_RESTORE_BY_USER_POSTGRES_SH}  --restore ${BACKUP_FILE} ${DB_NAME}"
            echo -e "正在开启外部访问权限，重启中......"
            # en_hba
            su - postgres -c  "sed -i '/^#host.*0\.0\.0\.0.*/s/#//g'  /usr/local/pgsql/data/pg_hba.conf"
            ${POSTGRESQL_DAEMON_SH}  stop
            sleep 3
            ${POSTGRESQL_DAEMON_SH}  start
            sleep 10
            echo -e "PG重启完成\n"
            exit
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

