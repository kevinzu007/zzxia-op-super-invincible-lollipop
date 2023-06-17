#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# 安装阿里云CLI
# https://www.alibabacloud.com/help/zh/doc-detail/90765.htm?spm=a2c63.l28256.b99.5.51255cbduC7hJw

# recoders json数据格式：
# {
#   "TotalCount": 32,
#   "RequestId": "7EC1B35C-BC71-4927-95CC-16AF16341FFA",
#   "PageSize": 1,
#   "DomainRecords": {
#     "Record": [
#       {
#         "RR": "stag-public",
#         "Line": "default",
#         "Status": "ENABLE",
#         "Locked": false,
#         "Type": "A",
#         "DomainName": "gc.cn",
#         "Value": "47.52.28.20",
#         "RecordId": "18669933463756800",
#         "TTL": 600
#       }
#     ]
#   },
#   "PageNumber": 1
# }


# aliyun信息
# 需要阿里云AccessKey
# ~/.aliyun/config.json
# 交互方式设置config：
# $ aliyun configure
# 非交互方式设置config：
# $ aliyun configure set \
#     --profile hk \
#     --language zh \
#     --mode AK \
#     --region cn-hongkong \
#     --access-key-id LTAIwHXKTccccccc \
#     --access-key-secret lvpSQqU1Q1BANF2dyYOVgHccccccc



# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 自动从/etc/profile.d/run-env.sh引入以下变量

# 引入env

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START="${TIME}"



# 用法：
F_HELP()
{
    echo "
    用途：用于查询修改dns信息
    依赖：
        /etc/profile.d/run-env.sh
        阿里云CLI：aliyun
    注意：
        * 输入命令时，参数顺序不分先后
    用法:
          $0 [-h|--help]
          $0 -A [replace|append|delete|query_domain|query_record]  <-d {域名}>  <-t [A|TXT|RNAME|...]>  <-n {dns记录名}>  <-v {dns记录值}>  <-w {关键字}>
    参数说明：
          -h|--help    此帮助
          -A|--Action  指定操作类型replace|append|delete|query_domain|query_record
          -d|--domain  指定域名，默认为/etc/profile.d/run-env.sh中定义的\${DOMAIN}
          -t|--type    指定dns记录类型A|TXT|CNAME|...
          -n|--name    指定dns记录名称
          -v|--value   指定dns记录值
          -w|--keyword 指定搜索关键字，在name及value中匹配
    示例:
          # 增加与修改：
          $0 -A [replace|append]  <-d 域名>  [-t [A|TXT|CNAME|...]]  [-n dns记录名]  [-v dns记录值]     #--- replace：删除现有后新增； append：增加多一条
          # 查询：
          $0 -A query_domain  <-d 域名>                                          #--- 查询域名信息
          $0 -A query_record  <-d 域名>                                          #--- 查询域名下所有记录
          $0 -A query_record  <-d 域名>  [-t [A|TXT|CNAME|...]]                  #--- 查询域名下该类型所有的记录
          $0 -A query_record  <-d 域名>  [-t [A|TXT|CNAME|...]]  [-n dns记录名]  #--- 查询域名下该类型该 名称 所有的记录
          $0 -A query_record  <-d 域名>  [-w 关键字]                             #--- 查询域名下模糊匹配该 名称或值 所有的记录
          $0 -A query_record  <-d 域名>  [-t [A|TXT|CNAME|...]]  [-w 关键字]     #--- 查询域名下该类型模糊匹配该 名称或值 所有的记录(此功能aliyun有bug)
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
TEMP=`getopt -o hA:d:t:n:v:w:  -l help,Action:,domain:,type:,name:,value:,keyword: -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
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
        -d|--domain)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            R_DOMAIN=$J
            ;;
        -t|--type)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            R_TYPE=$J
            ;;
        -n|--name)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            R_NAME=$J
            ;;
        -v|--value)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            R_VALUE=$J
            ;;
        -w|--keyword)
            j=$((i+1))
            J=${SH_ARGS[$j]}
            R_KEYWORD=$J
            ;;
        --)
            break
            ;;
        *)
            # 跳过
            ;;
    esac
done


# 域名不能为空
if [[ -z "${R_DOMAIN}" ]]; then
    echo -e "\n猪猪侠警告：域名参数为空，请检查！\n"
    exit 1
fi


#
# 获取主要参数
while true
do
    #echo 当前第一个参数是：$1
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -d|--domain|-t|--type|-n|--name|-v|--value)
            # 前面已处理，跳过
            shift 2
            ;;
        -A|--Action)
            R_ACTION="$2"
            shift 2
            #
            case "${R_ACTION}" in
                replace)
                    # 删除匹配并追加
                    echo -e "以下记录将被删除：\n"
                    aliyun alidns DescribeDomainRecords  --DomainName=${R_DOMAIN}  --Type=${R_TYPE}  --RRKeyWord ${R_NAME} | jq '.DomainRecords.Record[] | select (.RR=="'"${R_NAME}"'")'
                    aliyun alidns DescribeDomainRecords  --DomainName=${R_DOMAIN}  --Type=${R_TYPE}  --RRKeyWord ${R_NAME} | jq '.DomainRecords.Record[] | select (.RR=="'"${R_NAME}"'") | .RecordId' > /tmp/${SH_NAME}.RID
                    while read LINE
                    do
                        RID=`echo ${LINE} | sed 's/\"//g'`
                        aliyun alidns DeleteDomainRecord  --RecordId=${RID}
                    done < /tmp/${SH_NAME}.RID
                    # 追加
                    aliyun alidns AddDomainRecord  --DomainName=${R_DOMAIN}  --Type=${R_TYPE} --RR=${R_NAME} --Value=${R_VALUE}
                    ;;
                append)
                    # 仅追加
                    aliyun alidns AddDomainRecord  --DomainName=${R_DOMAIN}  --Type=${R_TYPE} --RR=${R_NAME} --Value=${R_VALUE}
                    ;;
                delete)
                    echo -e "以下记录将被删除：\n"
                    aliyun alidns DescribeDomainRecords  --DomainName=${R_DOMAIN}  --Type=${R_TYPE}  --RRKeyWord ${R_NAME} | jq '.DomainRecords.Record[] | select (.RR=="'"${R_NAME}"'")'
                    aliyun alidns DescribeDomainRecords  --DomainName=${R_DOMAIN}  --Type=${R_TYPE}  --RRKeyWord ${R_NAME} | jq '.DomainRecords.Record[] | select (.RR=="'"${R_NAME}"'") | .RecordId' > /tmp/${SH_NAME}.RID
                    while read LINE
                    do
                        RID=`echo ${LINE} | sed 's/\"//g'`
                        aliyun alidns DeleteDomainRecord  --RecordId=${RID}
                    done < /tmp/${SH_NAME}.RID
                    ;;
                query_domain)
                    echo -e "\n猪猪侠警告：此功能暂不提供，官方whois功能不能正常输出\n"
                    ;;
                query_record)
                    if [[ -z "${R_KEYWORD}" ]]; then
                        if [[ "x${R_TYPE}" != "x" && "x${R_NAME}" != "x" ]]; then
                            aliyun alidns DescribeDomainRecords  --DomainName=${R_DOMAIN}  --Type=${R_TYPE}  --RRKeyWord ${R_NAME}
                        elif [[ "x${R_TYPE}" != "x" && "x${R_NAME}" == "x" ]]; then
                            aliyun alidns DescribeDomainRecords  --DomainName=${R_DOMAIN}  --Type=${R_TYPE}
                        else
                            aliyun alidns DescribeDomainRecords  --DomainName=${R_DOMAIN}
                        fi
                    else
                        if [[ ! -z "${R_TYPE}" ]]; then
                            aliyun alidns DescribeDomainRecords  --DomainName=${R_DOMAIN}  --Type=${R_TYPE}  --KeyWord ${R_KEYWORD}
                        else
                            aliyun alidns DescribeDomainRecords  --DomainName=${R_DOMAIN}  --KeyWord ${R_KEYWORD}
                        fi
                    fi
                    ;;
                --)
                    shift
                    break
                    ;;
                *)
                    echo -e "\n猪猪侠警告：-A|--Action参数错误\n"
                    exit 1
                    ;;
            esac
            # send msg
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


