#!/bin/bash

# 用法：
F_HELP()
{
    echo "
    用途：安装pgBadger
    用法:
        $0 -h|--help
        $0 {-v <版本号>}          #--- 默认版本号：12.1
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
        -v             安装版本号，例如：12.1
    "
}


#
if [[ $# == 0 ]]; then
    echo -e "\n猪猪侠警告：请提供运行参数，请查看帮助【$0 --help】\n"
    exit 1
fi


case "$1" in
    "-h"|"--help")
        F_HELP
        exit 0
        ;;
    "-v")
        VER=${2:-12.1}
        ;;
    *)
        F_HELP
        echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
        exit 1
        ;;
esac


yum -y  install perl-JSON-XS  perl-Text-CSV_XS
yum -y  install perl-ExtUtils-MakeMaker


cd  /usr/local/src/
wget  https://github.com/darold/pgbadger/archive/refs/tags/v${VER}.tar.gz  -O pgbadger-v${VER}.tar.gz
tar zxf  pgbadger-v${VER}.tar.gz
cd  pgbadger-${VER}
perl Makefile.PL
make && sudo make install


