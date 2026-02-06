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
# 检测 MY_PRIVATE_ENVS_DIR 是否存在，不存在则主动加载环境变量（非终端界面不会自动引入）
if [ -z "${RUN_ENV}" ]; then
    if [ -f /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh ]; then
        . /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
    else
        echo -e "\n猪猪侠警告：缺少环境变量文件：/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh\n"
        echo "请在 deploy 服务器上安装/配置该文件，并确保所有必要变量可用。"
        echo
        exit 52
    fi
fi

# 引入env.sh
. ${SH_PATH}/env.sh

# 本地env
GAN_WHAT_FUCK='User_Manage'
NEED_PRIVILEGES='ADMIN'                   #-- 运行此程序需要的权限
TIME=${TIME:-`date +%Y-%m-%dT%H:%M:%S`}

FORMAT_TABLE_SH="${SH_PATH}/../tools/format_table.sh"

# 引入函数
.  ${SH_PATH}/function.sh


# 必要文件检查
if [[ -n "${MY_PRIVATE_ENVS_DIR}" ]]; then
    USER_DB_FILE=${USER_DB_FILE:-"${MY_PRIVATE_ENVS_DIR}/user.db"}
    USER_DB_FILE_APPEND_1=${USER_DB_FILE_APPEND_1:-"${MY_PRIVATE_ENVS_DIR}/user.db.append.1"}
fi

if [[ ! -f "${USER_DB_FILE}" ]]; then
    echo -e "\n猪猪侠警告：用户数据库文件不存在：${USER_DB_FILE}\n"
    exit 52
fi

if [[ ! -f "${USER_DB_FILE_APPEND_1}" ]]; then
    echo -e "\n猪猪侠警告：用户权限扩展文件不存在：${USER_DB_FILE_APPEND_1}\n"
    exit 52
fi


# 用法：
F_HELP()
{
    echo "
    用途：统一管理用户信息和更新密码
    特征码：
        ${GAN_WHAT_FUCK:-'未命名'}
    权限要求：
        ${NEED_PRIVILEGES:-'未指定'}
    依赖：
        ${USER_DB_FILE}
        ${USER_DB_FILE_APPEND_1}
        ${FORMAT_TABLE_SH}
    注意：
        * 添加或修改用户时，请确保 USER_ID 和 USER_NAME 的唯一性
        * 更新密码会重新生成随机盐
    用法:
        $0  -h|--help
        $0  -l|--list
        $0  -a|--add      <用户名>
        $0  -u|--update   <用户名>
        $0  -d|--delete   <用户名>
        $0  -p|--password <用户名>
    参数规范：
        无包围符号 ：-a                : 必选【选项】
                   ：val               : 必选【参数值】
                   ：val1 val2 -a -b   : 必选【选项或参数值】，且不分先后顺序
        []         ：[-a]              : 可选【选项】
                   ：[val]             : 可选【参数值】
        <>         ：<val>             : 需替换的具体值（用户必须提供）
        %%         ：%val%             : 通配符（包含匹配，如%error%匹配error_code）
        |          ：val1|val2|<valn>  : 多选一
        {}         ：{-a <val>}        : 必须成组出现【选项+参数值】
                   ：{val1 val2}       : 必须成组的【参数值组合】，且必须按顺序提供
    参数说明：
        -h|--help      此帮助
        -l|--list      用户列表
        -a|--add       添加用户（基本信息）
        -u|--update    更新用户信息（姓名、邮箱、备注）
        -d|--delete    删除用户
        -p|--password  更新/重置用户密码
        --print-priv-rule 打印用户权限定义说明
    示例:
        $0  -l                 #--- 列出所有用户
        $0  --print-priv-rule  #--- 打印权限定义说明
        $0  -a  jack           #--- 添加用户 jack
        $0  -u  jack           #--- 更新 jack 的基本信息
        $0  -p  jack           #--- 更新 jack 的密码
        $0  -d  jack           #--- 删除用户 jack
    "
}

# 权限定义说明
F_PRIVILEGE_INFO()
{
    echo "
# 用户权限定义说明：
# ---------------------------------------------------------------------------------------------------
###    权限定义：
###     【用户权限：USER_PRIVILEGES】= [ 运行环境1:权限1, 运行环境2:权限1 & 权限2 & ......, 运行环境n:...... ]
###      定义用户在指定运行环境下的权限，多个运行环境之间用逗号分隔，多个权限之间用&分隔
###    参数解释：
###      * 运行环境   1 ALL         : 代表所有运行环境
###                   2 自定义名称  : 代表指定名称的运行环境，比如：dev、prod等
###      * 权限       1 ADMIN|ALL   : 代表所有权限，权限包括不限于：ADMIN、build、deploy、gan、......
###                   2 build       : 构建权限，即fuckingdoit目录下匹配 ^build*.sh 的shell脚本
###                   3 deploy      : 部署发布权限，即fuckingdoit目录下不匹配 ^build*.sh 的shell脚本
###                   4 gan         : 运行gan.sh权限
###    示例：
###      【ALL:ADMIN】              : 代表在所有运行环境具有全部权限
###      【ALL:build】              : 代表在所有运行环境具有build权限
###      【dev:ALL, prod:build】    : 代表在dev运行环境具有全部权限，在prod运行环境具有build权限
###      【dev:build&deploy】       : 代表在dev运行环境具有build及deploy权限
###      【dev:gan】                : 代表在dev运行环境具有gan权限
# ---------------------------------------------------------------------------------------------------
    "
}

# 列表展示
F_LIST()
{
    echo -e "\n【当前用户信息清单】"
    # 临时文件
    local USER_DB_FILE_TMP="/tmp/${SH_NAME}-user.list.tmp"
    local USER_DB_APPEND_FILE_TMP="/tmp/${SH_NAME}-user.append.list.tmp"
    
    # 1. 展示基本信息 (user.db)
    echo -e "\n1. 基本信息 (user.db)"
    sed -E -e '/^\s*$/d' -e '/^#.*$/d' "${USER_DB_FILE}" > "${USER_DB_FILE_TMP}"
    ${FORMAT_TABLE_SH} --delimeter '|' --title "#| **用户ID** | **用户名** | **姓名** | **E-MAIL** | **盐** | **密码** | **备注** |" --file "${USER_DB_FILE_TMP}"
    
    # 2. 展示权限信息 (user.db.append.1)
    echo -e "\n2. 权限信息 (user.db.append.1)"
    sed -E -e '/^\s*$/d' -e '/^#.*$/d' "${USER_DB_FILE_APPEND_1}" > "${USER_DB_APPEND_FILE_TMP}"
    ${FORMAT_TABLE_SH} --delimeter '|' --title "#| **用户ID** | **用户名** | **Gitlab用户名** | **用户权限** |" --file "${USER_DB_APPEND_FILE_TMP}"
}

# 更新密码逻辑
F_UPDATE_PASSWORD()
{
    local USER_NAME=$1
    if [[ -z "${USER_NAME}" ]]; then
        echo "错误：未指定用户名。"
        return 1
    fi

    # 检查用户是否存在 (精确匹配数据行)
    grep -q -E "^\|[ ]*[0-9]+[ ]*\|[ ]*${USER_NAME}[ ]*\|" "${USER_DB_FILE}"
    if [[ $? -ne 0 ]]; then
        echo -e "\n猪猪侠警告：用户【${USER_NAME}】不存在！\n"
        return 1
    fi

    read  -s -p "请输入用户【${USER_NAME}】新密码："  USER_PASSWORD
    echo
    read  -s -p "请再次输入新密码："  USER_PASSWORD_2
    echo
    if [[ ${USER_PASSWORD} != ${USER_PASSWORD_2} ]]; then
        echo -e  "\n猪猪侠警告：两次输入的密码不一致！\n"
        return 1
    fi

    # secret logic
    local USER_SALT=$(echo ${RANDOM} | md5sum | cut -c 1-10)
    local USER_SECRET_sha1=$(echo -n "${USER_NAME}${USER_PASSWORD}" | sha1sum | awk '{print $1}')
    local USER_SECRET_sha1_30=${USER_SECRET_sha1:2:30}
    local USER_SECRET_sha256=$(echo -n "${USER_SALT}${USER_SECRET_sha1_30}" | sha256sum | awk '{print $1}')
    local USER_SECRET_sha256_50=${USER_SECRET_sha256:3:50}
    local USER_SECRET=${USER_SECRET_sha256_50}

    # 更新 user.db 中的盐和密码
    sed -i -E "s/^([|][ ]*[0-9]+[ ]*[|][ ]*${USER_NAME}[ ]*[|][^|]+[|][^|]+[|])[^|]+[|][^|]+[|]([^|]+[|])$/\1 ${USER_SALT} | ${USER_SECRET} |\2/" "${USER_DB_FILE}"
    
    if [[ $? -eq 0 ]]; then
        echo -e "\n猪猪侠提醒：用户【${USER_NAME}】密码更新成功。\n"
    else
        echo -e "\n猪猪侠警告：密码更新失败。\n"
    fi
}

# 添加用户
F_ADD_USER()
{
    local USER_NAME=$1
    if [[ -z "${USER_NAME}" ]]; then
        echo "错误：未指定用户名。"
        return 1
    fi

    # 检查重名 (精确匹配，忽略表头)
    local GET_IT='N'
    while read LINE
    do
        [[ "$LINE" =~ ^# ]] || [[ "$LINE" =~ ^[\ ]*$ ]] && continue
        F_UN=`echo $LINE | awk -F '|' '{print $3}' | awk '{print $1}'`
        if [[ "${F_UN}" == "${USER_NAME}" ]]; then
            GET_IT='YES'
            break
        fi
    done < "${USER_DB_FILE}"

    if [[ ${GET_IT} == 'YES' ]]; then
        echo -e "\n猪猪侠警告：用户【${USER_NAME}】已存在！\n"
        return 1
    fi

    # 获取最大的 ID
    local MAX_ID=$(grep -E '^[ ]*\|' "${USER_DB_FILE}" | awk -F '|' '{print $2}' | sort -rn | head -n 1)
    local NEW_ID=$((MAX_ID + 1))

    echo "正在为用户【${USER_NAME}】(ID: ${NEW_ID}) 录入基本信息："
    read -p "请输入姓名 (USER_XINGMING): " USER_XINGMING
    read -p "请输入邮箱 (USER_EMAIL): " USER_EMAIL
    read -p "请输入备注 (NOTE): " USER_NOTE
    read -p "请输入Gitlab用户名 (GITLAB_USER_NAME): " GITLAB_USER_NAME
    read -p "请输入用户权限 (USER_PRIVILEGES, e.g. dev:ALL): " USER_PRIVILEGES

    # 写入 user.db
    echo "| ${NEW_ID}        | ${USER_NAME}     | ${USER_XINGMING}        | ${USER_EMAIL}               |            |                                                    | ${USER_NOTE}             |" >> "${USER_DB_FILE}"
    
    # 写入 user.db.append.1
    echo "| ${NEW_ID}        | ${USER_NAME}     | ${GITLAB_USER_NAME}            | ${USER_PRIVILEGES}                                     |" >> "${USER_DB_FILE_APPEND_1}"

    echo -e "\n猪猪侠提醒：用户【${USER_NAME}】基本信息已创建，请继续使用 -p 参数设置其密码。\n"
}

# 更新基本信息
F_UPDATE_INFO()
{
    local USER_NAME=$1
    if [[ -z "${USER_NAME}" ]]; then
        echo "错误：未指定用户名。"
        return 1
    fi

    # 1. 检查 user.db 并在其中提取当前信息
    local USER_LINE=$(grep -E "^\|[ ]*[0-9]+[ ]*\|[ ]*${USER_NAME}[ ]*\|" "${USER_DB_FILE}")
    if [[ -z "${USER_LINE}" ]]; then
        echo -e "\n猪猪侠警告：用户【${USER_NAME}】不存在！\n"
        return 1
    fi

    local CUR_XINGMING=$(echo "${USER_LINE}" | awk -F '|' '{print $4}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    local CUR_EMAIL=$(echo "${USER_LINE}" | awk -F '|' '{print $5}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    local CUR_NOTE=$(echo "${USER_LINE}" | awk -F '|' '{print $8}' | sed 's/^[ \t]*//;s/[ \t]*$//')

    # 2. 检查 user.db.append.1 并提取信息
    local USER_LINE_APP=$(grep -E "^\|[ ]*[0-9]+[ ]*\|[ ]*${USER_NAME}[ ]*\|" "${USER_DB_FILE_APPEND_1}")
    local CUR_GITLAB_USER_NAME=""
    local CUR_USER_PRIVILEGES=""
    if [[ -n "${USER_LINE_APP}" ]]; then
        CUR_GITLAB_USER_NAME=$(echo "${USER_LINE_APP}" | awk -F '|' '{print $4}' | sed 's/^[ \t]*//;s/[ \t]*$//')
        CUR_USER_PRIVILEGES=$(echo "${USER_LINE_APP}" | awk -F '|' '{print $5}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    fi

    echo "正在更新用户【${USER_NAME}】的信息 (直接回车表示保持当前值)："
    
    read -p "姓名 (USER_XINGMING) [当前: ${CUR_XINGMING}]: " USER_XINGMING
    USER_XINGMING=${USER_XINGMING:-"${CUR_XINGMING}"}
    
    read -p "邮箱 (USER_EMAIL) [当前: ${CUR_EMAIL}]: " USER_EMAIL
    USER_EMAIL=${USER_EMAIL:-"${CUR_EMAIL}"}
    
    read -p "备注 (NOTE) [当前: ${CUR_NOTE}]: " USER_NOTE
    USER_NOTE=${USER_NOTE:-"${CUR_NOTE}"}

    read -p "Gitlab用户名 (GITLAB_USER_NAME) [当前: ${CUR_GITLAB_USER_NAME}]: " GITLAB_USER_NAME
    GITLAB_USER_NAME=${GITLAB_USER_NAME:-"${CUR_GITLAB_USER_NAME}"}

    read -p "用户权限 (USER_PRIVILEGES) [当前: ${CUR_USER_PRIVILEGES}]: " USER_PRIVILEGES
    USER_PRIVILEGES=${USER_PRIVILEGES:-"${CUR_USER_PRIVILEGES}"}
    
    # 更新 user.db
    if [[ -n "${USER_XINGMING}" ]]; then
        sed -i -E "s/^([|][^|]+[|][ ]*${USER_NAME}[ ]*[|])[^|]+([|][^|]+[|][^|]+[|][^|]+[|][^|]+[|])/\1 ${USER_XINGMING} \2/" "${USER_DB_FILE}"
    fi
    if [[ -n "${USER_EMAIL}" ]]; then
        sed -i -E "s/^([|][^|]+[|][ ]*${USER_NAME}[ ]*[|][^|]+[|])[^|]+([|][^|]+[|][^|]+[|][^|]+[|])/\1 ${USER_EMAIL} \2/" "${USER_DB_FILE}"
    fi
    if [[ -n "${USER_NOTE}" ]]; then
        sed -i -E "s/^([|][^|]+[|][ ]*${USER_NAME}[ ]*[|][^|]+[|][^|]+[|][^|]+[|][^|]+[|])[^|]+([|])$/\1 ${USER_NOTE} \2/" "${USER_DB_FILE}"
    fi

    # 更新 user.db.append.1
    if [[ -n "${USER_LINE_APP}" ]]; then
        if [[ -n "${GITLAB_USER_NAME}" ]]; then
            sed -i -E "s/^([|][^|]+[|][ ]*${USER_NAME}[ ]*[|])[^|]+([|][^|]+[|])/\1 ${GITLAB_USER_NAME} \2/" "${USER_DB_FILE_APPEND_1}"
        fi
        if [[ -n "${USER_PRIVILEGES}" ]]; then
            sed -i -E "s/^([|][^|]+[|][ ]*${USER_NAME}[ ]*[|][^|]+[|])[^|]+([|])/\1 ${USER_PRIVILEGES} \2/" "${USER_DB_FILE_APPEND_1}"
        fi
    fi

    echo -e "\n猪猪侠提醒：用户【${USER_NAME}】信息更新成功。\n"
}

# 删除用户
F_DELETE_USER()
{
    local USER_NAME=$1
    if [[ -z "${USER_NAME}" ]]; then
        echo "错误：未指定用户名。"
        return 1
    fi

    # 检查用户是否存在 (精确匹配数据行)
    grep -q -E "^\|[ ]*[0-9]+[ ]*\|[ ]*${USER_NAME}[ ]*\|" "${USER_DB_FILE}"
    if [[ $? -ne 0 ]]; then
        echo -e "\n猪猪侠警告：用户【${USER_NAME}】不存在！\n"
        return 1
    fi

    # 询问确认
    read -p "确定要删除用户【${USER_NAME}】吗？(y/n): " CONFIRM
    if [[ "${CONFIRM}" != "y" ]]; then
        echo "操作已取消。"
        return 0
    fi

    sed -i -E "/^[|][ ]*[0-9]+[ ]*[|][ ]*${USER_NAME}[ ]*[|]/d" "${USER_DB_FILE}"
    sed -i -E "/^[|][ ]*[0-9]+[ ]*[|][ ]*${USER_NAME}[ ]*[|]/d" "${USER_DB_FILE_APPEND_1}"

    echo -e "\n猪猪侠提醒：用户【${USER_NAME}】已从数据库中移除。\n"
}

# 参数检查
TEMP=`getopt -o hlau:d:p:  -l help,list,add,update:,delete:,password:,print-priv-rule -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    exit 51
fi
eval set -- "${TEMP}"

# 获取参数
while true
do
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -l|--list)
            F_LIST
            exit
            ;;
        --print-priv-rule)
            F_PRIVILEGE_INFO
            exit
            ;;
        -a|--add)
            WORK='add'
            shift
            ;;
        -u|--update)
            WORK='update'
            TARGET_USER=$2
            shift 2
            ;;
        -d|--delete)
            WORK='delete'
            TARGET_USER=$2
            shift 2
            ;;
        -p|--password)
            WORK='password'
            TARGET_USER=$2
            shift 2
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

# 如果指定了 -a 但没跟 TARGET_USER，从剩余参数取
if [[ "${WORK}" == "add" ]] && [[ -z "${TARGET_USER}" ]]; then
    TARGET_USER=$1
    shift
fi

# 来自webhook或父shell
export HOOK_USER_INFO_FROM
export HOOK_GAN_ENV
export HOOK_USER_NAME
export HOOK_USER_XINGMING
export HOOK_USER_EMAIL

if [[ -z ${USER_INFO_FROM} ]]; then
    USER_INFO_FROM=${HOOK_USER_INFO_FROM:-'local'}     #--【local|hook_hand|hook_gitlab】，默认：local
fi

# 检查权限
F_get_user_info
F_check_user_priv

# 执行任务
case "${WORK}" in
    list)
        F_LIST
        ;;
    add)
        if [[ -z "${TARGET_USER}" ]]; then
            echo "错误：请提供用户名。"
            exit 51
        fi
        F_ADD_USER "${TARGET_USER}"
        ;;
    update)
        F_UPDATE_INFO "${TARGET_USER}"
        ;;
    delete)
        F_DELETE_USER "${TARGET_USER}"
        ;;
    password)
        F_UPDATE_PASSWORD "${TARGET_USER}"
        ;;
    *)
        if [[ $# -eq 0 && -z "${WORK}" ]]; then
            F_HELP
        else
            echo -e "\n猪猪侠警告：请指定具体操作类型！\n"
            exit 51
        fi
        ;;
esac
