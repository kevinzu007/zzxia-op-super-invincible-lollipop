

# nexus
mkdir -p  /srv/docker/nexus
cd    /srv/docker/nexus
mkdir  nexus-data && chown -R 200 ./nexus-data


# docker-compose.yml


# 浏览器
http://ip:8081
设置repo及密码（默认密码admin/admin123）
admin/1234567890


# 配置需要在浏览器上设置
#-----------------------------------------------
# blob:

my-mvn-snapshots-repo
my-mvn-releases-repo
my-npm-repo


# repo:
## mvn

mvn-aliyun
proxy
http://maven.aliyun.com/nexus/content/groups/public/

mvn-adobe
proxy
https://repo.adobe.com/nexus/content/repositories/public/

my-mvn-releases
hosted
my-mvn-releases-repo
redeploy

my-mvn-snapshots
hosted
my-mvn-snapshots-repo
redeploy

my-mvn-group
group


## npm
npm-taobao
proxy
https://registry.npm.taobao.org

my-npm
hosted
my-npm-repo
redeploy

my-npm-group
group







