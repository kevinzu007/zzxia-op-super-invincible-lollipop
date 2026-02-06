#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7


TIME=`date +%Y-%m-%dT%H:%M%S`
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}

# 自动从/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh引入以下变量
#RUN_ENV=


# 用法：
F_HELP()
{
    echo "
    用法:
        bash $0  [-h|--help]
        bash $0  [-c|--copy<{运行环境>]    #-- 拷贝当前目录中以【---运行环境】结尾的文件到指定路径，【运行环境】如果没有指定，则从【/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh】中获取
    示例：
        $0  -h            #-- 帮助
        $0  -c            #-- 拷贝运行环境的文件到目标路径，默认从系统profile.d/中获取运行环境，如果不明白，建议手动指定，如：-cdev
        $0  -cdev         #-- 拷贝以【dev】运行环境的文件到目标路径
    "
}


F_CP ()
{
    # 配置文件清单路径
    MANIFEST_FILE="${SH_PATH}/cp-my_normal_envs.sh.list"
    if [[ ! -f "${MANIFEST_FILE}" ]]; then
        echo -e "\n猪猪侠警告：配置文件清单【${MANIFEST_FILE}】不存在！\n"
        exit 1
    fi

    echo -e "正在根据清单【${MANIFEST_FILE}】分发配置..."
    # 读取清单文件，忽略空行和注释
    grep -vE '^\s*#|^\s*$' "${MANIFEST_FILE}" | while read -r src_base dest_path_template; do
        # 1. 解析目标路径 (支持环境变量 ${DEST_DIR})
        eval dest_path="${dest_path_template}"
        # 2. 确定源文件 (优先找带后缀的，没有则找通用的)
        # 更新：后缀改为 --
        src_env="${src_base}--${R_ENV}"
        src_common="${src_base}"
        real_src=""
        if [[ -f "./${src_env}" ]]; then
            real_src="./${src_env}"
        elif [[ -f "./${src_common}" ]]; then
            real_src="./${src_common}"
        else
            echo "  [跳过] 找不到源文件: ${src_base} (检查了 ${src_env} 和 ${src_common})"
            continue
        fi
        # 3. 执行拷贝
        # 如果目标是以 / 结尾，则说明是目录，不用改名
        # 如果目标是文件路径，则覆盖
        if [[ "${dest_path}" == */ ]]; then
             mkdir -p "${dest_path}"
             cp -f "${real_src}" "${dest_path}"
             echo "  [拷贝] ${real_src} -> ${dest_path}"
        else
             # 确保目标文件的父目录存在
             mkdir -p "$(dirname "${dest_path}")"
             cp -f "${real_src}" "${dest_path}"
             echo "  [拷贝] ${real_src} -> ${dest_path}"
        fi
    done
}


# 参数检查
if [[ $# == 0 ]]; then
    echo -e "\n猪猪侠警告：请提供运行参数！\n"
    exit 1
fi
#
TEMP=`getopt -o hc::  -l help,copy:: -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
    F_HELP
    exit 51
fi
#
eval set -- "${TEMP}"


# 获取运行参数
R_MODE=''
while true
do
    case "$1" in
        "-h"|"--help")
            F_HELP
            exit
            ;;
        -c|--copy)
            # 如果没有指定，就从父进程获取
            R_ENV=${2:-${RUN_ENV}}
            shift 2
            if [[ -z ${R_ENV} ]]; then
                echo -e "\n猪猪侠警告：运行环境变量【\${R_ENV}】为空，请用命令行参数指定！\n"
                exit 1
            fi
            #
            # 获取【zzxia-op-super-invincible-lollipop|超级无敌棒棒糖】项目路径
            .  ./zzxia-op-super-invincible-lollipop.run-env.sh---${R_ENV}
            DEST_DIR=${ZZXIA_OP_SUPER_INVINCIBLE_LOLLIPOP_HOME}
            if [[ ! -f ${DEST_DIR}/gan.sh ]]; then
                echo -e "\n猪猪侠警告：配置文件【./zzxia-op-super-invincible-lollipop.run-env.sh---${R_ENV}】中指定的项目路径参数【ZZXIA_OP_SUPER_INVINCIBLE_LOLLIPOP_HOME】有误，请检查\n"
                exit 1
            fi
            #
            F_CP
            #
            echo -e "\n猪猪侠警告：请重新登录以使【/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh】中的变量生效！\n"
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


