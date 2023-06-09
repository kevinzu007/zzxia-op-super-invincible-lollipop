#!/bin/bash


# 用法：
F_HELP()
{
    echo "
    用途：安装世界上最牛B的数据库：PostGreSQL
    用法:
    sh $0 [-h|--help]
    sh $0 -v <版本号>          #--- 默认版本号：14.6
    "
}


#
if [[ $# == 0 ]]; then
    echo -e "\n猪猪侠警告：请提供运行参数，请查看帮助【$0 --help】\n"
    F_HELP
    exit 1
fi


case "$1" in
    "-h"|"--help")
        F_HELP
        exit 0
        ;;
    "-v")
        VER=${2:-14.6}
        ;;
    *)
        F_HELP
        echo -e "\n猪猪侠警告：参数不合法，请查看帮助【$0 --help】\n"
        exit 1
        ;;
esac



yum install -y  gcc readline-devel  zlib-devel  bison  flex

# stop
ps -ef | grep -v grep | grep /usr/local/pgsql/bin/postmaster >/dev/null 2>&1
if [ $? = 0 ]; then
    echo "正在停止PostGreSQL"
    /root/postgresql_daemon.sh stop
    echo "停止PostGreSQL ... OK"
fi


# check
if [ -d /usr/local/pgsql-${VER} ]; then
    echo "/usr/local/pgsql-${VER}目录已存在，当前pg版本已安装，已退出！"
    exit 1
fi

# download
cd /usr/local/src

[ -e postgresql-${VER}.tar.gz ] || wget https://ftp.postgresql.org/pub/source/v${VER}/postgresql-${VER}.tar.gz  -P ./

if [ $? != 0 ]; then
    echo "https://ftp.postgresql.org/pub/source/v${VER}/postgresql-${VER}.tar.gz 文件下载失败，请检查"
    exit 1
fi

[ -e postgresql-${VER} ] && mv postgresql-${VER}  postgresql-${VER}---`date +%Y%m%dT%H%M%S`
tar zxf postgresql-${VER}.tar.gz
if [ $? != 0 ]; then
    echo "postgresql-${VER}.tar.gz解压出错，请检查！"
    exit 1
fi


# install
set -e
cd postgresql-${VER}/
./configure --prefix=/usr/local/pgsql-${VER}
make
make install
#
# 安装扩展
cd  contrib/
cd  pgstattuple
make
make install
cd  ../pg_buffercache
make
make install
cd  ../pg_stat_statements
make
make install
cd ../../
set +e


# link
[ -h /usr/local/pgsql ] && rm -f /usr/local/pgsql
[ -e /usr/local/pgsql ] && echo "/usr/local/pgsql已存在，创建软连接失败，请检查！" && exit 1
ln -s /usr/local/pgsql-${VER} /usr/local/pgsql

# init
grep 'postgres' /etc/passwd >/dev/null 2>&1 || adduser postgres
mkdir /usr/local/pgsql/data
chown -R postgres:postgres /usr/local/pgsql/data
cp  ./contrib/start-scripts/linux  /root/postgresql_daemon.sh
chmod +x /root/postgresql_daemon.sh
su - postgres -c "/usr/local/pgsql/bin/initdb  -D /usr/local/pgsql/data -E UTF8 --local=C"
su - postgres -c "/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l logfile start"
mkdir /usr/local/pgsql/data/conf.d
chown -R postgres:postgres /usr/local/pgsql/data
su - postgres -c "sed -i '/^include_dir/d' /usr/local/pgsql/data/postgresql.conf ;  echo include_dir = \'./conf.d\' >> /usr/local/pgsql/data/postgresql.conf"


# os env
[ -e /etc/profile.d/pg-env.sh ] || ( echo 'PATH="/usr/local/pgsql/bin:$PATH"' > /etc/profile.d/pg-env.sh )

# start
grep '^/root/postgresql_daemon.sh' /etc/rc.local  >/dev/null 2>&1 || (chmod +x /etc/rc.local ; echo '/root/postgresql_daemon.sh  start' | tee -a /etc/rc.local)



