#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7

set -e
set -o


# 变量
TIME=`date +%Y-%m-%dT%H:%M%S`
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}
SQL_SCRIPT_BASE="${SH_PATH}/build"
SQL_SCRIPT_PROJECT="sql-release"

# env
. ${SH_PATH}/env.sh


# sql脚本版本如何管理：
# 在数据库中记录当前数据结构的版本
# 在仓库中存储数据结构所有的版本与个版本的sql脚本文件
# 根据数据库当前的数据结构版本及仓库中的版本历史，以及需要更新到的目标版本（或最新latest版本）按版本顺序执行数据结构脚本，并更新数据库数据结构版本信息
# 数据版本封板后禁止再次修改，只能在下个版本中更新
# 目录结构与分支:
# sql-release/release/1.0.180101   (stag|master)
#                     1.0.180102
#             prepare/1.1.xxx     (dev)
#
# .sql 文件名规范:
# 1-agent-anyname.sql
# 1-agent-anyname.sql.rollback
# 2-product-anyname2.sql
# 2-product-anyname2.sql.rollback
# 3-...
#
# 脚本设计：
# 1.获取db列表
# 2.根据版本差别，顺序执行sql脚本；更新数据结构版本号
# 2.按需要，根据版本差别，顺序执行sql回滚脚本；更新数据结构版本号


cd ${SQL_BASE}
git clone -b ${GIT_BRANCH} ${GIT_XXXX}
cd xxxx


# 用法：
F_HELP()
{
    echo "
    用法:
    sh $0 [-h|--help]
    sh $0 [--go|--rollback] <版本号>     #--- 所有数据库更新到latest版本
    sh $0 [--go|--rollback] [版本号] <数据库名>
    "
}


# 参数检查
if [ "x$1" != 'x' ]; then
    case "$1" in
        "-h"|"--help")
            F_HELP
            exit 0
            ;;
        "--go"|"--rollback")
            ;;
        *)
            F_HELP
            echo '骚年，请输入正确的脚本命令参数！'
            exit 1
            ;;
    esac
fi




#
./pg-sql-exec.sh [--go|--rollback]  $dir




