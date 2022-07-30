

# docker_registry
# https://yq.aliyun.com/articles/57310

# 目录
mkdir -p /srv/docker/docker_registry
cd  /srv/docker/docker_registry
mkdir  auth data certs

# 生成passwd
yum install -y  httpd-tools
htpasswd -Bbn ufipf 123456 > auth/htpasswd

# docker-compose.yml


浏览器：
http://docker-repo:5000/v2/_catalog
ufipf
123456

# shell
curl -u ufipf:123456  -X GET http://docker-repo:5000/v2/_catalog
curl -u ufipf:123456  -X GET http://docker-repo:5000/v2/test/neo4j/tags/list


#docker save lzqs/deploy:1.0 > deploy.tar
#docker load                 < deploy.tar



