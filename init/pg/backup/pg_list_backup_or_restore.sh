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
cd ${SH_PATH}

# 引入env

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
## 默认：
BAKCUP_NAME="pufi"
BACKUP_PATH_DIR='./bak'
YEAR=`date +%Y`
COPY_TO_PATH_SURE="no"
COPY_TO_PATH="/oss/backup/pg-${BAKCUP_NAME}/${YEAR}"
SEARCH_PATH="/oss/backup/pg-${BAKCUP_NAME}/${YEAR}"
SEARCH_NAME=""

# sh
POSTGRESQL_DAEMON_SH="/root/postgresql_daemon.sh"
PG_LIST_BACKUP_OR_RESTORE_BY_USER_POSTGRES_SH="${SH_PATH}/pg_list_backup_or_restore_by_user_postgres.sh"



# 用法：
F_HELP ()
{
    echo "
    用途：用于pg数据库备份or还原，仅备份或恢复pg_db.list中的数据库。
    依赖：
        ${POSTGRESQL_DAEMON_SH}
        ${PG_LIST_BACKUP_OR_RESTORE_BY_USER_POSTGRES_SH}
    注意：需在root账户下运行，在还原时会自动设置访问限制、删库、创建、导入、取消限制。
    用法：
        $0 [-h|--help]
        $0 [-b|--backup]   <-d|--path-dir 备份目录路径>   <-c<目标路径>|--copy-to-path=<目标路径>>   #--- 特别注意-c参数用法
        $0 [-r|--resotore] [-d|--path-dir 备份目录路径]
        $0 [-s|--search]   <-p|--search-path 搜索父目录>  <-n|--search-name 搜索子目录名>
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        #
        -b|--backup          备份
        -r|--resotore        还原
        -s|--search          搜索备份，用来帮助选择用以还原的备份
        -d|--path-dir        目录，可以是相对或绝对路径。在备份时，目标目录必须是不存在的或者是空的，且可写，默认路径为./bak；在还原时，必须是已存在的，可读
        -c|--copy-to-path    拷贝副本到新路径，默认为/oss/backup/pg-${BAKCUP_NAME}/\${YEAR}
        -p|--search-path     指定搜索路径，可以是相对或绝对路径，默认为/oss/backup/pg-${BAKCUP_NAME}/\${YEAR}
        -n|--search-name     指定搜索子目录名，支持模糊搜索，默认为修改日期最新的那个
    示例:
        # 备份：
        $0  -b                          #--- 备份到默认目录
        $0  -b  -c./aa/bbb              #--- 备份到默认目录，并拷贝副本到./aa/bbb目录下
        $0  -b  -d ./xxx                #--- 备份到./xxx目录下
        $0  -b  -d ./xxx -c./aa/bbb     #--- 备份到./xxx目录下，并拷贝副本到./aa/bbb目录下
        # 还原：
        $0  -r  -d ./xxx/nnn            #--- 从./xxx/nnn还原数据库
        # 搜索：
        $0  -s                          #--- 在默认位置搜索最新的备份
        $0  -s  -n nnn                  #--- 在默认位置搜索名字为nnn的备份
        $0  -s  -p ./aaa/bbb            #--- 在./aaa/bbb目录下搜索最新备份
        $0  -s  -p ./aaa/bbb  -n nnn    #--- 在./aaa/bbb目录下搜索名字为*nnn*的备份
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
TEMP=`getopt -o hbrsd:c::p:n:  -l help,backup,restore,search,path-dir:,copy-to-path::,search-path:,search-name: -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 1
fi
#
eval set -- "${TEMP}"

# 参数个数为0
if [[ $# -eq 0 ]]; then
    echo -e "\n猪猪侠警告：缺少必要运行参数\n"
    exit 1
fi

# start
# 获取次要命令参数
SH_ARGS_NUM=$#
SH_ARGS[0]="占位"
for ((i=1;i<=SH_ARGS_NUM;i++)); do
    eval K=\${${i}}
    SH_ARGS[${i}]=${K}
    #echo 调试：   SH_ARGS数组${i}列的值是: ${SH_ARGS[${i}]}
done
#
SH_ARGS_ARR_NUM=${#SH_ARGS[@]}
for ((i=1;i<SH_ARGS_ARR_NUM;i++))
do
    case ${SH_ARGS[$i]} in
        -h|--help)
            F_HELP
            exit
            ;;
        -d|--path-dir)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            BACKUP_PATH_DIR="${J:-${BACKUP_PATH_DIR}}"
            # 删除行尾的'/'
            BACKUP_PATH_DIR=${BACKUP_PATH_DIR%*/}
            ;;
        -c|--copy-to-path)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            COPY_TO_PATH=${J:-${COPY_TO_PATH}}
            # 删除行尾的'/'
            COPY_TO_PATH=${COPY_TO_PATH%*/}
            COPY_TO_PATH_SURE="yes"
            ;;
        -p|--search-path)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            SEARCH_PATH=${J:-${SEARCH_PATH}}
            # 删除行尾的'/'
            SEARCH_PATH=${SEARCH_PATH%*/}
            ;;
        -n|--search-name)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            SEARCH_NAME=${J}
            ;;
        --)
            break
            ;;
        *)
            # 跳过
            ;;
    esac
done


# 获取主要参数，运行
while true
do
    #
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -d|--path-dir|-c|--copy-to-path|-p|--search-path|-n|--search-name)
            # 前面已处理，跳过
            shift 2
            ;;
        -b|--backup)
            if [[ ${COPY_TO_PATH_SURE} == "yes" ]]; then
                su - postgres -c  "cd ${SH_PATH} && bash ${PG_LIST_BACKUP_OR_RESTORE_BY_USER_POSTGRES_SH} --backup --path-dir ${BACKUP_PATH_DIR} --copy-to-path=${COPY_TO_PATH}"
            else
                su - postgres -c  "cd ${SH_PATH} && bash ${PG_LIST_BACKUP_OR_RESTORE_BY_USER_POSTGRES_SH} --backup --path-dir ${BACKUP_PATH_DIR}"
            fi
            exit
            ;;
        -r|--restore)
            # 必须包含参数：-d|--path-dir
            echo -e "\n${SH_ARGS[@]}\n"
            echo ${SH_ARGS[@]} | grep '\-d' >/dev/null 2>&1
            R1=$?
            echo ${SH_ARGS[@]} | grep '\-\-path\-dir' >/dev/null 2>&1
            R2=$?
            if [[ ${R1} -ne 0 && ${R2} -ne 0 ]]; then
                echo -e "猪猪侠警告：必须使用【-d|--path-dir】参数，请查看帮助！"
                exit 1
            fi
            #
            echo "正在关闭PG外部访问权限......"
            # dis_hba
            su - postgres -c  "sed -i '/^host.*0\.0\.0\.0.*/s/^/#/g'  /usr/local/pgsql/data/pg_hba.conf"
            /root/postgresql_daemon.sh stop
            sleep 10
            /root/postgresql_daemon.sh start
            sleep 5
            #
            su - postgres -c  "cd ${SH_PATH} && bash ${PG_LIST_BACKUP_OR_RESTORE_BY_USER_POSTGRES_SH} --restore --path-dir ${BACKUP_PATH_DIR}"
            echo -e "正在开启PG外部访问权限，重启中......"
            # en_hba
            su - postgres -c  "sed -i '/^#host.*0\.0\.0\.0.*/s/#//g'  /usr/local/pgsql/data/pg_hba.conf"
            /root/postgresql_daemon.sh stop
            sleep 5
            /root/postgresql_daemon.sh start
            sleep 10
            echo -e "PG服务重启完成\n"
            exit
            ;;
        -s|--search)
            #
            if [[ -n ${SEARCH_NAME} ]]; then
                su - postgres -c  "cd ${SH_PATH} && bash ${PG_LIST_BACKUP_OR_RESTORE_BY_USER_POSTGRES_SH} --search --search-path ${SEARCH_PATH}  --search-name ${SEARCH_NAME}"
            else
                su - postgres -c  "cd ${SH_PATH} && bash ${PG_LIST_BACKUP_OR_RESTORE_BY_USER_POSTGRES_SH} --search --search-path ${SEARCH_PATH}"
            fi
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



