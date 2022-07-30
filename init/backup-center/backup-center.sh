#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7


SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}
SRC_BASE_PATH=/oss/backup
DEST_BASE_PATH=/zjlh/d3/sz_bakup_center
ARCHIVE_SUB_DIR='archives'
PROJECT_LIST_FILE="${SH_PATH}/backup-center-project.list"
PROJECT_NAME=''
FILE_NAME=''
YEAR=`date +%Y`
DATETIME=`date +%Y%m%dT%H%M`
TIME_START=`date +%Y-%m-%dT%H:%M:%S`
# 删除空行（以及只有tab、空格的行）
sed -i '/^\s*$/d'  ${PROJECT_LIST_FILE}



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




while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    PROJECT_NAME=`echo ${LINE} | cut -d \| -f 2`
    PROJECT_NAME=`echo ${PROJECT_NAME}`

    # 源目录
    if [ ! -d "${SRC_BASE_PATH}/${PROJECT_NAME}/${YEAR}" ]; then
        echo "项目路径不存在：${SRC_BASE_PATH}/${PROJECT_NAME}/${YEAR}，请检查！继续下一个。"
        /usr/local/bin/dingding_conver_to_markdown_list.py  "【Error:备份中心:${PROJECT_NAME}】"  "项目路径不存在：${SRC_BASE_PATH}/${PROJECT_NAME}/${YEAR}，请检查！继续下一个。"
        continue
    fi
    # 源文件
    FILE_NAME=''
    ## 获取文件名类似: *20190909T0*
    FILE_NAME=$(ls ${SRC_BASE_PATH}/${PROJECT_NAME}/${YEAR} | grep "`date +%Y%m%d`T0" | head -n 1)
    ## 获取文件名类似: *2019_09_09*
    if [ x${FILE_NAME} = 'x' ]; then
        FILE_NAME=$(ls ${SRC_BASE_PATH}/${PROJECT_NAME}/${YEAR} | grep "`date +%Y_%m_%d`" | head -n 1)
    fi
    ## 空则跳过
    if [ x${FILE_NAME} = 'x' ]; then
        echo  "没有找到${PROJECT_NAME}今日的备份文件，请检查！继续下一个。"
        /usr/local/bin/dingding_conver_to_markdown_list.py  "【Error:备份中心:${PROJECT_NAME}】"  "没有找到${PROJECT_NAME}今日的备份文件，请检查！继续下一个。"
        continue
    fi
    # 目标路径
    [ -d ${DEST_BASE_PATH}/${PROJECT_NAME}/${YEAR} ] || mkdir -p ${DEST_BASE_PATH}/${PROJECT_NAME}/${YEAR}
    [ -d ${DEST_BASE_PATH}/${PROJECT_NAME}/${ARCHIVE_SUB_DIR} ] || mkdir -p ${DEST_BASE_PATH}/${PROJECT_NAME}/${ARCHIVE_SUB_DIR}

    # cp 每月 1日或不是
    if [ `date +%d` = '01' ]; then
        cp -r ${SRC_BASE_PATH}/${PROJECT_NAME}/${YEAR}/${FILE_NAME}  ${DEST_BASE_PATH}/${PROJECT_NAME}/${ARCHIVE_SUB_DIR}/
        if [ $? != 0 ]; then
            echo  "${PROJECT_NAME}备份失败，请检查！继续下一个。"
            /usr/local/bin/dingding_conver_to_markdown_list.py  "【Error:备份中心:${PROJECT_NAME}】"  "${PROJECT_NAME}备份失败，请检查！继续下一个。"
            continue
        fi
    else
        cp -r ${SRC_BASE_PATH}/${PROJECT_NAME}/${YEAR}/${FILE_NAME}  ${DEST_BASE_PATH}/${PROJECT_NAME}/${YEAR}/
        if [ $? != 0 ]; then
            echo  "${PROJECT_NAME}备份失败，请检查！继续下一个。"
            /usr/local/bin/dingding_conver_to_markdown_list.py  "【Error:备份中心:${PROJECT_NAME}】"  "${PROJECT_NAME}备份失败，请检查！继续下一个。"
            continue
        fi
    fi
done < ${PROJECT_LIST_FILE}


TIME_END=`date +%Y-%m-%dT%H:%M:%S`
TIME_COST=`F_TimeDiff "${TIME_START}" "${TIME_END}"`


# 每周一发通知
if [ `date +%w` = 1 ]; then
    /usr/local/bin/dingding_conver_to_markdown_list.py  "【Info:备份中心:SZ】"  "所有备份已完成，请检查是否全部成功！ ${TIME_COST}"
fi


# 每月1号发通知
if [ `date +%d` = '01' ]; then
    /usr/local/bin/dingding_conver_to_markdown_list.py  "【Info:备份中心:SZ】"  "月度备份归档已完成，请检查是否全部成功！ ${TIME_COST}"
fi




