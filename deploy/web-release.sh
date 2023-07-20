#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"

# 引入/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
.  /etc/profile        #-- 非终端界面不会自动引入，必须主动引入
#RUN_ENV=
#NGINX_CONFIG_SH_HOME=

# 引入env.sh
. ${SH_PATH}/env.sh
#LOLLIPOP_PLATFORM_NAME=
#LOLLIPOP_DB_HOME=
#LOLLIPOP_LOG_BASE=
#ANSIBLE_HOST_FOR_LOGFILE=
# 来自 ${MY_PRIVATE_ENVS_DIR} 目录下的 *.sec
#USER_DB_FILE=
#USER_DB_FILE_APPEND_1=
#DINGDING_API=

# 本地env
GAN_WHAT_FUCK='Web_Release'
NEED_PRIVILEGES='deploy'                   #-- 运行此程序需要的权限，如果需要多个权限，则用【&】分隔
TIME=${TIME:-`date +%Y-%m-%dT%H:%M:%S`}
TIME_START=${TIME}
DATE_TIME=`date -d "${TIME}" +%Y%m%dT%H%M%S`
#
LOG_HOME="${LOLLIPOP_LOG_BASE}/${DATE_TIME}"
#
ERROR_CODE=''     #--- 程序最终返回值，一般用于【--mode=function】时
#
TODAY=$(date -d "${TIME}" +%Y%m%d)
WEB_PROJECT_LIST_FILE="${SH_PATH}/nginx.list"
WEB_PROJECT_LIST_FILE_TMP="${LOG_HOME}/${SH_NAME}-nginx.list.tmp"
#
WEB_RELEASE_NGINX_OK_LIST_FILE="${LOG_HOME}/${SH_NAME}-web_release_nginx-OK.list"
WEB_RELEASE_OK_LIST_FILE="${LOG_HOME}/${SH_NAME}-web_release-OK.list"
#
WEB_RELEASE_HISTORY_CURRENT_FILE="${LOG_HOME}/${SH_NAME}.history.current"
FUCK_HISTORY_FILE="${LOLLIPOP_DB_HOME}/fuck.history"
# 运行方式
SH_RUN_MODE="normal"
# 来自webhook或父shell
export HOOK_USER_INFO_FROM
export HOOK_GAN_ENV
export HOOK_USER_NAME
export HOOK_USER_XINGMING
export HOOK_USER_EMAIL
# 来自父shell
WEB_RELEASE_OK_LIST_FILE_function=${WEB_RELEASE_OK_LIST_FILE_function:-"${LOG_HOME}/${SH_NAME}-web_release-OK.list.function"}
#MY_USER_NAME=
#MY_USER_XINGMING=
#MY_USER_EMAIL=
if [[ -z ${USER_INFO_FROM} ]]; then
    USER_INFO_FROM=${HOOK_USER_INFO_FROM:-'local'}     #--【local|hook_hand|hook_gitlab】，默认：local
fi
# sh
FORMAT_TABLE_SH="${SH_PATH}/../tools/format_table.sh"
DINGDING_MARKDOWN_PY="${SH_PATH}/../tools/dingding_conver_to_markdown_list-deploy.py"
# 引入函数
.  ${SH_PATH}/function.sh



# 删除空行（以及只有tab、空格的行）
#sed -i '/^\s*$/d'  "${WEB_PROJECT_LIST_FILE}"
# 删除行中的空格
#sed -i 's/[ \t]*//g'  "${WEB_PROJECT_LIST_FILE}"



# 用法：
F_HELP()
{
    echo "
    用途：Web站点发布上线
    依赖：
        ${WEB_PROJECT_LIST_FILE}
        ${FORMAT_TABLE_SH}
        ${DINGDING_MARKDOWN_PY}
        ${SH_PATH}/env.sh
        nginx上：/root/nginx-config/web-release-on-nginx.sh
    注意：运行在nginx节点上
        * 【上线（ship）】流程包含以下四个子流程【构建】、【测试（test）】、【部署（deploy）】、【发布（release）】。原地发布（即部署 == 发布）
        * 名称正则表达式完全匹配，会自动在正则表达式的头尾加上【^ $】，请规避
        * 输入命令时，参数顺序不分先后
    用法:
        $0  [-h|--help]
        $0  [-l|--list]                                         #--- 列出项目
        $0  <-M|--mode [normal|function]>  [-r|--release]   <{项目1}  {项目2} ... {项目n} ... {项目名称正则表达式完全匹配}>     #--- 发布上线今天的版本
        $0  <-M|--mode [normal|function]>  [-b|--rollback]  <{项目1}  {项目2} ... {项目n} ... {项目名称正则表达式完全匹配}>     #--- 回滚到上一个版本
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help        此帮助
        -l|--list        项目列表
        -r|--release     发布
        -b|--rollback    回滚
        -M|--mode      ：指定构建方式，二选一【normal|function】，默认为normal方式。此参数用于被外部调用
    示例:
        $0  -l                 #--- 列出所有项目
        #
        $0  -r                 #--- 发布所有项目
        $0  -r  项目a 项目b    #--- 发布【项目a、项目b】
        #
        $0  -b                 #--- 回滚所有项目
        $0  -b  项目a 项目b    #--- 回滚【项目a、项目b】
        # 服务名称用正则完全匹配
        $0  -r  .*xxx.*           #--- 发布项目名称正则完全匹配【^.*xxx.*$】的第一个项目
        $0  -b  [.]*xxx           #--- 回滚项目名称正则完全匹配【^[.]*xxx$】的第一个项目
        # 外调用★
        $0  -M function  -r                 #--- 函数调用方式发布所有项目
        $0  -M function  -r  项目a 项目b    #---  函数调用方式发布【项目a、项目b】

    "
}



# 参数检查
TEMP=`getopt -o hlrbM:  -l help,list,release,rollback,mode: -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    F_HELP
    exit 51
fi
#
eval set -- "${TEMP}"


# 获取参数
while true
do
    #
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -l|--list)
            #cat  "${WEB_PROJECT_LIST_FILE}"
            sed  -E  -e '/^\s*$/d'  -e '/^##.*$/d'  -e '/---/d'  -e '/^#.*PRIORITY/d'  ${WEB_PROJECT_LIST_FILE}  > /tmp/web-release-project-list.txt
            ${FORMAT_TABLE_SH}  --delimeter '|'  --file /tmp/web-release-project-list.txt
            exit
            ;;
        -r|--release)
            WORK='release'
            shift
            ;;
        -b|--rollback)
            WORK='rollback'
            shift
            ;;
        -M|--mode)
            SH_RUN_MODE=$2
            shift 2
            # 参数
            case ${SH_RUN_MODE} in
                normal|function)
                    # OK
                    ;;
                *)
                    echo -e "\n猪猪侠警告：参数错误，-M|--mode 的参数值只能是：normal|function\n"
                    exit 51
                    ;;
            esac
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



# 建立base目录
[ -d "${LOG_HOME}" ] || mkdir -p  ${LOG_HOME}



# 运行环境匹配for Hook
if [[ -n ${HOOK_GAN_ENV} ]] && [[ ${HOOK_GAN_ENV} != 'NOT_CHECK' ]] && [[ ${HOOK_GAN_ENV} != ${RUN_ENV} ]]; then
    echo -e "\n猪猪侠警告：运行环境不匹配，跳过（这是正常情况）\n"
    exit
fi


# 获取用户信息
if [[ -z ${MY_USER_NAME} ]]; then
    if [[ ${USER_INFO_FROM} == 'local' ]]; then
        # if sudo -i 取${SUDO_USER}；
        # if sudo cmd 取${LOGNAME}
        export MY_USER_NAME=${SUDO_USER:-"${LOGNAME}"}
        #
        R=$(F_SEARCH_USER ${MY_USER_NAME})
        R_1=$(echo $R | awk -F '|' '{print $1}' | awk '{print $1}')
        if [[ ${R_1} == 0 ]]; then
            R_3=$(echo $R | awk -F '|' '{print $3}' | awk '{print $1}')
            R_4=$(echo $R | awk -F '|' '{print $4}' | awk '{print $1}')
            export MY_USER_XINGMING=${R_3}
            export MY_USER_EMAIL=${MY_USER_EMAIL:-"${R_4}"}
        else
            export MY_USER_XINGMING="x-Man"
            export MY_USER_EMAIL
        fi
    elif [[ ${USER_INFO_FROM} =~ hook_hand ]]; then
        #
        export MY_USER_NAME=${HOOK_USER_NAME}
        export MY_USER_XINGMING=${HOOK_USER_XINGMING}
        export MY_USER_EMAIL=${HOOK_USER_EMAIL}
    elif [[ ${USER_INFO_FROM} =~ hook_gitlab ]]; then
        #
        R=$(F_SEARCH_GITLAB_USER ${HOOK_USER_NAME})
        R_1=$(echo $R | awk -F '|' '{print $1}' | awk '{print $1}')
        if [[ ${R_1} == 0 ]]; then
            R_2=$(echo $R | awk -F '|' '{print $2}' | awk '{print $1}')
            export MY_USER_NAME=${R_2}
        else
            echo -e "\n猪猪侠警告：Gitlab用户不存在【${HOOK_USER_NAME}】\n"
            exit 52
        fi
        export MY_USER_XINGMING=${HOOK_USER_XINGMING}      #-- 使用gitlab上的
        export MY_USER_EMAIL=${HOOK_USER_EMAIL}            #-- 使用gitlab上的
    else
        echo -e "\n猪猪侠警告：未知参数值【\${USER_INFO_FROM} = ${USER_INFO_FROM}】\n"
        exit  51
    fi
fi


# 检查用户权限
if [[ ! ${MY_USER_XINGMING} =~ x-Man ]]; then
    #
    NEED_PRIVILEGES=${NEED_PRIVILEGES// /}
    NEED_PRIVILEGES_NUM=$(echo ${NEED_PRIVILEGES} | grep -o '&' | wc -l)
    #
    for ((j=PRIVILEGES_env_priv_NUM; j>=0; j--))
    do
        #
        FIELD_J=$((j+1))
        NEED_PRIVILEGES_x=`echo ${NEED_PRIVILEGES} | cut -d '&' -f ${FIELD_J}`
        #
        R=$(F_SEARCH_USER_PRIV  ${MY_USER_NAME}  ${NEED_PRIVILEGES_x})
        R_1=$(echo $R | awk -F '|' '{print $1}' | awk '{print $1}')
        if [[ ${R_1} != 0 ]]; then
            # 必须全部匹配
            echo -e "\n猪猪侠警告：用户【${MY_USER_NAME}】无【${NEED_PRIVILEGES}】权限！\n"
            exit 52
        fi
    done
fi



# 待搜索的WEB项目清单
> "${WEB_PROJECT_LIST_FILE_TMP}"
## 参数个数
if [[ $# -eq 0 ]]; then
    cp  "${WEB_PROJECT_LIST_FILE}"  "${WEB_PROJECT_LIST_FILE_TMP}"
else
    # 指定项目
    for i in "$@"
    do
        #
        GET_IT='N'
        while read LINE
        do
            # 跳过以#开头的行或空行
            [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
            #
            PJ=`echo $LINE | awk -F '|' '{print $2}'`
            PJ=`echo ${PJ}`
            if [[ ${PJ} =~ ^$i$ ]]; then
                echo $LINE >> "${WEB_PROJECT_LIST_FILE_TMP}"
                GET_IT='YES'
                break
            fi
        done < "${WEB_PROJECT_LIST_FILE}"
        #
        if [[ $GET_IT != 'YES' ]]; then
            echo -e "\n${ECHO_ERROR}猪猪侠警告：【${GAN_WHAT_FUCK}】时，项目【${i}】正则不匹配项目列表【${WEB_PROJECT_LIST_FILE}】中任何项目，请检查！${ECHO_CLOSE}\n"
            ${DINGDING_MARKDOWN_PY}  "【Error:${LOLLIPOP_PLATFORM_NAME}:${RUN_ENV}】" "猪猪侠警告：【${GAN_WHAT_FUCK}】时，项目【${i}】正则不匹配项目列表【${WEB_PROJECT_LIST_FILE}】中任何项目，请检查！" > /dev/null
            exit 51
        fi
    done
fi
# 删除无关行
#sed  -i  -E  -e '/^\s*$/d'  -e '/^#.*$/d'  -e 's/[ \t]*//g'  ${WEB_PROJECT_LIST_FILE_TMP}
sed  -i  -E  -e '/^\s*$/d'  -e '/^#.*$/d'  ${WEB_PROJECT_LIST_FILE_TMP}
# 优先级排序
> ${WEB_PROJECT_LIST_FILE_TMP}.sort
for i in  `awk -F '|' '{split($10,a," ");print NR,a[1]}' ${WEB_PROJECT_LIST_FILE_TMP}  |  sort -n -k 2 |  awk '{print $1}'`
do
    awk "NR=="$i'{print}' ${WEB_PROJECT_LIST_FILE_TMP}  >> ${WEB_PROJECT_LIST_FILE_TMP}.sort
done
cp  ${WEB_PROJECT_LIST_FILE_TMP}.sort  ${WEB_PROJECT_LIST_FILE_TMP}
# 加表头
sed -i  '1i#| **项目名** | **域名A记录** | **http端口** | **https端口** | **方式** | **后端协议端口** | **附加项** | **域名A记录IP** | **优先级** |'  ${WEB_PROJECT_LIST_FILE_TMP}
# 屏显
if [[ ${SH_RUN_MODE} == 'normal' ]]; then
    echo -e "${ECHO_NORMAL}========================= 开始发布 =========================${ECHO_CLOSE}"  #--- 60 (60-50-40)
    echo -e "\n【${SH_NAME}】待发布项目清单："
    ${FORMAT_TABLE_SH}  --delimeter '|'  --file ${WEB_PROJECT_LIST_FILE_TMP}
    #echo -e "\n"
fi



# go
> ${WEB_RELEASE_OK_LIST_FILE}
CHECK_COUNT=0
while read LINE
do
    # 跳过以#开头的行或空行
    [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
    #
    PJ=`echo $LINE | cut -f 2 -d \| `
    PJ=`echo $PJ`
    #
    MODE=`echo $LINE | cut -f 6 -d \| `
    MODE=`echo $MODE`
    #
    CHECK_COUNT=`expr ${CHECK_COUNT} + 1`
    #
    case "${WORK}" in
        release)
            WEB_ACTION='发布'
            #
            if [[ "$MODE" == 'proxyserver' ]]; then
                #printf  "%-32s  %s\n"  "${PJ}"   "无需发布或回滚"
                echo "${PJ} : 跳过，无需发布" >> ${WEB_RELEASE_OK_LIST_FILE}
                ERROR_CODE=56
                continue
            fi
            #
            > ${WEB_RELEASE_NGINX_OK_LIST_FILE}
            ansible ${ANSIBLE_HOST_FOR_LOGFILE} -m command -a "bash  ${NGINX_CONFIG_SH_HOME}/web-release-on-nginx.sh  --release  ${PJ}"  > ${WEB_RELEASE_NGINX_OK_LIST_FILE}    #--- 如果子命令返回值不是0，则ansible命令返回值为2
            if [[ $? -ne 0 ]]; then
                ERROR_CODE=5
                echo "${PJ} : 失败，OS级" >> ${WEB_RELEASE_OK_LIST_FILE}
            else
                # 例：
                # 192.168.11.77 | CHANGED | rc=0 >>
                # gc-h5-front      成功
                #
                sed -i '1d' ${WEB_RELEASE_NGINX_OK_LIST_FILE}
                while read LINE
                do
                    PJ=$(echo "$LINE" | awk '{printf $1}')
                    WEB_RELEASE_RESULT=$(echo "$LINE" | awk '{printf $2}')
                    echo "${PJ} : ${WEB_RELEASE_RESULT}" >> ${WEB_RELEASE_OK_LIST_FILE}
                done < "${WEB_RELEASE_NGINX_OK_LIST_FILE}"
            fi
            ;;
        rollback)
            WEB_ACTION='回滚'
            #
            if [[ "$MODE" == 'proxyserver' ]]; then
                #printf  "%-32s  %s\n"  "${PJ}"   "无需发布或回滚"
                echo "${PJ} : 跳过，无需回滚" >> ${WEB_RELEASE_OK_LIST_FILE}
                ERROR_CODE=56
                continue
            fi
            #
            > ${WEB_RELEASE_NGINX_OK_LIST_FILE}
            ansible ${ANSIBLE_HOST_FOR_LOGFILE} -m command -a "bash  ${NGINX_CONFIG_SH_HOME}/web-release-on-nginx.sh  --rollback  ${PJ}"  > ${WEB_RELEASE_NGINX_OK_LIST_FILE}
            if [[ $? -ne 0 ]]; then
                ERROR_CODE=5
                echo "${PJ} : 失败，OS级" >> ${WEB_RELEASE_OK_LIST_FILE}
            else
                #
                sed -i '1d' ${WEB_RELEASE_NGINX_OK_LIST_FILE}
                while read LINE
                do
                    PJ=$(echo "$LINE" | awk '{printf $1}')
                    WEB_RELEASE_RESULT=$(echo "$LINE" | awk '{printf $2}')
                    echo "${PJ} : ${WEB_RELEASE_RESULT}" >> ${WEB_RELEASE_OK_LIST_FILE}
                done < "${WEB_RELEASE_NGINX_OK_LIST_FILE}"
            fi
            ;;
    esac
done < "${WEB_PROJECT_LIST_FILE_TMP}"
echo -e "\n${WEB_ACTION}完成！\n"





# 输出结果
#
# web-release-on-nginx.sh:
# 0  56  "跳过，无需发布或回滚"
# 0  53  "失败，项目目录不存在"
# 0  50  "成功"
# 0  50  "成功*版本"
# 0  55  "跳过，今日无部署"
#
# web-release.sh:
# 56  "跳过，无需发布"
# 56  "跳过，无需回滚"
# 5   "失败，OS级"
#
SUCCESS_COUNT=`cat ${WEB_RELEASE_OK_LIST_FILE} | grep -o '成功' | wc -l`
ERROR_COUNT=`cat ${WEB_RELEASE_OK_LIST_FILE} | grep -o '失败' | wc -l`
NONEED_COUNT=`cat ${WEB_RELEASE_OK_LIST_FILE} | grep -o '跳过' | wc -l`
TIME_END=`date +%Y-%m-%dT%H:%M:%S`

case ${SH_RUN_MODE} in
    normal)
        #
        MESSAGE_END="WEB项目${WEB_ACTION}已完成！ 共企图${WEB_ACTION}${CHECK_COUNT}个项目，成功${WEB_ACTION}${SUCCESS_COUNT}个项目，跳过${NONEED_COUNT}个项目，${ERROR_COUNT}个项目出错。"
        # 消息回显拼接
        > ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        echo "干：**${GAN_WHAT_FUCK}**" | tee -a ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        echo "===== WEB 站点${WEB_ACTION}报告 =====" >> ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        echo -e "${ECHO_REPORT}========================== WEB 站点${WEB_ACTION}报告 ==========================${ECHO_CLOSE}"
        #
        echo "所在环境：${RUN_ENV}" | tee -a ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        echo "造 浪 者：${MY_USER_XINGMING}" | tee -a ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        echo "造浪账号：${MY_USER_NAME}@${USER_INFO_FROM}" | tee -a ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        echo "发送邮箱：${MY_USER_EMAIL}" | tee -a ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        echo "开始时间：${TIME}" | tee -a ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        echo "结束时间：${TIME_END}" | tee -a ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        echo "${WEB_ACTION}清单：" | tee -a ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        # 输出到文件
        echo "--------------------------------------------------" >> ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        cat  ${WEB_RELEASE_OK_LIST_FILE}            >> ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        echo "--------------------------------------------------" >> ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        # 输出屏幕
        ${FORMAT_TABLE_SH}  --delimeter ':'  --title "**项目名称**:**${WEB_ACTION}**"  --file ${WEB_RELEASE_OK_LIST_FILE}
        #
        F_TimeDiff  "${TIME_START}" "${TIME_END}" | tee -a ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        #
        echo "${MESSAGE_END}" >> ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        echo -e "${ECHO_REPORT}${MESSAGE_END}${ECHO_CLOSE}"
        # 保存历史
        cat ${WEB_RELEASE_HISTORY_CURRENT_FILE} >> ${FUCK_HISTORY_FILE}
        echo -e "\n\n\n"  >> ${FUCK_HISTORY_FILE}
        
        # markdown
        # 删除空行（以及只有tab、空格的行）
        sed -i '/^\s*$/d'  ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        t=1
        while read LINE
        do
            MSG[$t]=$LINE
            #echo ${MSG[$t]}
            let  t=$t+1
        done < ${WEB_RELEASE_HISTORY_CURRENT_FILE}
        ${DINGDING_MARKDOWN_PY}  "【Info:${LOLLIPOP_PLATFORM_NAME}:${RUN_ENV}】" "${MSG[@]}" > /dev/null
        ;;
    function)
        #
        if [ `cat ${WEB_RELEASE_OK_LIST_FILE} | wc -l` -eq 0 ]; then
            # 结果为空
            exit 59
        fi
        #
        cat  ${WEB_RELEASE_OK_LIST_FILE} > ${WEB_RELEASE_OK_LIST_FILE_function}
        #grep -q '成功' ${WEB_RELEASE_OK_LIST_FILE} >/dev/null 2>&1
        #exit $?
        exit ${ERROR_CODE}
        ;;
    *)
        echo -e "\n猪猪侠警告：这是你自己加的，请自行完善！\n"
        exit 51
        ;;
esac

