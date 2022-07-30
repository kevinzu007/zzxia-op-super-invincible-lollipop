#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7


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
#
DOCKER_IMAGES_FILE='/tmp/docker_images.list'
DOCKER_IMAGES_FILE_FORMAT='/tmp/docker_images_format.list'
DOCKER_IMAGES_FILE_DEL='/tmp/docker_images_format_del.list'
# docker镜像清单格式化
docker image prune -f > /dev/null   #--- 删除tag为none的镜像
docker image ls > ${DOCKER_IMAGES_FILE}
> ${DOCKER_IMAGES_FILE_FORMAT}
#
cat ${DOCKER_IMAGES_FILE} | awk 'BEGIN{FS=" "} {if($5 ~ /days/)   {printf "%s  %s  %s  %d  %s\n", $1,$2,$3,$4*7,  $7}}' >> ${DOCKER_IMAGES_FILE_FORMAT}
cat ${DOCKER_IMAGES_FILE} | awk 'BEGIN{FS=" "} {if($5 ~ /weeks/)  {printf "%s  %s  %s  %d  %s\n", $1,$2,$3,$4*7,  $7}}' >> ${DOCKER_IMAGES_FILE_FORMAT}
cat ${DOCKER_IMAGES_FILE} | awk 'BEGIN{FS=" "} {if($5 ~ /months/) {printf "%s  %s  %s  %d  %s\n", $1,$2,$3,$4*30, $7}}' >> ${DOCKER_IMAGES_FILE_FORMAT}
cat ${DOCKER_IMAGES_FILE} | awk 'BEGIN{FS=" "} {if($5 ~ /years/)  {printf "%s  %s  %s  %d  %s\n", $1,$2,$3,$4*365,$7}}' >> ${DOCKER_IMAGES_FILE_FORMAT}



# 帮助
F_HELP()
{
    echo "
    用途：删除旧docker镜像
    依赖：
    注意：
        * 输入命令时，参数顺序不分先后
    用法：
        $0 [-h|--help]
        $0 <-q|--quiet>  [ <-k|--keyword {关键字}>  <-t|--tag {镜像tag}>  <-d|--days {天数}> ]
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        #
        -h|--help              此帮助
        -q|--quiet             静默方式
        -k|--keyword {关键字}  指定镜像名称关键字
        -t|--tag {镜像tag}     指定镜像tag名称，比如：none、latest等
        -d|--days {N}          指定天数
    示例：
        $0 -k gcl              #--- 删除镜像名称中包含字符【gcl】的所有镜像
        $0 -q -k gcl           #--- 删除镜像名称中包含字符【gcl】的所有镜像，静默方式
        $0 -t none             #--- 删除tag为【none】的所有镜像
        $0 -d 10               #--- 删除10天数之前所有镜像
        $0 -k gcl -d 10             #--- 删除镜像名称中包含字符【gcl】，且为10天之前的有镜像
        $0 -k gcl -t latest         #--- 删除镜像名称中包含字符【gcl】，且镜像tag为【latest】的镜像
        $0 -d 10 -t latest          #--- 删除10天数之前，且镜像tag为【latest】的镜像
        $0 -k gcl -d 10 -t latest   #--- 删除镜像名称中包含字符【gcl】，且为10天之前，且镜像tag为【latest】的镜像
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



F_find_keyword()
{
    F_KEYWORD="$1"
    cat ${DOCKER_IMAGES_FILE_FORMAT} | awk '{if($1 ~ "'"${F_KEYWORD}"'") {printf "%s\n" ,$0}}' > ${DOCKER_IMAGES_FILE_DEL}
    cat ${DOCKER_IMAGES_FILE_DEL}  > ${DOCKER_IMAGES_FILE_FORMAT}
}



F_find_tag()
{
    F_TAG="$1"
    # 注意：使用变量时，正则表达式不能使用【/^$/】这些字符，否则正则表达式不能正常运行
    # 精确匹配，但不能使用变量：cat ${DOCKER_IMAGES_FILE_FORMAT} | awk '{if($2 ~  /^关键字$/)      {printf "%s\n" ,$0}}'  ---使用【~】
    # 精确匹配，可以使用变量：  cat ${DOCKER_IMAGES_FILE_FORMAT} | awk '{if($2 == "'"${F_TAG}"'")  {printf "%s\n" ,$0}}'  ---使用【==】，变量使用两个【"'"】包围
    # 模糊匹配，可以使用变量：  cat ${DOCKER_IMAGES_FILE_FORMAT} | awk '{if($2 ~  "'"${F_TAG}"'")  {printf "%s\n" ,$0}}'  ---使用【~】，变量使用两个【"'"】包围
    cat ${DOCKER_IMAGES_FILE_FORMAT} | awk '{if($2 == "'"${F_TAG}"'") {printf "%s\n" ,$0}}' > ${DOCKER_IMAGES_FILE_DEL}
    cat ${DOCKER_IMAGES_FILE_DEL}  > ${DOCKER_IMAGES_FILE_FORMAT}
}



F_find_days_ago()
{
    F_DAYS=$1
    cat ${DOCKER_IMAGES_FILE_FORMAT} | awk -v awk_F_DAYS=${F_DAYS} '{if($4 > awk_F_DAYS) {printf "%s\n" ,$0}}' > ${DOCKER_IMAGES_FILE_DEL}
    cat ${DOCKER_IMAGES_FILE_DEL}  > ${DOCKER_IMAGES_FILE_FORMAT}
}





# 参数检查
TEMP=`getopt -o hqk:t:d:  -l help,quiet,keyword:,tag:,days: -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 1
fi

# 参数个数为0
if [[ $# -eq 0 ]]; then
    echo -e "\n猪猪侠警告：请提供必要运行参数，退出\n"
    exit 1
fi
#
eval set -- "${TEMP}"



# 获取次要命令参数
SH_ARGS_NUM=$#
SH_ARGS[0]="占位"
for ((i=1;i<=SH_ARGS_NUM;i++)); do
    eval K=\${${i}}
    SH_ARGS[${i}]=${K}
    #echo SH_ARGS数组${i}列的值是: ${SH_ARGS[${i}]}
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
        -q|--quiet)
            RM_OK=Y
            ;;
        -k|--keyword)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            F_find_keyword "$J"
            ;;
        -t|--tag)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            F_find_tag "$J"
            ;;
        -d|--days)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            # 判断是否为自然数
            if grep -E '^[0-9]$|^[1-9][0-9]+$' <<< $J  > /dev/null 2>&1; then
                echo
            else
                echo -e "\n猪猪侠警告：-d|--days 参数必须为数字，byebye！\n"
                exit 1
            fi
            F_find_days_ago $J
            ;;
        --)
            break
            ;;
        *)
            # 跳过
            ;;
    esac
done



# 删除
cat ${DOCKER_IMAGES_FILE_FORMAT} | sort -u -k 3  > ${DOCKER_IMAGES_FILE_DEL}
cat ${DOCKER_IMAGES_FILE_FORMAT} | awk '{printf "%4d %s\n", NR,$0}'  > ${DOCKER_IMAGES_FILE_DEL}
cat ${DOCKER_IMAGES_FILE_DEL}  > ${DOCKER_IMAGES_FILE_FORMAT}
# 空
if [[ `cat ${DOCKER_IMAGES_FILE_DEL} | wc -l` -eq 0 ]]; then
    echo -e "\n猪猪侠警告：待删除的docker镜像清单为空，滚！\n"
    exit
fi
#
echo "准备删除以下docker镜像："
cat ${DOCKER_IMAGES_FILE_DEL}
#
if [[ -z "${RM_OK}" ]]; then
    read -p "确认删除吗（Y/N）：" RM_OK
fi
#
if [[ "${RM_OK}" == 'Y' ]]; then
    cat ${DOCKER_IMAGES_FILE_DEL} | awk '{print $4}' | sort -u | xargs docker rmi -f
    echo OK
else
    echo -e "\n好吧，你想好先^_^\n"
fi


