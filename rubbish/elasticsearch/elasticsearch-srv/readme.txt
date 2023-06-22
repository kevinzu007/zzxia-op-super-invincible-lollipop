
数据目录权限必须设置为用户及组id为1000:1000
例如：
mkdir -p  data  conf
chown -R 1000:1000  ./data
chown -R 1000:1000  ./conf


