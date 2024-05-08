#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################

# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
#cd "${SH_PATH}"


# 引入env
[[ -f /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh ]] && . /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
#DINGDING_WEBHOOK_API=
dingding_api_url=${DINGDING_WEBHOOK_API_NEW:-"${DINGDING_WEBHOOK_API}"}

# 本地env
HOSTNAME=$(hostname)    #-- 获取主机名
DATETIME=$(date "+%Y-%m-%d %H:%M:%S %z")    #-- 小时时间标记
send_title=""
send_message=""


# 用法：
F_HELP()
{
    echo "
    用途：将markdown格式的文本通过钉钉机器人发送出去
    依赖：/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
    注意：
    用法:
        $0  [-h|--help]
        $0  <-w|--webhook {Webhook地址}>  [-t|--title {消息标题}  -m|--message {消息内容}]
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help        此帮助
        -w|--webhook     钉钉webhook地址，默认从从环境变量中继承（DINGDING_WEBHOOK_API、DINGDING_WEBHOOK_API_{1,2,3}，数字越大优先级越高）
        -t|--title       消息标题
        -m|--message     消息内容
    示例:
        $0  -t 'sssss'       -m \"\`cat xxx.md\`\"
        $0  --title 'sssss'  --message \"\`cat xxx.md\`\"                                               #-- 从文件获取
        $0  --title 'sssss'  --message \"### 用户：\${USER}\"                                            #-- 简单输出
        $0  --title 'sssss'  --message \"\$( echo -e "### 用户：\${USER} \n### 时间：\`date\` \n\n" )\"     #-- 从命令获取
        $0  -w \"https://oapi.dingtalk.com/robot/send?access_token=你自己的钉钉机器人token\"  -t 'sssss'  -m \"### 用户：\${USER}\"
    "
}



# 参数检查
# 检查参数是否符合要求，会对参数进行重新排序，列出的参数会放在其他参数的前面，这样你在输入脚本参数时，不需要关注脚本参数的输入顺序，例如：'$0 aa bb -w wwww ccc'
# 但除了参数列表中指定的参数之外，脚本参数中不能出现以'-'开头的其他参数，例如按照下面的参数要求，这个命令是不能正常运行的：'$0 -w wwww  aaa --- bbb ccc'
# 如果想要在命令中正确运行上面以'-'开头的其他参数，你可以在'-'参数前加一个'--'参数，这个可以正确运行：'$0 -w wwww  aaa -- --- bbb ccc'
# 你可以通过'bash -x'方式运行脚本观察'--'的运行规律
#
#TEMP=`getopt -o hw:t:m:  -l help,webhook:,title:,message: -- "$@"`
#if [ $? != 0 ]; then
#    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"  >&2
#    exit 51
#fi
##
#eval set -- "${TEMP}"
#
# 因为输入参数可能有以'-'开头的，必须关闭参数检查



while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            shift
            F_HELP
            exit 0
            ;;
        -w|--webhook)
            dingding_api_url="$2"
            shift 2
            ;;
        -t|--title)
            send_title="$2"
            shift 2
            ;;
        -m|--message)
            send_message="$2"
            #shift 2     #-- 如果不够两个将会失败，造成死循环
            shift
            shift
            ;;
#        --)
#            shift
#            break
#            ;;
        *)
            break
            ;;
    esac
done



if [[ -z $send_title || -z $send_message ]]; then
    echo -e "\n猪猪侠警告：参数不足，请查看帮助【$0 --help】\n"  >&2
    exit 51
fi

if [[ -z ${dingding_api_url} ]]; then
    echo -e "\n猪猪侠警告：参数dingding_api_url为空，请引入变量或使用【-w|--webhook】参数设置\n"  >&2
    exit 51
fi



send_header="Content-Type: application/json; charset=utf-8"

send_message="### ${send_title} \n---\n${send_message} \n\n---\n\n*发自: ${HOSTNAME}*\n\n*时间: ${DATETIME}*\n\n"

send_data=$(cat <<EOF
{
  "msgtype": "markdown",
  "markdown": {
    "title": "${send_title}",
    "text": "${send_message}"
  }
}
EOF
)

curl -s -X POST -H "${send_header}" -d "${send_data}" "${dingding_api_url}" || { echo "Error sending message" >&2 ; exit 1; }


