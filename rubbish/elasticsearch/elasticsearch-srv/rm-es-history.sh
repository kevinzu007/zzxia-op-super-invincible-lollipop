#!/bin/bash

# 请注意：
# 这个目前是简单使用，es服务器地址信息在此文件变量【ES_BASE_URL】里，也没弄用户名密码，请用合适的方式使用


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"

# 引入env


# 本地env
TODAY=$(date +%Y-%m-%d)
ES_BASE_URL='http://127.0.0.1:9200'



# 用法：
F_HELP()
{
    echo "
    用途：删除es索引数据
    依赖：
    注意：运行在es服务器上
        * 输入命令时，参数顺序不分先后
    用法:
        $0  [-h|--help]
        $0  [-l|--list-index]                        #--- 列出所有索引名称
        $0  [-L|--list-index-days  {索引名称}]       #--- 列出指定索引所有日期
        $0  [-r|--rm  {索引名称}  {天数}]            #--- 删除指定索引，指定天数之前的数据
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help              此帮助
        -l|--list-index        列出索引名称
        -L|--list-index-days   列出索引名称下所有日期
        -r|--rm                删除索引数据保留天数
    示例:
        $0  -l                 #--- 列出所有索引名称
        $0  -L  ggg            #--- 列出索引【ggg】下所有日期
        $0  -r  ggg  30        #--- 删除索引【ggg】【30】天以前的数据
    "
}



# 删除索引
# 用法： F_RM
#
F_RM()
{
    R_DATE_LIST=$(curl -s -XGET "${ES_BASE_URL}/_cat/indices" | awk '{print $3}' | grep "${INDEX_NAME}" | cut -d '-' -f 2- | sort)     #--- 格式：%Y.%m.%d
    S_TODAY=$(date -d ${TODAY} +%s )
    
    for i in ${R_DATE_LIST}
    do
        j=$(echo $i | sed -E 's/\./-/g')
        S_J=$(date -d ${j} +%s)
        #
        let N=(${S_TODAY}-${S_J})/86400
        if [[ $N -ge ${RETENTION_DAYS} ]]; then
            curl -XDELETE "${ES_BASE_URL}/${INDEX_NAME}-${i}"
        fi
    done
}



## 参数检查
#TEMP=`getopt -o hlL:r:  -l help,list-index,list-index-days:rm: -- "$@"`
#if [ $? != 0 ]; then
#    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
#    F_HELP
#    exit 51
#fi
##
#eval set -- "${TEMP}"


# 获取参数
while true
do
    #
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -l|--list-index)
            # 列出索引
            curl -s -XGET "${ES_BASE_URL}/_cat/indices" | awk '{print $3}' | cut -d '-' -f 1 | sort | uniq
            exit
            ;;
        -L|--list-index-days)
            INDEX_NAME=$2
            shift
            #
            if [[ -z ${INDEX_NAME} ]]; then
                echo -e "\n猪猪侠警告：参数【-L|--list-index-days】使用错误，请看帮助【$0 --help】\n"
                exit 51
            fi
            # 列出基于日期的索引
            curl -s -XGET "${ES_BASE_URL}/_cat/indices" | awk '{print $3}' | grep "${INDEX_NAME}"
            exit
            ;;
        -r|--rm)
            INDEX_NAME=$2
            RETENTION_DAYS=$3
            shift 3
            #
            if [[ -z ${INDEX_NAME} ]]; then
                echo -e "\n猪猪侠警告：参数【-L|--list-index-days】使用错误，请看帮助【$0 --help】\n"
                exit 51
            fi
            #
            if [[ ! ${RETENTION_DAYS} =~ ^[0-9]+$ ]]; then
                echo -e "\n猪猪侠警告：参数【--rm-retention-days】不合法，请看帮助【$0 --help】\n"
                exit 51
            fi
            # 执行删除
            F_RM
            exit
            ;;
        --)
            shift
            break
            ;;
        *)
            echo -e "\n猪猪侠警告：未知参数，请查看帮助【$0 --help】\n"
            exit 51
            ;;
    esac
done

exit


