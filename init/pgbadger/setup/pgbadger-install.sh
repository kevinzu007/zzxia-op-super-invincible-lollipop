#!/bin/bash

# 用法：
F_HELP()
{
    echo "
    用途：安装pgBadger
    用法:
    sh $0 [-h|--help]
    sh $0 -v <版本号>          #--- 默认版本号：12.1
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


