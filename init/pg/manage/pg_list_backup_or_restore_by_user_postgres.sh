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
# 自动从/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh引入以下变量
. /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh      #--- 计划任务中运行时，须source引入
#RUN_ENV=

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}
DATETIME=`date +%Y%m%dT%H%M`
## 默认：
BAKCUP_NAME="pufi"
BAKCUP_DIRNAME="${BAKCUP_NAME}-${DATETIME}"
BACKUP_PATH_DIR='./bak'
YEAR=`date +%Y`
COPY_TO_PATH_SURE="no"
COPY_TO_PATH="/oss/backup/pg-${BAKCUP_NAME}/${YEAR}"
SEARCH_PATH="/oss/backup/pg-${BAKCUP_NAME}/${YEAR}"
SEARCH_NAME=""

# sh
PGSQL_CMD_BASE='/usr/local/pgsql/bin'
PG_DB_LIST="pg_db.list"
DINGDING_SEND_LIST_SH="/usr/local/bin/dingding_conver_to_markdown_list.sh"




# 用法：
F_HELP ()
{
    echo "
    用途：用于pg数据库备份or还原，仅备份或恢复${PG_DB_LIST}中的数据库。
    依赖：
        /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
        ${PG_DB_LIST}
        ${DINGDING_SEND_SH}
    注意：需在root账户下运行，在还原时会自动设置访问限制、删库、创建、导入、取消限制。
    用法：
        $0  [-h|--help]
        $0  [-b|--backup]   <-d|--path-dir {备份目录路径}>   <-c<{目标路径}>|--copy-to-path=<{目标路径}>>   #--- 特别注意-c参数用法
        $0  [-r|--resotore] [-d|--path-dir {备份目录路径}]
        $0  [-s|--search]   <-p|--search-path {搜索父目录}>  <-n|--search-name {搜索子目录名}>
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



# 备份
F_BACKUP()
{
    FV_BACKUP_PATH_DIR=$1
    # 目录检查
    if [ -e ${FV_BACKUP_PATH_DIR} ]; then
        echo "猪猪侠警告：【${FV_BACKUP_PATH_DIR}】备份目录已存在，能不能换个名字先！"
        return 1
    fi
    # 新建目录
    mkdir -p ${FV_BACKUP_PATH_DIR}
    if [[ $? -ne 0 ]]; then
        echo "猪猪侠警告：【${FV_BACKUP_PATH_DIR}】目录新建失败，请检查！"
        return 2
    fi
    #
    # ./${PG_DB_LIST}
    # 删除空行（以及只有tab、空格的行）
    sed -i '/^\s*$/d'  ${PG_DB_LIST}
    # 删除行中的空格
    sed -i 's/[ \t]*//g' ${PG_DB_LIST}
    # 也可以直接生成db列表 - 排除系统数据库及其他噪音
    #${PGSQL_CMD_BASE}/pgsql  -c "\l" | cut -d \| -f 1 | sed -e '1,3d' -e '/rows)/d' | sed -e '/template/d' -e '/postgres/d' | sed -e '/^\s*$/d' -e 's/[ \t]*//g'  > ${PG_DB_LIST}
    #
    # backup
    for DB in `cat ${PG_DB_LIST}`
    do
        # 跳过以#开头的行或空行
        [[ "$DB" =~ ^# ]] || [[ "$DB" =~ ^[\ ]*$ ]] && continue
        #
        echo "${DB} :"
        ${PGSQL_CMD_BASE}/pg_dump ${DB} | gzip > ${FV_BACKUP_PATH_DIR}/${DB}.gz
        if [ $? != 0 ]; then
            echo  "猪猪侠警告：备份数据库 ${DB} 时出错，请检查！继续下一个。"
            ${DINGDING_SEND_SH}  "【Err:pg-${BAKCUP_NAME}备份:${RUN_ENV}】" "备份数据库 ${DB} 时出错，请检查！继续下一个。"
        fi
    done
    #
    cp ${PG_DB_LIST} ${FV_BACKUP_PATH_DIR}/
    #
    echo -e "\nOK,备份最终路径为：${FV_BACKUP_PATH_DIR}\n"
    return 0
}



# 恢复
F_RESTORE()
{
    # arg
    FV_BACKUP_PATH_DIR=$1
    # 目录检查
    if [ ! -d ${FV_BACKUP_PATH_DIR} ]; then
        echo -e "\n猪猪侠警告：还原之备份目录【${FV_BACKUP_PATH_DIR}】不存在或无权限，请检查\n"
        return 1
    fi
    # ${PG_DB_LIST}检查
    if [ ! -f ${FV_BACKUP_PATH_DIR}/${PG_DB_LIST} ]; then
        echo -e "\n猪猪侠警告：还原之备份目录【${FV_BACKUP_PATH_DIR}】中没有${PG_DB_LIST}文件，请检查\n"
        return 2
    fi
    # 还原
    date
    echo -e "\n开始进行数据库还原......"
    for DB in `cat ${FV_BACKUP_PATH_DIR}/${PG_DB_LIST}`
    do
        # 跳过以#开头的行或空行
        [[ "$DB" =~ ^# ]] || [[ "$DB" =~ ^[\ ]*$ ]] && continue
        #
        echo "${DB} :"
        if [ ! -f "${FV_BACKUP_PATH_DIR}/${DB}.gz" ]; then
            echo -e "\n猪猪侠警告：备份文件【${FV_BACKUP_PATH_DIR}/${DB}.gz】不存在\n"
            ${DINGDING_SEND_SH}  "【Err:pg-${BAKCUP_NAME}还原:${RUN_ENV}】" "数据库备份文件不存在（${FV_BACKUP_PATH_DIR}/${DB}.gz），已退出，请检查！"
            return 3
        fi
        #
        dropdb   ${DB}
        sleep 3
        #
        createdb ${DB}
        gunzip -c ${FV_BACKUP_PATH_DIR}/${DB}.gz | psql ${DB}
        if [ $? != 0 ]; then
            ${DINGDING_SEND_SH}  "【Err:pg-${BAKCUP_NAME}还原:${RUN_ENV}】" "数据库 ${DB} 还原失败，已退出，请检查！"
            return 4
        fi
    done
    #
    echo -e "\nOK，数据库还原自：${FV_BACKUP_PATH_DIR}\n"
    return 0
}


F_COPY_TO ()
{
    FV_BACKUP_PATH_DIR=$1
    FV_COPY_TO_PATH=$2
    # 拷贝
    cp -r  ${FV_BACKUP_PATH_DIR}  ${FV_COPY_TO_PATH}
    if [[ $? -eq 0 ]]; then
        echo -e "\nOK,备份拷贝副本路径为：${FV_COPY_TO_PATH}\n"
        return 0
    else
        echo -e "\n猪猪侠警告：备份拷贝到副本路径时出错，请检查！\n"
        ${DINGDING_SEND_SH}  "【Err:pg-${BAKCUP_NAME}备份:${RUN_ENV}】"   "备份拷贝到副本路径时出错，请检查！"
        return 1
    fi
    #
}


F_SEARCH ()
{
    FV_SEARCH_PATH=$1
    FV_SEARCH_NAME=$2
    if [[ -n ${FV_SEARCH_NAME} ]]; then
        echo -e "\n搜索结果如下："
        echo "--------------------------------------------------"
        find  ${FV_SEARCH_PATH}  -maxdepth 1  -name "*${FV_SEARCH_NAME}*"
    else
        echo -e "\n搜索之最新备份为："
        echo "--------------------------------------------------"
        FV_R=`ls -lt --time-style=full-iso ${FV_SEARCH_PATH} | sed '1d' | head -n 1 | awk '{print $9}'`
        echo "${FV_SEARCH_PATH}/${FV_R}"
    fi
    echo ""
    return 0
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
            BACKUP_PATH_DIR="${BACKUP_PATH_DIR}/${BAKCUP_DIRNAME}"
            F_BACKUP  ${BACKUP_PATH_DIR}
            if [[ $? -eq 0 ]]; then
                # 拷贝到副本路径
                if [[ ${COPY_TO_PATH_SURE} == "yes" ]]; then
                    F_COPY_TO  ${BACKUP_PATH_DIR}  ${COPY_TO_PATH}
                fi
                # send msg
                TIME_END=`date +%Y-%m-%dT%H:%M:%S`
                TIME_COST=`F_TimeDiff "${TIME_START}" "${TIME_END}"`
                # 每周一发通知
                if [ `date +%w` = 1 ]; then
                    ${DINGDING_SEND_SH}  "【Info:pg-${BAKCUP_NAME}备份:${RUN_ENV}】"  "数据库备份任务完成！ ${TIME_COST}"
                fi
            else
                ${DINGDING_SEND_SH}  "【Err:pg-${BAKCUP_NAME}备份:${RUN_ENV}】"   "数据库备份任务失败，请检查！"
            fi
            exit
            ;;
        -r|--restore)
            # 必须包含参数：-d|--path-dir
            echo ${SH_ARGS[@]} | grep '\-d' >/dev/null 2>&1
            R1=$?
            echo ${SH_ARGS[@]} | grep '\-\-path\-dir' >/dev/null 2>&1
            R2=$?
            if [[ ${R1} -ne 0 && ${R2} -ne 0 ]]; then
                echo -e "\n猪猪侠警告：必须使用【-d|--path-dir】参数，请查看帮助！\n"
                exit 1
            fi
            # 如果是生产环境
            if [ "x${RUN_ENV}" = "xprod" ]; then
                read -p "猪猪侠警告：当前是生产环境（prod），你确定要还原吗[YES|NO]：" G
                if [[ "x${G}" != 'xYES' ]]; then
                    echo "好的，我已退出！"
                    exit
                fi
            fi
            #
            read -p "你将要从【${BACKUP_PATH_DIR}】还原数据库，你确定吗[yes|no]：" G2
            if [ "x${G2}" != 'xyes' ]; then
                echo "好的，我退出！"
                exit
            fi
            #
            ${DINGDING_SEND_SH}  "【Info:pg-${BAKCUP_NAME}还原:${RUN_ENV}】"   "我要开始还原数据库啦！skr skr skr"
            #
            F_RESTORE ${BACKUP_PATH_DIR}
            if [[ $? -eq 0 ]]; then
                # send msg
                TIME_END=`date +%Y-%m-%dT%H:%M:%S`
                TIME_COST=`F_TimeDiff "${TIME_START}" "${TIME_END}"`
                ${DINGDING_SEND_SH}  "【Info:pg-${BAKCUP_NAME}还原:${RUN_ENV}】"  "数据库还原任务完成！ ${TIME_COST}"
            else
                ${DINGDING_SEND_SH}  "【Err:pg-${BAKCUP_NAME}还原:${RUN_ENV}】"   "数据库还原任务失败，请检查！"
            fi
            exit
            ;;
        -s|--search)
            # 仅搜索当前目录
            F_SEARCH ${SEARCH_PATH} ${SEARCH_NAME}
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


