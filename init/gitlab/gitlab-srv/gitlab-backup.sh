#!/bin/bash


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}


# 引入env
.  ./gitlab-backup.sh.env


# env
YEAR=`date +%Y`
TIME_START=`date +%Y-%m-%dT%H:%M:%S`
DINGDING_MARKDOWN_PY='/usr/local/bin/dingding_conver_to_markdown_list.py'



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


echo '#######################################################'
date
echo '#######################################################'


# backup
${BACKUP_CMD}
if [ $? != 0 ]; then
    echo  "gitlab备份：gitlab:backup:create备份出错，请检查！"
    ${DINGDING_MARKDOWN_PY}  "【Error:备份:gitlab】" "gitlab备份：gitlab:backup:create备份出错，请检查！"
    exit 1
fi
FILE_NAME=$(ls ${BACKUP_DIR} | grep "`date +%Y_%m_%d`" | sed -n '$p')


# 检查oss
df -h | grep ossfs > /dev/null 2>&1
if [ $? != 0 ]; then
    echo "gitlab备份：ossfs没有挂载，请检查！"
    ${DINGDING_MARKDOWN_PY}  "【Error:备份:gitlab】"  "gitlab备份：ossfs没有挂载，请检查！"
    exit
fi


# 准备目录
[ -d ${BACKUP_REMOTE_DIR}/${YEAR} ] || mkdir -p ${BACKUP_REMOTE_DIR}/${YEAR}


# cp
echo "正在执行：cp ${BACKUP_DIR}/${FILE_NAME} ${BACKUP_REMOTE_DIR}/${YEAR}/"
echo "`date` ，请等待........"
cp ${BACKUP_DIR}/${FILE_NAME} ${BACKUP_REMOTE_DIR}/${YEAR}/
if [ $? != 0 ]; then
    echo "gitlab备份：备份文件拷贝到ossfs不成功，请检查！"
    ${DINGDING_MARKDOWN_PY}  "【Error:备份:gitlab】"  "gitlab备份：备份文件拷贝到ossfs不成功，请检查！"
    exit
fi
echo "`date` ，OK"



TIME_END=`date +%Y-%m-%dT%H:%M:%S`
TIME_COST=`F_TimeDiff "${TIME_START}" "${TIME_END}"`

# 每周一发通知
if [ `date +%w` = 1 ]; then
    ${DINGDING_MARKDOWN_PY}  "【Info:备份:gitlab】"  "gitlab备份：成功！ ${TIME_COST}"
fi


