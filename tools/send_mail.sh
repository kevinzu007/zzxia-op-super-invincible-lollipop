#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# sh
DINGDING_BY_MARKDOWN_FILE_SH="/usr/local/bin/dingding_send_markdown.sh"



F_HELP()
{
    echo "
    用途：使用mailx发送邮件
    依赖：
        mailx
        ${DINGDING_BY_MARKDOWN_FILE_SH}
    注意：
        * 输入命令时，参数顺序不分先后
    用法：
        $0 [-h|--help]
        $0 [-s|--subject {主题}]  [-c|--content {邮件内容}]  <[-a|--attach {文件名1}] ... [-a|--attach {文件名n}]>  <-o|--origin-option [{mailx选项]}>  [{收件人1} ... <{收件人n}>]
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是一个整体，是必选项，默认是必选项（即没有括号【[]、<>】时也是必选项），一般用于表示参数对，此时不可乱序，单个参数也可以使用括号
        <>   : 代表是一个整体，是可选项，默认是必选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help       查看本帮助
        -s|--subject    邮件主题，注意事项：为避免空格问题，一定要用引号引起来，不管是字符串还是变量
        -c|--content    邮件内容，注意事项同上
        -a|--attach     邮件附件，可以有多个
        -o|--origin-option     mailx自带的其他非必须参数选项，可以有多个，注意事项同上
    示例：
        # 一般用法：(-a 附件文件名不能有空格)
        $0  [-s \"邮件主题\"]  [-c \"邮件内容\"]  <[-a "文件名1"] ... <[-a "文件名n"]>>   [收件人1] ... <收件人n>

        # -c 之 邮件内容高级用法(邮件主题同之)：
        $0  [-s "邮件主题"]    [-c \"[邮件内容]\" | \"\`echo \${邮件内容变量}\`\" | \"\`cat 邮件内容文件名\`\" ]   [收件人1] ... <收件人n>

        # -o 之 mailx自带的高级选项用法，例如：添加-c、-b，如下：(更多高级选项请参考man mailx)
        $0  [-s "邮件主题"]    [-c \"[邮件内容]\" ]  <[-o \"-c 抄送地址\"] ... <-o \"-b 暗送地址\">>   [收件人1] ... <收件人n>
        # 例如：(注意","分隔处不能有空格)
        $0  -s \"\${SS}\" -c \"222 33\" -o \"-c admin@gc.com,zhu@gc.com\" -o \"-b 猪猪侠@163.com\"  reg@gc.com
        $0  -s \"\${SS}\" -c \"222 33\" -o \"-c admin@gc.com,zhu@gc.com      -b 猪猪侠@163.com\"  reg@gce.com
    "
}



TEMP=`getopt -o hs:c:a:o:  -l help,subject:,content:,attach:,origin-option -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 1
fi
#
eval set -- "${TEMP}"


MAIL_ATTACH_S=""
MAIL_OPTION_S=""

while true
do
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -s|--subject)
            MAIL_SUBJECT="$2"
            shift 2
            ;;
        -c|--content)
            MAIL_CONTENT="$2"
            shift 2
            ;;
        -a|--attach)
            MAIL_ATTACH_S="-a $2 ${MAIL_ATTACH_S}"
            shift 2
            ;;
        -o|--origin-option)
            MAIL_OPTION_S="$2 ${MAIL_OPTION_S}"
            shift 2
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


# 必须软件mailx
if [ "`which mailx >/dev/null 2>&1 ; echo $?`" != "0" ]; then
    ${DINGDING_BY_MARKDOWN_FILE_SH}  \
        --title "【Error:邮件:${RUN_ENV}】"  \
        --message "$( echo -e "### 请安装软件mailx" )"
    echo -e "\n猪猪侠警告：请安装软件mailx\n"
    exit 1
fi



# 不能为空
if [ -z "${MAIL_SUBJECT}"  -o  -z "${MAIL_CONTENT}"  -o  -z "$@" ]; then
    echo "猪猪侠警告：邮件主题、内容、收件人 都不允许为空，当前信息如下："
    echo -e "\n主题：${MAIL_SUBJECT}  \n内容：${MAIL_CONTENT}  \n收件人：$@  \n"
    exit 1
fi


#echo "邮件发送给：-- $@"
#echo  "${MAIL_CONTENT}" | mailx  -s "${MAIL_SUBJECT}"  ${MAIL_OPTION_S}  ${MAIL_ATTACH_S}  $@
echo -e "${MAIL_CONTENT}" | mailx  -s "${MAIL_SUBJECT}"  ${MAIL_OPTION_S}  ${MAIL_ATTACH_S}  $@  >/tmp/send_mail.sh.log 2>&1
# mailx命令出错会直接退出，下面的语句是无效的
#[ $? != 0 ] && echo -e "\n  邮件发送失败，请检查日志：/tmp/send_mail.sh.log\n"



