#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# key申请地址：https://developer.godaddy.com/keys
#
# godaddy API 文档：
# https://developer.godaddy.com/doc/endpoint/domains#/
#
# 测试环境： For the OTE environment, use your OTE Key and Secret with the following base URL: https://api.ote-godaddy.com
# 生产环境： For the production environment, use your production Key and Secret with the following base URL: https://api.godaddy.com
#
# 查询：
# GET:   /v1/domains/{domain}/records/{type}/{name}      查询某记录：Retrieve DNS Records for the specified Domain, optionally with the specified Type and/or Name
# GET:   /v1/domains/{domain}/records/{type}             查询所有某类型记录
#
# 添加：
# PUT:   /v1/domains/{domain}/records/{type}/{name}      替换某type某name所有记录(所有符合条件的历史记录会全部删除，然后添加新的)：Replace all DNS Records for the specified Domain with the specified Type and Name
# PATCH: /v1/domains/{domain}/records                    添加多个记录：Add the specified DNS Records to the specified Domain
#
# 以下谨慎使用：
# PUT:   /v1/domains/{domain}/records/{type}             替换某type所有记录：Replace all DNS Records for the specified Domain with the specified Type
# PUT:   /v1/domains/{domain}/records                    替换某域名所有记录：Replace all DNS Records for the specified Domain
#
# recoders json数据格式：
# [
#   {
#     "data": "string",
#     "name": "string",
#     "port": 0,
#     "priority": 0,
#     "protocol": "string",
#     "service": "string",
#     "ttl": 0,
#     "type": "A",
#     "weight": 0
#   }
# ]

## 查询
## 查询域名
#curl -X GET "${godaddy_env}/v1/domains/${MASTER_DOMAIN}"  -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_TOKEN"  | jq
#
## 查询dns记录
#curl -X GET "${godaddy_env}/v1/domains/${MASTER_DOMAIN}/records"  -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_TOKEN"  | jq
#
## 查询dns某类型记录
#curl -X GET "${godaddy_env}/v1/domains/${MASTER_DOMAIN}/records/${R_TYPE}"  -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_TOKEN"  | jq
#
## 查询dns某类型某名称记录
#curl -X GET "${godaddy_env}/v1/domains/${MASTER_DOMAIN}/records/${R_TYPE}/${R_NAME}"  -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_TOKEN"  | jq
#
## 修改添加
## 添加修改dns某类型某名称记录
#curl -X PUT "${godaddy_env}/v1/domains/${MASTER_DOMAIN}/records/${R_TYPE}/${R_NAME}"  -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_TOKEN"  -H 'Content-Type: application/json'  --data '[{"type": "'"${R_TYPE}"'", "name": "'"$R_NAME"'", "data": "'"$R_VALUE"'", "ttl": 3600}]'




## 指定用户下运行
#if [ ${USER} != 'root' ]; then
#    echo '请在root用户下运行！'
#    exit 1
#fi

# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 自动从/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh引入以下变量

# 引入env

# 本地env
TIME=`date +%Y-%m-%dT%H:%M:%S`
TIME_START=${TIME}


# godaddy信息
GODADDY_SEC_ENV="/etc/godaddy.sec.env"
if [[ -f ${GODADDY_SEC_ENV} ]]; then
    . ${GODADDY_SEC_ENV}
else
    echo -e "\n猪猪侠警告：没有找到sec文件\n"
    exit 1
fi
#godaddy_env="https://api.ote-godaddy.com"
#GODADDY_KEY=''
#GODADDY_TOKEN=''



# 用法：
F_HELP()
{
    echo "
    用途：用于查询修改Godaddy dns信息
    依赖：
    注意：
        * 输入命令时，参数顺序不分先后
    用法:
        $0 -h|--help
        $0 [-A query_domain]  [-d {主域名}]                                                                    #-- 查询域信息
        $0 [-A query_record]  [-d {主域名}]  <-t [A|TXT|RNAME|...]>  <-n {dns记录名}>                          #-- 查询域记录
        $0 [-A delete]        [-d {主域名}]  <-t [A|TXT|RNAME|...]>  <-n {dns记录名}>                          #-- 删除记录，未实现
        $0 [-A replace|append]  [-d {主域名}]  <-t [A|TXT|RNAME|...]>  <-n {dns记录名}>  <-v {dns记录值}>      #-- 替换或追加域名记录
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是一个整体，是必选项，默认是必选项（即没有括号【[]、<>】时也是必选项），一般用于表示参数对，此时不可乱序，单个参数也可以使用括号
        <>   : 代表是一个整体，是可选项，默认是必选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help    此帮助
        -A|--Action  指定操作类型replace|append|delete|query_domain|query_record，注：replace是删除所有现有匹配的，然后新增
        -d|--domain  指定主域名
        -t|--type    指定dns记录类型A|TXT|RNAME|...
        -n|--name    指定dns记录名称
        -v|--value   指定dns记录值
    示例:
        # 增加与修改：
        $0 -A [replace|append]  <-d 域名>  [-t [A|TXT|RNAME|...]]  [-n dns记录名]  [-v dns记录值]     #--- replace：删除现有后新增； append：增加多一条
        # 查询：
        $0 -A query_domain  -d aaa.com                                  #--- 查询域名【aaa.com】信息
        $0 -A query_record  -d aaa.com                                  #--- 查询域名【aaa.com】下所有记录
        $0 -A query_record  -d aaa.com  -t A                            #--- 查询域名【aaa.com】下【A】类型所有记录
        $0 -A query_record  -d aaa.com  -t TXT  -n www                  #--- 查询域名【aaa.com】下【TXT】类型名称【www】的所有记录
        $0 -A append        -d aaa.com  -t TXT  -n www  -v 2.22.22.22   #--- 添加【A】类型域名【www.aaa.com】，IP是【2.22.22.22】
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
TEMP=`getopt -o hA:d:t:n:v:  -l help,Action:,domain:,type:,name:,value: -- "$@"`
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
            MASTER_DOMAIN=$J
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
        --)
            break
            ;;
        *)
            # 跳过
            ;;
    esac
done


# 域名不能为空
if [[ -z "${MASTER_DOMAIN}" ]]; then
    echo -e "\n猪猪侠警告：域名参数为空，请检查！\n"
    exit 1
fi


#
# 获取主要参数，运行
while true
do
    #
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
            case ${R_ACTION} in
                replace)
                    #
                    if [[ -z ${R_TYPE} || -z ${R_NAME} || -z ${R_VALUE} ]]; then
                        echo -e "\n猪猪侠警告：命令参数不足，请查看帮助！\n"
                        exit 53
                    fi
                    # 删除匹配并追加
                    curl -X PUT "${godaddy_env}/v1/domains/${MASTER_DOMAIN}/records/${R_TYPE}/${R_NAME}"  -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_TOKEN"  -H 'Content-Type: application/json'  --data '[{"type": "'"${R_TYPE}"'", "name": "'"$R_NAME"'", "data": "'"$R_VALUE"'", "ttl": 3600}]'
                    ;;
                append)
                    #
                    if [[ -z ${R_TYPE} || -z ${R_NAME} || -z ${R_VALUE} ]]; then
                        echo -e "\n猪猪侠警告：命令参数不足，请查看帮助！\n"
                        exit 53
                    fi
                    # 仅追加
                    curl -X PATCH "${godaddy_env}/v1/domains/${MASTER_DOMAIN}/records"  -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_TOKEN"  -H 'Content-Type: application/json'  --data '[{"type": "'"${R_TYPE}"'", "name": "'"$R_NAME"'", "data": "'"$R_VALUE"'", "ttl": 3600}]'
                    ;;
                delete)
                    echo -e "\n猪猪侠警告：此功能暂未实现，因为godaddy没有提供api\n"
                    ;;
                query_domain)
                    curl -X GET "${godaddy_env}/v1/domains/${MASTER_DOMAIN}"  -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_TOKEN"  | jq
                    ;;
                query_record)
                    if [[ "x${R_TYPE}" != "x" && "x${R_NAME}" != "x" ]]; then
                        curl -X GET "${godaddy_env}/v1/domains/${MASTER_DOMAIN}/records/${R_TYPE}/${R_NAME}"  -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_TOKEN"  | jq
                    elif [[ "x${R_TYPE}" != "x" && "x${R_NAME}" == "x" ]]; then
                        curl -X GET "${godaddy_env}/v1/domains/${MASTER_DOMAIN}/records/${R_TYPE}"  -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_TOKEN"  | jq
                    else
                        curl -X GET "${godaddy_env}/v1/domains/${MASTER_DOMAIN}/records"  -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_TOKEN"  | jq
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


