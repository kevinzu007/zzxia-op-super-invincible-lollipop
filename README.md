# zzxia-op-super-invincible-lollipop

中文名：猪猪侠之运维超级无敌棒棒糖

## 1 介绍

这是一套集环境搭建，项目构建、部署、发布及周边的运维工具箱。适用docker集群（k8s、swarm、docker-compose）及Web站点等项目发布，支持灰度、扩缩容与回滚。这些工具也可以独立使用，比如项目构建、部署发布、Webhook server、dns修改、服务器登录异常警报、数据库备份归档与还原、表格绘制、申请与续签（泛）域名证书等等，具体参考帮助。**如果你在使用中遇到任何问题请在Issues中提出，或留下联系方式线下沟通。**



### 1.1 特点

- 项目构建：可以指定构建方法、输出方法、一键发布方式等（也可以使用自带的python钩子程序或Jenkins等外部钩子程序调用脚本实现自动化构建发布）。

- 发布环境：支持多种docker容器编排：k8s、swarm、docker-compose（市面主流工具只支持k8s）；支持多种集群与多集群并存；支持目录式发布，例如nginx等。

- 项目发布：可以指定发布相关的所有参数与变量，这个参数变量可以是全局的，也可以是某一项目专有的，这里包括但不限于服务运行参数、变量、端口、副本数、Java运行参数变量，容器变量、容器启动命令参数，命名空间 、主机名等。只需要修改项目发布清单就可以搞定所有项目，方便快捷（不同于一般系统那种每个项目都是一个独立配置文件，难以批量修改，与主流helm工具大相径庭，俗话说：不是同一个科技树）。

- 多环境统一配置，极大降低环境差异造成的参数差异隐患。

- 所有微服务在同一个表格中完成配置，非常方便对比差异与增加，和主流helm使用了完全相反的实现理念。

- 结果输出界面美观清晰，有表格及颜色区分，也包含耗时、进度条与邮箱手机消息通知。

- 标准化错误输出，通过错误消息及代码，可以轻松知道问题所在。

- shell语言，模块化编码，使得每个人可以轻松的增加自己的专属功能。shell语言还带来的好处是极少存在版本升级带来的运行异常问题，也不挑Linux版本（极少功能使用Python实现）。




### 1.2 适用条件

- 适用于基于微服务docker集群架构与或nginx前端。主要提供java、node语言类别项目（其他语言项目也可以，只需添加相关语言模块即可，这很简单，只是构建命令不一样而已，其他大同小异）。
- 特别适用于的中小团队，脚本命令使用超简单，可以实现你想要的任意构建与发布要求，帮助齐全，也可以把这些代码集成到你的CI/CD中（比如Jenkins），实现标准化管理，对于大团队也可以轻松嵌入到现有CI/CD系统中。
- 从开发层面：使用不固定分支发布代码，使用高度可选择的发布项目、发布时间、发布参数，比如：随意发布某项目、某分支、跳过测试、无更新强制发布、构建日志与结果通知方式、开发自助等。也可以一个简且短的命令对所有项目进行检查更新与构建发布。日常常规使用只需根据自己设置的默认参数构建发布，构建发布命令非常简短，无需输入命令参数。
- 从CI/CD层面：可能很多团队在使用Jenkins或gitlab等实现全自动构建发布或手动选择项目及参数进行构建与发布，如果你在使用全自动化方式（大团队标配），则建议你保持，无需考虑使用本项目（当然：也可以把此项目嵌入到你的流水线系统，这样不需要自己写发布代码）；如果你没有实现全自动化，而是让开发人员在网页上用鼠标点选项目与参数实现构建发布，则强烈建议使用本项目。我们知道，在微服务架构下，随便都是几十上百，甚至几百上千的项目，如果没有全自动化，在网页上点击要发布的项目真是折磨，这比使用本项目脚本发布会慢很多很多，时间就是头发。另外：即便你在开发测试环境使用全自动化构建发布，但在生产环境也较少使用全自动化发布，仍然需要手动发布或触发发布，那么你嵌入此项目将是一个不错的选择。使用此项目，初期开发人员可能会根据过往经验抵触这种发布方式，当他们用久了就会喜欢上这种发布方式，因为这种掌控感会让他们欲罢不能。
- 从运维层面：通过脚本初始化环境，无需手动进行，添加新项目时，只需维护envs中的清单及相关定制化变量即可，无需大动干戈。可能有些人喜欢一个项目维护一个或几个静态配置文件，如果有多个项目需要修改时，就需要修改一大批文件，这会很低效，而在这里，把所有项目参数都集中项目清单中（表格），只需要修改两三个个配置文清单文件即可，开发人员可以自行完成构建发布（开发测试环境），无需运维在场，构建发布一条命令搞定，消息自动提醒，发布态势运维可随时掌控，省心省力。另外shell脚本不像其他，运维人都会shell语言编程，可以根据自己的需要定制，而且这些脚本都是模块化的，而且关键点都有注释，自己修改也很容易。一切尽在掌握，这是运维人的终极追求，不是吗？



### 1.3 功能

- 环境搭建：这个对于每个公司可能会有所不同，但大同小异，自己调整或用其他方式搭建。
- 参数初始化：初始化环境，为构建发布做准备。
- nginx项目配置初始化：根据参数文件初始化项目目录、配置文件(http|https、端口、运行方式、后端端口、附加配置等)，自动添加修改域名A记录，自动申请https证书（我放在集群外，也可以放在集群内）
- 项目构建：对Java、Node、Dockerfile等项目进行构建打包，提供了丰富的构建参数供选择，比如：并行、分支、静默、强制、测试、（代码审查）、邮件、钉钉、微信
- 项目发布docker-service：提供列表、创建、删除、回滚、更新、缩扩容、镜像版本、状态、明细等功能
- 项目发布nginx：提供项目列表、发布上线、项目回滚
- 项目构建发布：一键构建发布功能，提供有丰富参数选择，但默认也是最好的选择


### 1.4 喜欢她，就满足她：

1. 【Star】她，让她看到你是爱她的；
2. 【Watching】她，时刻感知她的动态；
2. 【Fork】她，为她增加新功能，修Bug，让她更加卡哇伊；
3. 【Issue】她，告诉她有哪些小脾气，她会改的，手动小绵羊；
4. 【打赏】她，为她买jk；
<img src="https://gitee.com/zhf_sy/pic-bed/raw/master/dao.png" alt="打赏" style="zoom:40%;" />



## 2 软件架构

### 2.1 代码语言
- Linux shell

- Python

  

### 2.2 关系图



### 2.3 功能与依赖



#### 2.3.1 构建工具（build.sh；build-parallel.sh；gogogo.sh）

| 序号 | 类别       | 构建方法            | 输出方法           | 必要软件环境                                |
| :--: | ---------- | ------------------- | ------------------ | ------------------------------------------- |
|  1   | product    | NONE                | NONE               |                                             |
|  2   |            |                     | docker_image_push  | docker；docker仓库                          |
|  3   | Dockerfile | docker_build        | NONE               | docker                                      |
|  4   |            |                     | docker_image_push  | docker；docker仓库                          |
|  5   | Java       | mvn_package或gradle | NONE               | java_jdk；maven或gradle                     |
|  6   |            |                     | deploy_war         | java_jdk；maven或gradle                     |
|  7   |            |                     | deploy_jar_to_repo | java_jdk；maven或gradle；maven仓库          |
|  8   |            |                     | docker_image_push  | java_jdk；maven或gradle；docker；docker仓库 |
|  9   | Node       | npm_install         | NONE               | node；npm                                   |
|  10  |            |                     | docker_image_push  | node；npm；docker；docker仓库               |
|  11  |            | npm_build           | direct_deploy      | node；npm                                   |
|  12  |            |                     | docker_image_push  | node；npm；docker；docker仓库               |
|  13  | 自定义     | 自定义              | 自定义             | 自定义                                      |

> **`gogogo.sh`是自动化构建+发布工具**



#### 2.3.2 发布工具（docker-cluster-service-deploy.sh；web-release.sh；gogogo.sh）

| 序号 | 类别                             | 部署类型                  | 必要软件环境                                               |
| :--: | -------------------------------- | ------------------------- | ---------------------------------------------------------- |
|  1   | docker-cluster-service-deploy.sh | swarm                     | docker；swarm                                              |
|  2   |                                  | k8s                       | docker；k8s                                                |
|  3   |                                  | docker-compose            | docker；docker-compose                                     |
|  4   | web-release.sh                   | nginx或其他web服务器      | nginx或其他web服务器                                       |
|  5   | gogogo.sh                        | 上面所有类型（构建+发布） | build.sh；docker-cluster-service-deploy.sh；web-release.sh |



#### 2.3.3 其他工具

| 序号 | 脚本                                          | 用途                              | 必要软件环境                             |
| :--: | --------------------------------------------- | --------------------------------- | ---------------------------------------- |
|  1   | deploy/docker-image-search.sh                 | 从私有docker仓库搜索docker镜像    | docker；docker仓库                       |
|  2   | deploy/docker-tag-push.sh                     | 推送docker镜像到私有docker仓库    | docker；docker仓库                       |
|  3   | op/aliyun-dns.sh                              | 用阿里云dns做解析的域名修改工具   | 阿里云CLI；阿里云dns                     |
|  4   | op/godaddy-dns.sh                             | 用Godaddy dns做解析的域名修改工具 | curl；godaddy                            |
|  5   | op/cert-letsencrypt-wildcart.sh               | 在Let'sencrypt上申请泛域名证书    | certbot                                  |
|  6   | op/send_mail.sh                               | 发送邮件                          | mailx；邮件服务器账号                    |
|  7   | op/dingding_conver_to_markdown_list-deploy.py | 发送钉钉消息                      | python；钉钉机器人                       |
|  8   | op/format_table.sh                            | 格式化表格                        | awk                                      |
|  9   | op/draw_table.sh                              | 严格格式化表格                    | awk                                      |
|  10  | init/1-sshkey-copy.sh                         | 免密登录                          | sshpass                                  |
|  11  | init/send_login_alert_msg.sh                  | 发送用户登录警报消息              | python；钉钉机器人                       |
|  12  | init/send_mail_attach_my_log.sh               | 发送自定义日志到邮箱              | mailx；邮件服务器账号                    |
|  13  | init/nginx-config/nginx-cert-letsencrypt-a.sh | 在Let'sencrypt上申请A域名证书     | certbot；nginx                           |
|  14  | init/nginx-config/nginx-root.sh               | 创建nginx web站点目录             |                                          |
|  15  | init/nginx-config/nginx-conf.sh               | 创建nginx配置文件                 | nginx                                    |
|  16  | init/nginx-config/nginx-dns.sh                | 创建nginx站点域名A记录            | op/aliyun-dns.sh；<br> op/godaddy-dns.sh |
|  17  | init/nginx-config/web-release-on-nginx.sh     | 上线或回滚nginx站点               | nginx                                    |
|  18  | init/pg/backup/pg_backup_or_restore.sh        | 备份pg数据库                      | pg                                       |
|  19  | init/pg/backup/pg_list_backup_or_restore.sh   | 备份pg数据库指定清单              | pg                                       |
|  20  | init/webhook/                                 | webhook前后端                     | python3                                  |
|  21  | 其他                                          | 略                                |                                          |



## 3 安装

项目运行在Linux系统之上，基本环境安装部分是基于CentOS，如果你用的是Ubuntu，可是自行修改，或手动安装。基本运行环境一般自行安装，每个公司都有自己的特有要求。



### 3.1 服务器准备

一般配置：

| 服务器类别 | 数量 | 说明         | 例如       |
| ---------- | ---- | ------------ | ---------- |
| deploy     | 1    | 用于构建与发布、webhook |          |
| docker集群 | 1~n  | 根据自己需要 | k8s；swarm；docker-compose |
| nginx      | 0~n  | 根据自己需要 | 放到集群也行 |
| db         | 0~n  | 根据自己需要 | postgresql；mysql |
| docker仓库 | 0~1  | 根据自己需要 | docker registry |
| maven仓库  | 0~1  | 根据自己需要 | nexus      |
| 代码仓库   | 0~1  | 根据自己需要 | gitalb |



### 3.2 Deploy主机初始化

创世之初



#### 3.2.1 安装基础软件

```bash
yum install -y tmux ansible sshpass git python3-pip
```



#### 3.2.2 克隆项目

克隆项目到deploy主机上，假设【home项目路径 = ~/zzxia-om-super-invincible-lollipop】



### 3.3 环境配置文件

**环境配置文件是后面项目初始化与运行的基础**。

如果没有特别说明，以下则皆在目录【home项目路径/init】下完成



#### 3.3.1 创建专属配置文件

基于【home项目路径/init/envs.sample】示例创建自己的环境变量文件

```bash
cp -r  home项目路径/init/envs.sample  home项目路径/init/envs-MyName
```

请参考【README.md】修改`home项目路径/init/envs-MyName`中的配置文件。如果增减了配置文件，也需要同时修改【0-init-envs.sh】脚本文件。





#### 3.3.2 初始化配置配置文件

```bash
$ ./00-cp-【0-init-envs.sh】-to-here.sh  --help
    用法:
    sh ./00-cp-【0-init-envs.sh】-to-here.sh  [-h|--help]
    sh ./00-cp-【0-init-envs.sh】-to-here.sh  {Path-To-envs文件目录}    #--- 拷贝envs目录中的【0-init-envs.sh】到当前目录
$ ./00-cp-【0-init-envs.sh】-to-here.sh  ./envs-MyName

$ ./0-init-envs.sh --help
    用法:
    sh ./0-init-envs.sh  [-h|--help]
    sh ./0-init-envs.sh  [-r|--rm]            #--- 删除项目环境文件
    sh ./0-init-envs.sh  [-c|--copy {环境名称}]  <-f|--from {Path-To-envs文件目录}>    #--- 拷贝envs目录中以【---环境名称】结尾的文件到指定路径，比如：【prod|stag|dev|其他任意名称】
$ ./0-init-envs.sh  -c dev  -f ./envs-MyName
```



### 3.4 SSH登录配置

如果没有特别说明，以下则皆在目录【home项目路径/init】下完成



#### 3.4.1 登录跳过RSA key"yes/no"验证，会话保持

修改配置文件`/etc/ssh/ssh_config`：

```text
    StrictHostKeyChecking no
    ServerAliveInterval 60
```



#### 3.4.2 生成sshkey用于免密登录

```bash
ssh-keygen -C '便于识别的名字'
```



#### 3.4.3 免密登录

```bash
$ ./1-sshkey-copy.sh --help
用法：./1-sshkey-copy.sh  [用户]  [密码]  [主机列表文件]

$ ./1-sshkey-copy.sh  [用户]  [密码]  host-ip.list
```



### 3.5 为了减少异常发生，你可能需要关掉一些麻烦

关闭防火墙，略
关闭selinux，略



### 3.6 安装base软件环境

如果没有特别说明，以下则皆在目录【home项目路径/init】下完成

```bash
# java、mvn、node（根据需要安装）
./install-build-envs.sh
# hosts（一般不需要）
ansible-playbook  install-hosts.yml
# 一般必须
ansible-playbook  install-base.yml
ansible-playbook  install-config-base.yml
# reboot 重新装载变量RUN_ENV
ansible all --become -m shell -a "reboot"
```



### 3.7 密码配置文件

**密码配置文件是后面项目运行的基础，这些一般不要保存在仓库中，请放在隐秘的角落，就像小电影一样。**

这些文件都会在构建或发布的时候被`env.sh`引入。

如果没有特别说明，以下则皆在目录【home项目路径/init】下完成



#### 3.7.1创建专属密码配置文件

基于【home项目路径/init/my_sec.sample】示例创建自己的密码配置文件

```bash
cp -r  home项目路径/init/my_sec.sample  home项目路径/init/my_sec-MyName
```

请参考【README.md】修改`home项目路径/init/my_sec-MyName`中的配置文件。如果增减了配置文件，也需要同时修改【install-config-my_sec.yml】ansible-playbook文件。



#### 3.7.2 部署密码配置文件

```bash
ansible-playbook  install-config-my_sec.yml
```



### 3.8 其他周边软件

这些软件不是必须的，请根据自己的需要选择安装，也可以自己用其他方式安装

```bash
# docker相关
ansible-playbook  install-docker.yml
ansible-playbook  install-config-docker.yml

# docker仓库，你可能用的是harbor
ansible-playbook  install-docker_registry.yml
ansible-playbook  install-config-docker_registry.yml

# maven仓库、npm仓库
ansible-playbook  install-nexus.yml

# postgresql
ansible-playbook  install-pg.yml
ansible-playbook  install-config-pg.yml

# nginx相关
ansible-playbook  install-nginx.yml
ansible-playbook  install-config-nginx.yml

# 证书相关
ansible-playbook install-certbot.yml
ansible-playbook install-config-certbot.yml

# 其他略
# 根据自己需要安装
```



### 3.9 安装集群

请自行安装（k8s或swarm或docker-compose）

支持多种集群并行运行，也支持多命名空间或网络空间



## 4 配置

【安装】环节对【环境配置文件】只是简单带过，其实这是非常关键的一环，所以在这里对主要配置进行详细说明

**所有的说明都写在注释里或者表头里，请一定仔细研读**

文件位置：【home项目路径/init/envs.sample】



### 4.1 【env.sh---dev】

【home项目路径/init/envs.sample/env.sh---dev】

```sh
#!/bin/bash

# 0  基本

GAN_PLATFORM_NAME="超甜B&D系统"    #--- 给本构建发布系统取个名字
BUILD_LOG_WEBSITE_DOMAIN_A="build-log"    #--- 这个需要与【nginx.list】中【项目名】为【build-log】的【域名A记录】保持一致，一般无需更改此项
ERROR_EXIT='NO'                    #--- 出错立即退出，YES|NO

# DEBUG 模式
DEBUG='YES'                         #--- YES|NO，如果设置DEBUG='YES'，则将容器所有内部端口publish出来，一般用于【dev】环境
# Debug模式容器随机端口范围
DEBUG_RANDOM_PORT_MIN=45000        #--- 最小
DEBUG_RANDOM_PORT_MAX=49999        #--- 最大

# 根据需要选择【npm|cnpm】
NPM_BIN='npm'

# 1  Build

## 仓库及分支
export GIT_REPO_URL_BASE="git@g.zjlh.lan:gc"
#export GIT_REPO_URL_BASE="https://g.zjlh.lan/gc"
export GIT_BRANCH='develop'

## 跳过测试
export BUILD_SKIP_TEST='NO'    #--- YES|NO

# 2  Docker集群相关

##  运行方式
# fuck    : 直接执行命令；.
# notfuck : 打印命令到屏幕，自行拷贝执行
export FUCK='notfuck'

##  集群类型

## ----------------------------------------
## A  swarm.

### 远程管理
#export SWARM_DOCKER_HOST="ssh://root@192.168.11.141:2222"
export SWARM_DOCKER_HOST="tcp://192.168.11.71:2375"

### 基本运行参数
#### 网络
export SWARM_DEFAULT_NETWORK='onet_1'         #--- 默认值，可以在服务清单中指定其他

### docker log driver
export DOCKER_LOG_DRIVER='json-file'
#export DOCKER_LOG_DRIVER='fluentd'

#### Json file
export JSON_LOG_MAX_FILE_SIZES="100m"
export JSON_LOG_MAX_FILES=5

#### Fluentd
#export FLUENTD_SERVER_ADDR="192.168.11.83"
#export FLUENTD_SERVER_PORT="24224"

## ----------------------------------------
## B  k8s

export K8S_NAMESAPCE='default'                       #--- 默认值，可以在服务清单中指定其他
export DOCKER_REPO_SECRET_NAME='my-docker-repo-pw'   #--- 请自行创建相关secret

## ----------------------------------------
## C  docker-compose

### 网络
export NETWORK_COMPOSE='net_gc'

## ----------------------------------------

# 3 Build 与 Docker

## 密码相关 ( *** 存放在【~/.my_sec/*.sec/*.sec】下的文件皆包含密码，不推荐保存到代码仓库 *** )
for FILE in $(find  "${HOME}/.my_sec"  -type f  -name '*.sec')
do
    . ${FILE}
done

## Container env(自定义希望注入到docker容器的环境变量)
export CONTAINER_ENVS_PUB_FILE="${HOME}/.my_sec/container-envs-pub.sec"

##############################################################
#
# 以下部分不需要修改
#
# 0 组装日志
# https://docs.docker.com/config/containers/logging/configure/
export DOCKER_LOG_PUB="--log-driver=json-file  --log-opt max-size=${JSON_LOG_MAX_FILE_SIZES:-100m}  --log-opt max-file=${JSON_LOG_MAX_FILES:-5}  --log-opt labels=\${SERVICE_NAME}"
#
case "${DOCKER_LOG_DRIVER}" in
    gelf)
        export DOCKER_LOG_PUB="--log-driver=gelf  --log-opt gelf-address=udp://${GELF_SERVER_ADDR}:${GELF_SERVER_PORT:-12201}  --log-opt tag=\${SERVICE_NAME}"
        ;;
    fluentd)
        export DOCKER_LOG_PUB="--log-driver=fluentd  --log-opt fluentd-address=udp://${FLUENTD_SERVER_ADDR}:${FLUENTD_SERVER_PORT:-24224}  --log-opt tag=\${SERVICE_NAME}"
        ;;
    json-file)
        export DOCKER_LOG_PUB="--log-driver=json-file  --log-opt max-size=${JSON_LOG_MAX_FILE_SIZES:-100m}  --log-opt max-file=${JSON_LOG_MAX_FILES:-5}  --log-opt labels=\${SERVICE_NAME}"
        ;;
    *)
        export DOCKER_LOG_PUB="--log-driver=json-file  --log-opt max-size=${JSON_LOG_MAX_FILE_SIZES:-100m}  --log-opt max-file=${JSON_LOG_MAX_FILES:-5}  --log-opt labels=\${SERVICE_NAME}"
        ;;
esac
```



### 4.2 【project.list】

这个是build.sh及gogogo.sh的关键配置文件

【home项目路径/init/envs.sample/project.list】

```sh
## 项目清单
###
### 2【类别：LANGUAGE_CATEGORY】= [ product|dockerfile|java|node|自定义 ]
###   1 product   ：成品
###   2 dockerfile：Dockerfile
###   3 java      ：Java
###   4 node      ：Node
###
### 3【项目名：PJ】= [自定义名称]
###
### 4【构建方法：BUILD_METHOD】= [ NONE | docker_build | java:[mvn_package|gradle|自定义] | node:[original|build|自定义] ]
###   0 类别='*'          : NONE             : 跳过构建，用【gogogo.sh】时，也会跳过发布
###   1 类别='product'    : NONE             : 跳过构建，成品无需构建
###   2 类别='dockerfile' : docker_build     : 即docker build
###   3 类别='java'       : mvn_package      : 即mvn package
###                       : mvn_deploy       : 即mvn deploy
###                       : gradle           : 即gradle ......（没搞）
###   4 类别='node'       : npm_install      : npm install
###                       : npm_build        : npm install && npm build
###
### 5【输出方法：OUTPUT_METHOD】= [ dockerfile:[docker_image_push|NONE] | java:[deploy_war|deploy_jar_to_repo|docker_image_push|NONE] | node:[direct_deploy|docker_image_push|NONE] ]
###   1 类别='product'    : docker_image_push    : 仅用于推送docker镜像到docker仓库
###   2 类别='dockerfile' : docker_image_push    : 推送docker镜像到仓库
###                       : NONE                 : 无需输出
###   3 类别='java'       : deploy_war           : 输出war包（没搞）
###                       : deploy_jar_to_repo   : 推送jar包到maven仓库
###                       : docker_image_push    : 推送docker镜像到仓库
###                       : NONE                 : 无需输出，比如已经deploy到仓库等
###   4 类别='node'       : direct_deploy        : 拷贝输出文件到nginx_real服务器
###                       : docker_image_push    : 推送docker_image_push镜像到仓库
###                       : NONE                 : 无需输出，一般用于前端公共组件项目，供其他项目链接用
###
### 6【镜像名：DOCKER_IMAGE_NAME】= [自定义名称]
###   当输出方法='docker_image_push'时，镜像名不能为空
###
### 7【链接node_project：LINK_NODE_PROJECT】= [node_module来源项目名称]
###   将此node项目中的node_module软链接到当前项目，用以避免重复编码与重复下载node_module
###
### 8【GOGOGO发布方式：GOGOGO_RELEASE_METHOD】= [ NONE | docker_cluster | web_release | 自定义 ]
###   注：用【gogogo.sh】脚本自动构建与发布时使用的参数
###   1 NONE            : 无需发布
###   2 docker_cluster  : 用【docker-cluster-service-deploy.sh】发布
###   3 web_release     : 用【web-release.sh】发布
###
### 9【优先级：PRIORITY】= [ 数字 ]
###   数字越小越优先
###
###   ***** 以上种种，都可以自己定义，然后调整相关脚本即可 *****
###
#| LANGUAGE_CATEGORY | PJ                    | BUILD_METHOD | OUTPUT_METHOD     | DOCKER_IMAGE_NAME              | LINK_NODE_PROJECT    |GOGOGO_RELEASE_METHOD | PRIORITY |
#| **类别** | **项目名**                     | **构建方法** | **输出方法**      | **镜像名**                     | **链接node_project** | **GOGOGO发布方式** | **优先级** |
#| -------- | ------------------------------ | ------------ | ----------------- | ------------------------------ | -------------------- | ------------------ | ---------- |
| product   | neo4j                          | NONE         | docker_image_push | neo4j                          |                      | docker_cluster     | 0          |
| product   | fluentd                        | NONE         | docker_image_push | fluentd-gcl                    |                      | docker_cluster     | 0          |
| dockerfile| my-oracle-java-8               | docker_build | docker_image_push | my-oracle-java-8               |                      | NONE               | 1          |
| java      | gc-common                      | mvn_deploy   | NONE              |                                |                      | NONE               | 5          |
| java      | gc-gray                        | mvn_deploy   | NONE              |                                |                      | NONE               | 5          |
| java      | gc-auth-service                | mvn_package  | docker_image_push | gc-auth-service                |                      | docker_cluster     | 10         |
| java      | gc-monitor                     | mvn_package  | docker_image_push | gc-monitor                     |                      | docker_cluster     | 20         |
| node      | gc-common-front                | npm_install  | NONE              |                                |                      | NONE               | 100        |
| node      | gc-platform-node               | npm_install  | docker_image_push | gc-platform-node               |                      | docker_cluster     | 110        |
| node      | gc-agent-front                 | npm_build    | direct_deploy     |                                | gc-common-front      | web_release        | 110        |
| node      | gc-fastprotect-front           | npm_build    | direct_deploy     |                                |                      | web_release        | 110        |
| product   | nacos-server                   | NONE         | docker_image_push | nacos-server                   |                      | docker_cluster     | 0          |
```



### 4.3 【docker-cluster-service.list---dev、docker-cluster-service.list。append.1---dev、docker-cluster-service.list.append.2---dev】

这个是发布docker服务时的关键文件，这里可以实现较为复杂的部署要求，也可以根据需要增加列以实现更为复杂的需求

- 【home项目路径/init/envs.sample/docker-cluster-service.list---dev】

```sh
###  4【POD副本数：POD_REPLICAS】= [ 数字|${变量名} ]
###    1 数字          : 例如：2
###    2 ${变量名}     : 例如：【${SERVICE_NAME}】
###
###  5【容器PORTS：CONTAINER_PORTS】= [ 外部端口号1:内部端口号2, 外部端口号3:内部端口号4, ...... , ${变量名} ]
###    若有多个，则用【,】分隔
###    示例：【17474:7474】
###          【${xName}:7474】
###          【27474:7474,7687:7687】
###
###  6【优先级：PRIORITY】= [ 数字 ]
###    数字越小越优先
###
###  7【备注：NOTE】= [ 自定义 ]
###    说明信息
###
###
### A.1 更多扩展项，请在文件【docker-cluster-service.list.append.1】中添加
###    3 集群
###    4 主机名
###    5 部署位置
###
###
### A.2 更多扩展项，请在文件【docker-cluster-service.list.append.2】中添加
###    3 JAVA选项
###    4 容器ENVS
###    5 容器CMDS
###
###
###   ***** 以上种种，都可以自己定义，然后调整相关脚本即可 *****
###
###   ***** 上文提到的变量名可以是下文表头的名字、也可以是sh中可以获得的变量名 *****
###
#| SERVICE_NAME           | DOCKER_IMAGE_NAME       | POD_REPLICAS  | CONTAINER_PORTS    | PRIORITY   | NOTE                         |
#| **服务名**             | **DOCKER镜像名**        | **POD副本数** | **容器PORTS**      | **优先级** | **备注**                     |
#| ---------------------- | ----------------------- | ------------: | ------------------ | ---------- | ---------------------------- |
|neo4j-srv                |neo4j                    | 1             | 7474:7474,7687:7687| 0          |                              |
|redis-srv                |redis                    | 1             | 6379:6379          | 0          |                              |
|nacos-server-1           |nacos-server             | 1             | 8848:8848,9848:9848,9555:9555| 0|                              |
|nacos-server-2           |nacos-server             | 1             | :8848,:9848,:9555  | 20         |                              |
|nacos-server-3           |nacos-server             | 1             | :8848,:9848,:9555  | 20         |                              |
|gc-gateway               |gc-gateway               | 1             | 13000:13000        | 15         |                              |
|gc-monitor               |gc-monitor               | 1             | :13030             | 20         |                              |
|gc-client-service        |gc-client-service        | 1             | :23000             | 20         |                              |
|gc-client-app-service    |gc-client-app-service    | 1             | :23100             | 20         |                              |
|gc-travel-service        |gc-travel-service        | 1             | :20201             | 20         |                              |
```

- 【home项目路径/init/envs.sample/docker-cluster-service.list.append.1---dev】

```sh
###  ---------------------------------------------------------------------------------------
###.
###  2【服务名：SERVICE_NAME】= [ 自定义名称 ].
###
###  3【集群：CLUSTER】= [ swarm|k8s|compose|自定义 ]
###    1 swarm       : swarm
###    2 k8s         : k8s
###    3 compose     : docker-compose
###
###  4【主机名：HOST_NAME】= [ 自定义 ]
###    须符合主机名称规范
###
###  5【部署位置：DEPLOY_PLACEMENT】= [ NET:网络 , L:label键值对 | NS:命名空间, L:label键值对 | SSH:<用户@>主机名或IP <-p ssh端口> ]
###    1 集群='swarm'      : NET:网络, L:label键值对             : NET 即network，默认在env.sh---*中定义，这里可以省略
###                                                              : L 即Label，指定标签，可以有多个，代表服务部署到这个标签主机节点，可以不指定
###    2 集群='k8s'        : NS:命名空间, L:label键值对          : NS 即k8s命名空间，默认在env.sh---*中定义，这里可以省略
###                                                              : L 同上，即Label，指定标签，可以有多个，代表服务部署到这个标签主机节点，可以不指定
###    3 集群='compose'    : SSH:<用户@>主机名或IP <-p ssh端口>  : 需要ssh到目标节点实现免密码登录，【用户名】及【ssh端口】可以省略
###    若有多个参数，则用【,】分隔
###    示例：【L:node=worker_node_2】
###          【NET:net1, L:node=worker, L:aa=bbb】
###          【NET:net1】
###          【NS:demo_space, L:node=worker, L:aa=bbb】
###          【NS:demo_space】
###          【SSH:root@192.168.11.77 -p 22】
###          【SSH:192.168.11.77】
###
###
###   ***** 以上种种，都可以自己定义，然后调整相关脚本即可 *****
###
###   ***** 上文提到的变量名可以是下文表头的名字、也可以是sh中可以获得的变量名 *****
###
#| SERVICE_NAME           | CLUSTER  | HOST_NAME     | DEPLOY_PLACEMENT                                           |
#| **服务名**             | **集群** | **主机名**    | **部署位置**                                               |
#| ---------------------- | -------- | ------------- | ---------------------------------------------------------- |
|neo4j-srv                | swarm    |               |                                                            |
|redis-srv                | swarm    |               |                                                            |
|nacos-server-1           | swarm    |nacos-server-a |                                                            |
|nacos-server-2           | swarm    |nacos-server-b |                                                            |
|nacos-server-3           | swarm    |nacos-server-c |                                                            |
|gc-gateway               | swarm    |               |                                                            |
|gc-monitor               | swarm    |               |                                                            |
|gc-client-service        | k8s      |               |                                                            |
|gc-client-app-service    | compose  |               | SSH:192.168.11.77                                          |
|gc-travel-service        | k8s      |               |                                                            |

```

- 【home项目路径/init/envs.sample/docker-cluster-service.list.append.2---dev】

```sh
## docker cluster 服务部署清单扩展
###
### 此文件【docker-cluster-service.list.append.2】是【docker-cluster-service.list】的扩展，请确保两个文件的【服务名】相匹配，否则无效，如果某服务不需要扩展项，则可以删除该行
###
###.
###  ---------------------------------------------------------------------------------------
###.
###  2【服务名：SERVICE_NAME】= [ 自定义名称 ].
###    确保与【docker-cluster-service.list】中的【服务名】相匹配，否则无效
###.
###  3【JAVA选项：JAVA_OPTIONS】= [ Java参数1 , Java参数2, Java参数n, JAVA_OPT_FROM_FILE="/path/to/filename" ]
###    如果有多个，则用【,】号分隔，例如：【-Dencoding=UTF-8,-Dfile=${FILE},JAVA_OPT_FROM_FILE="/path/to/filename"】
###    -  指定为具体参数，例如：【-Dencoding=UTF-8】
###    -  指定变量参数，例如：【-Dfile=${FILE}】
###    -  指定从文件获取，参数名需指定为【JAVA_OPT_FROM_FILE】，例如：【JAVA_OPT_FROM_FILE="/path/to/filename"】，建议放在【init/my_envs/】目录下，用git管理
###.
###  4【容器ENVS：CONTAINER_ENVS】= [ 变量1=值1, 变量2=值2, 变量n=值n, ENVS_FROM_FILE="/path/to/filename"]
###    如果有多个，则用【,】号分隔，例如：【aa=1,bb=2,NEO4J_AUTH=${NEO4J_USER}/${NEO4J_PASSWORD},ENVS_FROM_FILE="/path/to/filename"】
###    - 指定为具体参数，例如：【aa=1,bb=2】
###    - 指定变量参数，例如：【NEO4J_AUTH=${NEO4J_USER}/${NEO4J_PASSWORD}】
###    - 指定从文件获取，参数名需指定为【ENVS_FROM_FILE】，例如【ENVS_FROM_FILE="/path/to/filename"】，建议放在【init/my_envs/】目录下，用git管理
###.
###  5【容器CMDS：CONTAINER_CMDS】= [ 命令参数2, 命令参数n, CMDS_FROM_FILE="/path/to/filename" ]
###    如果有多个，则用【,】号分隔，例如：【--quiet,--requirepass "${REDIS_PASSWORD}",CMDS_FROM_FILE="/path/to/filename"】
###    - 指定为具体参数，例如：【--quiet】
###    - 指定变量参数，例如：【--requirepass "${REDIS_PASSWORD}"】
###    - 指定从文件获取，参数名需指定为【CMDS_FROM_FILE】，例如【CMDS_FROM_FILE="/path/to/filename"】，建议放在【init/my_envs/】目录下，用git管理
###.
###
###   ***** 以上种种，都可以自己定义，然后调整相关脚本即可 *****
###
###   ***** 上文提到的变量名可以是下文表头的名字、也可以是sh中可以获得的变量名 *****
###
#| SERVICE_NAME           | JAVA_OPTIONS                      | CONTAINER_ENVS                                             | CONTAINER_CMDS                    |
#| **服务名**             | **JAVA选项**                      | **容器ENVS**                                               | **容器CMDS**                      |
#| ---------------------- | --------------------------------- | ---------------------------------------------------------- | --------------------------------- |
|neo4j-srv                |                                   | NEO4J_AUTH="${NEO4J_USER}/${NEO4J_PASSWORD}"               |                                   |
|redis-srv                |                                   |                                                            |--requirepass "${REDIS_PASSWORD}"  |
|nacos-server-1           |                                   | ENVS_FROM_FILE=../init/my_envs/nacos.env                   |                                   |
|nacos-server-2           |                                   | ENVS_FROM_FILE=../init/my_envs/nacos.env                   |                                   |
|nacos-server-3           |                                   | ENVS_FROM_FILE=../init/my_envs/nacos.env                   |                                   |
|gc-gateway               | -Xms512m -Xmx512m                 |                                                            |                                   |
|gc-monitor               | -Xms512m -Xmx512m                 |                                                            |                                   |
|gc-client-service        | -Xms512m -Xmx512m                 |                                                            |                                   |
|gc-client-app-service    | -Xms512m -Xmx512m                 |                                                            |                                   |
|gc-travel-service        | -Xms512m -Xmx512m                 |                                                            |                                   |
```


### 4.4 【nginx.list---dev】

这个是发布web服务时的关键文件，也是生成nginx配置文件、自动生成域A记录的关键配置文件

【home项目路径/init/envs.sample/nginx.list---dev】

```sh
## nginx网站配置清单
###
###  2【项目名：PJ】= [ 自定义名称 ]
###
###  3【域名A记录：DOMAIN_A】= [ 自定义名称 ]
###    不要加域名后缀，部署时根据运行环境自动添加
###
###  4【http端口：FRONT_HTTP_PORT】= [ 端口号 ]
###    运行在http下时的端口号
###
###  5【https端口：FRONT_HTTPS_PORT】= [ 端口号 ]
###    运行在https下时的端口号
###
###  6【方式：MODE】= [ realserver|realserver ]
###    1 realserver      : 作为real server
###    2 proxyserver     : 作为代理服务器，必须要有【后端协议端口】参数
###
###  7【后端协议端口：BACKEND_PROTOCOL_PORT】= [ 协议:端口号 ]
###    协议 = [ http | https ]
###
###  8【附加项：ITEMS】= [auth_basic,autoindex,upload_size=100m,try_files]中的一个或多个，用【,】分隔
###    1 auth_basic           : 添加验证;
###    2 autoindex            : 目录浏览;
###    3 upload_size=100m     : 文件上传大小;
###    4 try_files            : try_files $uri $uri/ /index.html;
###
###  9【域名A记录IP：DOMAIN_IPS】= [ IP地址1,IP地址2,IP地址n ]
###    域名A记录指向的IP地址，如果有多个，则用【,】分隔
###
### 10【优先级：PRIORITY】= [ 数字 ]
###   数字越小越优先
###
###   ***** 以上种种，都可以自己定义，然后调整相关脚本即可 *****
###
#| PJ                           | DOMAIN_A            |FRONT_HTTP_PORT|FRONT_HTTPS_PORT| MODE      |BACKEND_PROTOCOL_PORT| ITEMS             |  DOMAIN_IPS     | PRIORITY   |
#| **项目名**                   | **域名A记录**       | **http端口** | **https端口** | **方式**    | **后端协议端口** | **附加项**           | **域名A记录IP** | **优先级** |
#| ---------------------------- | ------------------- | ------------ | ------------- | ----------- | ---------------- | -------------------- | --------------- | ---------- |
| build-log                     | build-log           | 80           | 443           | realserver  |                  | auth_basic,autoindex | 192.168.11.77   | 5          |
| log                           | log                 | 80           | 443           | proxyserver | http:5601        | auth_basic           | 192.168.11.77   | 5          |
| gc-platform-node              | bmp-platform-node   | 80           | 443           | proxyserver | http:41300       |                      | 192.168.11.77   | 5          |
| gc-client-mobile-h5-front     | app-client-h5       | 80           | 443           | realserver  |                  | try_files            | 192.168.11.77   | 5          |
| gc-client-app-service         | app-client-public   | 80           | 443           | proxyserver | http:23100       | upload_size=50m      | 192.168.11.77   | 5          |
```



## 5 使用



### 5.1 使用说明

请使用-h|--help参数运行sh脚本即可看到使用说明。

所有帮助里面都包含以下部分：

```text
用途：......
依赖：......
注意：......
用法：......
参数说明：
    $0   : 代表脚本本身
    []   : 代表是必选项
    <>   : 代表是可选项
    |    : 代表左右选其一
    {}   : 代表参数值，请替换为具体参数值
    %    : 代表通配符，非精确值，可以被包含
    正则  ：正则匹配
    完全正则：完全正则匹配
示例：......
```

**相信你可以根据帮助迅速上手**



### 5.2 项目构建



#### 5.2.1 一般构建

帮助信息如下：

```bash
$ ./deploy/build.sh --help

    用途：用于项目构建，生成docker镜像并push到仓库
    依赖：
        /etc/profile.d/run-env.sh
        /root/deploy-bmp/deploy/env.sh
        /root/deploy-bmp/deploy/project.list
        /root/deploy-bmp/deploy/../op/send_mail.sh
        /root/deploy-bmp/deploy/docker-tag-push.sh
        /root/deploy-bmp/deploy/../op/format_table.sh
        /root/deploy-bmp/deploy/../op/dingding_conver_to_markdown_list-deploy.py
    注意：
        * 名称正则表达式完全匹配，会自动在正则表达式的头尾加上【^ $】，请规避
        * 输入命令时，参数顺序不分先后
    用法:
        ./build.sh  [-h|--help]
        ./build.sh  [-l|--list]
        ./build.sh  <-M|--mode [normal|function]>  <-c|--category [dockerfile|java|node|自定义]>  <-b|--branch {代码分支}>  <-e|--email {邮件地址}>  <-s|--skiptest>  <-f|--force>  <-v|--verbose>  <{项目1}  {项目2} ... {项目n} ... {项目名称正则表达式完全匹配}>
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -l|--list      列出可构建的项目清单
        -M|--mode      指定构建方式，二选一【normal|function】，默认为normal方式。此参数用于被外部调用
        -c|--category  指定构建项目语言类别：【dockerfile|java|node|自定义】，参考：/root/deploy-bmp/deploy/project.list
        -b|--branch    指定代码分支，默认来自env.sh
        -e|--email     发送日志到指定邮件地址，如果与【-U|--user-name】同时存在，则将会被替代
        -s|--skiptest  跳过测试，默认来自env.sh
        -f|--force     强制重新构建（无论是否有更新）
        -v|--verbose   显示更多过程信息
    示例:
        #
        ./build.sh  -l         #--- 列出可构建的项目清单
        #
        ./build.sh                              #--- 构建所有项目，用默认分支
        ./build.sh  -b 分支a                    #--- 构建所有项目，用分支a
        ./build.sh  -b 分支a  项目1  项目2      #--- 构建项目：【项目1、项目2】，用【分支a】
        ./build.sh            项目1  项目2      #--- 构建项目：【项目1、项目2】，用默认分支
        # 按类别
        ./build.sh  -c java                           #--- 构建所有java项目，用默认分支
        ./build.sh  -c java  -b 分支a                 #--- 构建所有java项目，用【分支a】
        ./build.sh  -c java  -b 分支a  项目1  项目2   #--- 构建node项目：【项目1、项目2】，用【分支a】
        ./build.sh  -c java            项目1  项目2   #--- 构建node项目：【项目1、项目2】，用默认分支
        # 项目名称用正则表达式完全匹配
        ./build.sh   .*xxx.*        #--- 构建项目名称正则匹配【^.*xxx.*】的项目，用默认分支
        ./build.sh   [ab]*xxx       #--- 构建项目名称正则匹配【^[ab]*xxx$】的项目，用默认分支
        ./build.sh   sss.*eee       #--- 构建项目名称正则匹配【^sss.*eee$】的项目，用默认分支
        ./build.sh   sss.*          #--- 构建项目名称正则匹配【^sss.*$】的项目，用默认分支
        # 发邮件
        ./build.sh  --email xm@xxx.com                #--- 构建所有项目，用默认分支，将错误日志发送到邮箱【xm@xxx.com】
        ./build.sh  --email xm@xxx.com  项目1  项目2  #--- 构建项目：【项目1、项目2】，用默认分支，将错误日志发送到邮箱【xm@xxx.com】
        # 测试
        ./build.sh  -b 分支a  -s  项目1  项目2        #--- 构建项目：【项目1、项目2】，用【分支a】，跳过测试
        # 强制重新构建
        ./build.sh  -f  项目1  项目2                  #--- 构建【项目1、项目2】，用默认分支，无论有没有更新都进行强制构建
        # 显示更多信息
        ./build.sh  -v  --email xm@xxx.com                #--- 构建所有项目，用默认分支，显示更多过程信息并将错误日志发送到邮箱【xm@xxx.com】
        ./build.sh  -v  --email xm@xxx.com  项目1  项目2  #--- 构建项目：【项目1、项目2】，用默认分支，显示更多详细信息并将错误日志发送到邮箱【xm@xxx.com】
        # 外调用★
        ./build.sh  -M function  项目1                #--- 构建项目：【项目1】，用默认分支
        ./build.sh  -M function  -b 分支a  项目1      #--- 构建项目：【项目1】，用分支【分支a】

```

日常使用：

```bash
$ ./build.sh                  #--- 所有项目
$ ./build.sh  项目1  项目2     #--- 指定项目
$ ./build.sh  proj.*          #--- 指定正则匹配【proj.*】的项目
$ ./build.sh  -c java         #--- 指定项目类别
```

上面提供了丰富的参数，你可以灵活使用，且容易上手。



#### 5.2.2 并行构建

> 这可以加快构建速度

帮助信息如下：

```bash
$ ./deploy/build-parallel.sh --help

    用途：以并行的方式运行构建脚本，以加快构建速度
    依赖：
        /etc/profile.d/run-env.sh
        /root/deploy-bmp/deploy/env.sh
        /root/deploy-bmp/deploy/project.list
        /root/deploy-bmp/deploy/build.sh
        /root/deploy-bmp/deploy/../op/format_table.sh
        /root/deploy-bmp/deploy/../op/dingding_conver_to_markdown_list-deploy.py
    注意：
        * 名称正则表达式完全匹配，会自动在正则表达式的头尾加上【^ $】，请规避
        * 输入命令时，参数顺序不分先后
    用法:
        ./build-parallel.sh  [-h|--help]
        ./build-parallel.sh  [-l|--list]
        ./build-parallel.sh  <-n|--number>  <-c [dockerfile|java|node|自定义]>  <-b {代码分支}>  <-e|--email {邮件地址}>  <-s|--skiptest>  <-f|--force>  <{项目1}  {项目2} ... {项目n}> ... {项目名称正则表达式完全匹配}>
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -l|--list      列出可构建的项目清单
        -n|--number    并行构建项目的数量，默认为2个
        -c|--category  指定构建项目语言类别：【dockerfile|java|node|自定义】，参考：/root/deploy-bmp/deploy/project.list
        -b|--branch    指定代码分支，默认来自env.sh
        -e|--email     发送日志到指定邮件地址，如果与【-U|--user-name】同时存在，则将会被替代
        -s|--skiptest  跳过测试，默认来自env.sh
        -f|--force     强制重新构建（无论是否有更新）
    示例:
        #
        ./build-parallel.sh  -l     #--- 列出可构建的项目清单
        # 在build.sh的用法基础上选择是否加上【-n】参数即可
        ./build-parallel.sh                            #--- 构建所有项目，用默认分支，同时构建默认个
        ./build-parallel.sh  -n 4                      #--- 构建所有项目，用默认分支，同时构建4个
        ./build-parallel.sh  -n 4  -b 分支a            #--- 构建所有项目，用【分支a】，同时构建4个
        ./build-parallel.sh  -n 4  -c java             #--- 构建所有java项目，用默认分支，同时构建4个
        ./build-parallel.sh  项目1 项目2                        #--- 构建【项目1、项目2】，用默认分支，同时构建默认个
        ./build-parallel.sh  --email xm@xxx.com  项目1 项目2    #--- 构建【项目1、项目2】，用默认分支，同时构建默认个，将错误日志发送到邮箱【xm@xxx.com】
        ./build-parallel.sh  -s -f  项目1 项目2                 #--- 构建【项目1、项目2】，用默认分支，同时构建默认个，跳过测试，强制重新构建（无论是否有更新）
        ./build-parallel.sh  sss                       #--- 构建项目名称正则匹配【^sss$】的项目，用默认分支，同时构建默认个
        # 更多示例请参考【build.sh】
```

日常使用：

```bash
$ ./build-parallel.sh                  #--- 所有项目，默认并行2个
$ ./build-parallel.sh  -n 5            #--- 所有项目，一次并行构建5个
$ ./build-parallel.sh  -n 5  -c java   #--- 指定项目类别java，一次并行构建5个
```



### 5.3 项目发布

#### 5.3.1 docker项目发布（k8s|swarm|docker-compose）

帮助信息如下：

```bash
$ ./deploy/docker-cluster-service-deploy.sh --help

    用途：用于创建、更新、查看、删除......服务
    依赖：
        /root/deploy-bmp/deploy/docker-cluster-service.list
        /root/.my_sec/container-envs-pub.sec
        /root/deploy-bmp/deploy/docker-arg-pub.list
        /root/deploy-bmp/deploy/container-hosts-pub.list
        /root/deploy-bmp/deploy/java-options-pub.list
        /root/deploy-bmp/deploy/env.sh
        /root/deploy-bmp/deploy/docker-image-search.sh
        /root/deploy-bmp/deploy/../op/format_table.sh
        /root/deploy-bmp/deploy/../op/dingding_conver_to_markdown_list-deploy.py
    注意：
        * 名称正则表达式完全匹配，会自动在正则表达式的头尾加上【^ $】，请规避
        * 一般服务名（非灰度服务名）为项目清单中的服务名，灰度服务名为为【项目清单服务名】+【--】+【灰度版本号】
        * 输入命令时，参数顺序不分先后
    用法:
        ./docker-cluster-service-deploy.sh [-h|--help]
        ./docker-cluster-service-deploy.sh [-l|--list]                    #--- 列出配置文件中的服务清单
        ./docker-cluster-service-deploy.sh [-L|--list-run swarm|k8s]      #--- 列出指定集群中运行的所有服务，不支持持【docker-compose】
        # 创建、修改
        ./docker-cluster-service-deploy.sh <-M|--mode [normal|function]>  [-c|--create|-m|--modify]  <-D|--debug>  <<-t|--tag {模糊镜像tag版本}> | <-T|--TAG {精确镜像tag版本}>>  <-n|--number {副本数}>  <-V|--release-version {版本号}>  <-G|--gray>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        # 更新
        ./docker-cluster-service-deploy.sh <-M|--mode [normal|function]>  [-u|--update]  <<-t|--tag {模糊镜像tag版本}> | <-T|--TAG {精确镜像tag版本}>>  <-V|--release-version {版本号}>  <-G|--gray>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        # 回滚
        ./docker-cluster-service-deploy.sh <-M|--mode [normal|function]>  [--b|rollback]   <-V|--release-version {版本号}>  <-G|--gray>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        #
        # 扩缩容
        ./docker-cluster-service-deploy.sh <-M|--mode [normal|function]>  [-S|--scale]  [-n|--number {副本数}]  <-V|--release-version {版本号}>  <-G|--gray>  <{服务名或灰度服务名1} {服务名或灰度服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        # 删除
        ./docker-cluster-service-deploy.sh <-M|--mode [normal|function]>  [-r|--rm]  <-V|--release-version {版本号}>  <-G|--gray>  <-a|--all-release>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        # 状态
        ./docker-cluster-service-deploy.sh [-s|--status]  <-V|--release-version {版本号}>  <-G|--gray>  <-a|--all-release>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
        # 详情
        ./docker-cluster-service-deploy.sh [-d|--detail]  <-V|--release-version {版本号}>  <-G|--gray>  <-a|--all-release>  <{服务名1} {服务名2} ... {服务名正则表达式完全匹配}>  <-F|--fuck>
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      ：帮助
        -l|--list      ：列出配置文件中的服务清单
        -L|--list-run  ：列出指定集群中运行的所有服务，不支持【docker-compose】集群
        -F|--fuck      ：直接运行命令，默认：仅显示命令行
        -c|--create    ：创建服务，基于服务清单参数
        -m|--modify    ：修改服务，基于服务清单参数
        -u|--update    ：更新镜像版本
        -b|--rollback  ：回滚服务（回滚到非今天构建的上一个版本）
        -S|--scale     ：副本数设置
        -r|--rm        ：删除服务
        -s|--status    : 获取服务运行状态
        -d|--detail    : 获取服务详细信息
        -D|--debug     : 开启开发者Debug模式，目前用于开放所有容器服务端口
        -t|--tag       ：模糊镜像tag版本
        -T|--TAG       ：精确镜像tag版本
        -n|--number    ：Pod副本数
        -G|--gray      : 设置灰度标志为：gray，默认：normal
        -V|--release-version : 发布版本号
        -a|--all-release     : 所有已发布的版本，包含带版本号的、不带版本号的、灰度的、非灰度的
        -M|--mode      ：指定构建方式，二选一【normal|function】，默认为normal方式。此参数用于被外部调用
    示例：
        # 服务清单
        ./docker-cluster-service-deploy.sh -l                     #--- 列出配置文件中的服务清单
        ./docker-cluster-service-deploy.sh -L swarm               #--- 列出【swarm】集群中运行的所有服务
        # 仅显示最终命令行或直接执行（用于检查命令是否有错误）
        ./docker-cluster-service-deploy.sh -c  服务1                             #--- 根据服务清单显示创建【服务1】的命令行
        ./docker-cluster-service-deploy.sh -c  服务1  -F                         #--- 根据服务清单创建【服务1】
        # 服务名称正则完全匹配
        ./docker-cluster-service-deploy.sh  -c  .*xxx.*  -F                      #--- 创建服务名称正则完全匹配【^.*xxx.*$】的服务，使用最新镜像
        ./docker-cluster-service-deploy.sh  -u  [.]*xxx  -F                      #--- 更新服务名称正则完全匹配【^[.]*xxx$】的服务，使用最新镜像
        # 创建
        ./docker-cluster-service-deploy.sh -c  -F                                    #--- 根据服务清单创建所有服务
        ./docker-cluster-service-deploy.sh -c  服务1 服务2  -F                       #--- 创建【服务1】、【服务2】服务
        ./docker-cluster-service-deploy.sh -c  -D  服务1 服务2  -F                   #--- 创建【服务1】、【服务2】服务，并开启开发者Debug模式
        ./docker-cluster-service-deploy.sh -c  -T 2020.12.11  服务1 服务2  -F        #--- 创建【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】
        ./docker-cluster-service-deploy.sh -c  -t 2020.12     服务1 服务2  -F        #--- 创建【服务1】、【服务2】服务，且使用的镜像版本包含【2020.12】的最新镜像
        ./docker-cluster-service-deploy.sh -c  -n 2  服务1 服务2  -F                 #--- 创建【服务1】、【服务2】服务，且副本数为【2】
        ./docker-cluster-service-deploy.sh -c  -T 2020.12.11  -n 2  服务1 服务2  -F  #--- 创建【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】，副本数为【2】
        ./docker-cluster-service-deploy.sh -c  -V yyy       服务1 服务2  -F          #--- 创建【服务1】、【服务2】，版本号为【yyy】
        ./docker-cluster-service-deploy.sh -c  -G           服务1 服务2  -F          #--- 创建【服务1】、【服务2】的灰度服务
        ./docker-cluster-service-deploy.sh -c  -G  -V yyy   服务1 服务2  -F          #--- 创建【服务1】、【服务2】的灰度服务，版本号为【yyy】
        # 修改
        ./docker-cluster-service-deploy.sh -m  服务1 服务2  -F                       #--- 修改【服务1】、【服务2】服务
        ./docker-cluster-service-deploy.sh -m  服务1 服务2  -V yyy  -F               #--- 根据服务清单修改所有版本号为【yyy】的服务
        ./docker-cluster-service-deploy.sh -m  -T 2020.12.11  服务1 服务2  -F        #--- 修改【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】
        ./docker-cluster-service-deploy.sh -m  -t 2020.12     服务1 服务2  -F        #--- 修改【服务1】、【服务2】服务，且使用的镜像版本包含【2020.12】的最新镜像
        ./docker-cluster-service-deploy.sh -m  -n 2  服务1 服务2  -F                 #--- 修改【服务1】、【服务2】服务，且副本数为【2】
        ./docker-cluster-service-deploy.sh -m  -T 2020.12.11  -n 2  服务1 服务2  -F  #--- 修改【服务1】、【服务2】服务，且使用的镜像版本为【2020.12.11】，副本数为【2】
        # 更新镜像
        ./docker-cluster-service-deploy.sh -u  -F                                    #--- 根据服务清单更新设置所有服务的最新镜像tag版本（如果今天构建过）
        ./docker-cluster-service-deploy.sh -u  服务1 服务2  -F                       #--- 设置【服务1】、【服务2】服务的最新镜像tag版本（如果今天构建过）
        ./docker-cluster-service-deploy.sh -u  -t 2020.12  -F                        #--- 根据服务清单更新设置所有服务，且镜像tag版本包含【2020.12】的最新镜像
        ./docker-cluster-service-deploy.sh -u  -t 2020.12     服务1 服务2  -F        #--- 更新【服务1】、【服务2】有服务，且镜像tag版本包含【2020.12】的最新镜像
        ./docker-cluster-service-deploy.sh -u  -T 2020.12.11  -F                     #--- 根据服务清单更新设置所有服务，且镜像tag版本为【2020.12.11】的镜像
        ./docker-cluster-service-deploy.sh -u  -T 2020.12.11  服务1 服务2  -F        #--- 更新【服务1】、【服务2】有服务，且镜像tag版本为【2020.12.11】的镜像
        # 回滚
        ./docker-cluster-service-deploy.sh -b  -F                          #--- 根据服务清单回滚所有服务（如果今天构建过）
        ./docker-cluster-service-deploy.sh -b  服务1 服务2  -F             #--- 回滚【服务1】、【服务2】服务（如果今天构建过）
        ./docker-cluster-service-deploy.sh -b  服务1 服务2  -V yyy  -F     #--- 回滚【服务1】、【服务2】服务，且版本号为【yyy】（如果今天构建过）
        #
        # 扩缩容
        ./docker-cluster-service-deploy.sh -S  -n 2  -F                    #--- 根据服务清单设置所有服务的pod副本数为2
        ./docker-cluster-service-deploy.sh -S  -n 2  服务1 服务2  -F       #--- 设置【服务1】、【服务2】服务的pod副本数为2
        ./docker-cluster-service-deploy.sh -S  -n 2  -G  服务1 服务2  -F   #--- 设置【服务1】、【服务2】的灰度服务的pod副本数为2
        ./docker-cluster-service-deploy.sh -S  -n 2  -G  -V yyy  服务1 服务2  -F   #--- 设置【服务1】、【服务2】的灰度服务，且版本为【yyy】的pod副本数为2
        # 删除
        ./docker-cluster-service-deploy.sh -r  -F                          #--- 根据服务清单删除所有服务
        ./docker-cluster-service-deploy.sh -r  服务1 服务2  -F             #--- 删除【服务1】、【服务2】服务
        ./docker-cluster-service-deploy.sh -r  -G  服务1 服务2  -F         #--- 删除【服务1】、【服务2】的灰度服务
        ./docker-cluster-service-deploy.sh -r  -V yyy  服务1 服务2  -F     #--- 删除【服务1】、【服务2】，且版本为【yyy】的服务
        ./docker-cluster-service-deploy.sh -r  -V yyy  -G  服务1 服务2  -F #--- 删除【服务1】、【服务2】，且版本为【yyy】的灰度服务
        ./docker-cluster-service-deploy.sh -r  -a  服务1 服务2  -F         #--- 删除模糊匹配【服务1】、【服务2】的服务，包含带版本号的、不带版本号的、灰度的、非灰度的
        # 运行状态（更多请参考【删除】）
        ./docker-cluster-service-deploy.sh -s  -F                          #--- 根据服务清单获取服务运行状态
        ./docker-cluster-service-deploy.sh -s  服务1 服务2  -F             #--- 获取【服务1】、【服务2】服务运行状态
        ./docker-cluster-service-deploy.sh -s  -G  服务1 服务2  -F         #--- 获取【服务1】、【服务2】的灰度服务运行状态
        # 运行详细信息（更多请参考【删除】）
        ./docker-cluster-service-deploy.sh -d  -F                          #--- 根据服务清单获服务运行取详细信息
        ./docker-cluster-service-deploy.sh -d  服务1 服务2  -F             #--- 获取【服务1】、【服务2】服务运行详细信息
        # 外调用★ 
        ./docker-cluster-service-deploy.sh -M function  -u                 服务1  -F    #--- 更新部署【服务1】，使用最新镜像
        ./docker-cluster-service-deploy.sh -M function  -u  -T 2020.12.11  服务1  -F    #--- 更新部署【服务1】，使用版本为【2020.12.11】的镜像
```

日常使用：

```bash
$ ./docker-cluster-service-deploy.sh  -c  -F                             #--- 正常发布所有
$ ./docker-cluster-service-deploy.sh  -c  -F  -V 2.1  -G  服务1 服务2     #--- 灰度发布服务1、服务2，版本号：2.1
$ ./docker-cluster-service-deploy.sh  -u  -F  服务1 服务2                 #--- 更新服务1、服务2
$ ./docker-cluster-service-deploy.sh  -u  -F  service.*                  #--- 更新匹配【service.*】的服务
```

> 项目会根据优先级进行构建与发布



#### 5.3.2 web项目发布

帮助信息如下：

```bash
$ ./deploy/web-release.sh --help

    用途：Web站点发布上线
    依赖：
        /root/deploy-bmp/deploy/nginx.list
        /root/deploy-bmp/deploy/../op/format_table.sh
        /root/deploy-bmp/deploy/../op/dingding_conver_to_markdown_list-deploy.py
        /root/deploy-bmp/deploy/env.sh
        nginx上：/root/nginx-config/web-release-on-nginx.sh
    注意：运行在nginx节点上
        * 【上线（ship）】流程包含以下四个子流程【构建】、【测试（test）】、【部署（deploy）】、【发布（release）】。原地发布（即部署 == 发布）
        * 名称正则表达式完全匹配，会自动在正则表达式的头尾加上【^ $】，请规避
        * 输入命令时，参数顺序不分先后
    用法:
        ./web-release.sh  [-h|--help]
        ./web-release.sh  [-l|--list]                                         #--- 列出项目
        ./web-release.sh  <-M|--mode [normal|function]>  [-r|--release]   <{项目1}  {项目2} ... {项目n} ... {项目名称正则表达式完全匹配}>     #--- 发布上线今天的版本
        ./web-release.sh  <-M|--mode [normal|function]>  [-b|--rollback]  <{项目1}  {项目2} ... {项目n} ... {项目名称正则表达式完全匹配}>     #--- 回滚到上一个版本
    参数说明：
        $0   : 代表脚本本身
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
        ./web-release.sh  -l                 #--- 列出所有项目
        #
        ./web-release.sh  -r                 #--- 发布所有项目
        ./web-release.sh  -r  项目a 项目b    #--- 发布【项目a、项目b】
        #
        ./web-release.sh  -b                 #--- 回滚所有项目
        ./web-release.sh  -b  项目a 项目b    #--- 回滚【项目a、项目b】
        # 服务名称用正则完全匹配
        ./web-release.sh  -r  .*xxx.*           #--- 发布项目名称正则完全匹配【^.*xxx.*$】的第一个项目
        ./web-release.sh  -b  [.]*xxx           #--- 回滚项目名称正则完全匹配【^[.]*xxx$】的第一个项目
        # 外调用★
        ./web-release.sh  -M function  -r                 #--- 函数调用方式发布所有项目
        ./web-release.sh  -M function  -r  项目a 项目b    #---  函数调用方式发布【项目a、项目b】
```

日常使用：

```bash
$ ./web-release.sh  -r                      #--- 发布所有
$ ./web-release.sh  -r  proj.*              #--- 发布正则匹配项目【proj.*】
$ ./web-release.sh  -r  项目a 项目b          #--- 发布项目a、项目b
$ ./web-release.sh  -b  项目a 项目b          #--- 回滚项目a、项目b
```



### 5.4 构建发布一条龙

帮助信息如下：

```bash
$ ./deploy/gogogo.sh --help

    用途：用于项目构建并发布
    依赖脚本：
        /etc/profile.d/run-env.sh
        /root/deploy-bmp/deploy/env.sh
        /root/deploy-bmp/deploy/project.list
        /root/deploy-bmp/deploy/build.sh
        /root/deploy-bmp/deploy/docker-cluster-service.list
        /root/deploy-bmp/deploy/docker-cluster-service-deploy.sh
        /root/deploy-bmp/deploy/../op/format_table.sh
        /root/deploy-bmp/deploy/../op/dingding_conver_to_markdown_list-deploy.py
    注意：
        - 构建完成后的发布：如果目标服务不在运行中，则执行【create】；如果已经存在，则执行【update】。如果是以【create】方式执行，则【-G|--gray】参数有效
    用法:
        ./gogogo.sh  [-h|--help]
        ./gogogo.sh  [-l|--list]
        ./gogogo.sh  <-c [dockerfile|java|node|自定义]>  <-b {代码分支}>  <-e|--email {邮件地址}>  <-s|--skiptest>  <-f|--force>  <-v|--verbose>  <-V|--release-version>  <-G|--gray>  <{项目1}  {项目2} ... {项目n}> ... {项目名称正则匹配}>
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -l|--list      列出可构建的项目清单
        -c|--category  指定构建项目语言类别：【dockerfile|java|node|自定义】，参考：/root/deploy-bmp/deploy/project.list
        -b|--branch    指定代码分支，默认来自env.sh
        -e|--email     发送日志到指定邮件地址，如果与【-U|--user-name】同时存在，则将会被替代
        -s|--skiptest  跳过测试，默认来自env.sh
        -f|--force     强制重新构建（无论是否有更新）
        -v|--verbose   显示更多过程信息
        -G|--gray            : 设置灰度标志为：【gray】，默认：【normal】
        -V|--release-version : 发布版本号
    示例:
        #
        ./gogogo.sh  -l             #--- 列出可构建发布的项目清单
        # 类别
        ./gogogo.sh  -c java                           #--- 构建发布所有java项目，用默认分支
        ./gogogo.sh  -c java  -b 分支a                 #--- 构建发布所有java项目，用分支a
        ./gogogo.sh  -c java  -b 分支a  项目1  项目2   #--- 构建发布node【项目1、项目2】，用分支a（一般可不用-c参数）
        ./gogogo.sh  -c java            项目1  项目2   #--- 构建发布node【项目1、项目2】，用默认分支
        # 一般
        ./gogogo.sh                           #--- 构建发布所有项目，用默认分支
        ./gogogo.sh  -b 分支a                 #--- 构建发布所有项目，用【分支a】
        ./gogogo.sh  -b 分支a  项目1  项目2   #--- 构建发布【项目1、项目2】，用【分支a】
        ./gogogo.sh            项目1  项目2   #--- 构建发布【项目1、项目2】，用默认分支
        # 邮件
        ./gogogo.sh  --email xm@xxx.com  项目1 项目2     #--- 构建发布【项目1、项目2】，将错误日志发送到邮箱【xm@xxx.com】
        # 跳过测试
        ./gogogo.sh  -s  项目1 项目2                     #--- 构建发布【项目1、项目2】，跳过测试
        # 强制重新构建
        ./gogogo.sh  -f  项目1  项目2                    #--- 强制重新构建发布【项目1、项目2】，用默认分支，不管【项目1、项目2】有没有更新
        # 显示更多信息
        ./gogogo.sh  -v  项目1 项目2                     #--- 构建发布【项目1、项目2】，显示更多信息
        # 构建发布带版本号
        ./gogogo.sh  -V 2.2  项目1 项目2                 #--- 构建【项目1、项目2】，发布版本号为【2.2】
        # 构建完成后以灰度方式发布
        ./gogogo.sh  -G          项目1 项目2             #--- 构建【项目1、项目2】，并灰度发布
        ./gogogo.sh  -G  -V 2.2  项目1 项目2             #--- 构建【项目1、项目2】，并灰度发布，发布版本号为【2.2】
        # 项目名称用正则匹配
        ./gogogo.sh   .*xxx.*       #--- 构建发布项目名称正则匹配【.*xxx.*】的项目（包含xxx的），用默认分支
        ./gogogo.sh   [.]*xxx       #--- 构建发布项目名称正则匹配【[.]*xxx】的项目（包含xxx的），用默认分支
        ./gogogo.sh   xxx-          #--- 构建发布项目名称正则匹配【xxx-】的项目（包含xxx-的），用默认分支
        ./gogogo.sh   ^[xy]         #--- 构建发布项目名称正则匹配【^[xy]】的项目（以x或y开头的），用默认分支
        ./gogogo.sh   ^sss          #--- 构建发布项目名称正则匹配【^sss】的目（以sss开头的），用默认分支
        ./gogogo.sh   eee$          #--- 构建发布项目名称正则匹配【eee$】的目（以eee结尾的），用默认分支
        ./gogogo.sh   ^sss.*eee$    #--- 构建发布项目名称正则匹配【^sss.*eee$】的项目（以以sss开头，并且以eee结尾的），用默认分支
        ./gogogo.sh  -c ja  ^sss.*eee$    #--- 构建发布项目类别正则匹配【ja】，且项目名称正则匹配【^sss.*eee$】的项目（以以sss开头，并且以eee结尾的），用默认分支
```

日常使用：

```bash
$ ./gogogo.sh                              #--- 构建发布所有
$ ./gogogo.sh  -G  -V 2.2  项目1 项目2      #--- 构建并灰度发布项目1、项目2
$ ./gogogo.sh  proj.*                      #--- 构建发布正则匹配【proj.*】的项目
```

> 项目会根据优先级进行构建与发布



### 5.5 万宗归一工具

可以通过这一个工具干完几乎所有事情

```bash
$ ./gan.sh --help

    用途：用于远程安装部署。模块说明如下：
    注意：在deploy节点上运行，需要一堆关联脚本
    用法:
        ./gan.sh [-h|--help]    #--- 帮助
        ./gan.sh [-d|--do web|ngx-root|ngx-conf|cert|cert-w|pg-b-r|aliyun-dns|godaddy-dns]  <参数1> ... <参数n>     #--- 参数1...n 是 $1 模块的参数
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -d|--do        某功能模块
                       - build        【build.sh】：项目打包
                       - build-para   【build-parallel.sh】：并行项目打包
                       - gogogo       【gogogo.sh】：项目打包并部署上线
                       - docker       【docker-cluster-service-deploy.sh】：docker服务部署上线、回滚
                       - web          【web-release.sh】：网站代码部署上线、回滚
                       - ngx-dns      【nginx-dns.sh】：网站域名A记录添加或修改
                       - ngx-root     【nginx-root.sh】：网站root目录初始化
                       - ngx-conf     【nginx-conf.sh】：网站nginx配置设置
                       - ngx-cert     【nginx-cert-letsencrypt-a.sh】：网站域名证书申请
                       - ngx-cert-w   【cert-letsencrypt-wildcart.sh】：泛域名证书申请与更新
                       - pg-b-r       【pg_list_backup_or_restore.sh】：备份或还原pg_m上的数据库
                       - aliyun-dns   【aliyun-dns.sh】：修改aliyun dns
                       - godaddy-dns  【godaddy-dns.sh】：修改godaddy dns
    示例:
        #
        ./gan.sh  -h
        ./gan.sh  -d web  -h                 #--- 运行web-release.sh命令帮助
        ./gan.sh  -d web  -r                 #--- 运行web-release.sh命令，发布所有前端项目
        ./gan.sh  -d web  -r  项目a 项目b    #--- 运行web-release.sh命令，发布所有前端【项目a、项目b】

```

一般我会用它初始化nginx的root目录及conf文件及dns A记录，例如：

```bash
# nginx root目录
$ ./gan.sh -d ngx-root --help

    用途：用以在nginx服务器上生成项目站点目录结构
    依赖：
        /etc/profile.d/run-env.sh
        /root/deploy-bmp/init/nginx-config/nginx.list
    注意: 运行在deploy上
    用法:
        /root/deploy-bmp/init/nginx-config/nginx-root.sh  [-h|--help]
        /root/deploy-bmp/init/nginx-config/nginx-root.sh  [-l|--list]
        /root/deploy-bmp/init/nginx-config/nginx-root.sh  <{项目1} {项目2} ... {项目n}>
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -l|--list      列出可构建的项目清单
    示例:
        #
        /root/deploy-bmp/init/nginx-config/nginx-root.sh  -h     #--- 帮助
        /root/deploy-bmp/init/nginx-config/nginx-root.sh  -l     #--- 列出项目清单
        #
        /root/deploy-bmp/init/nginx-config/nginx-root.sh                 #--- 为所有项目建立项目目录
        /root/deploy-bmp/init/nginx-config/nginx-root.sh  项目a 项目b    #--- 为【项目a、项目b】建立项目目录
        
        
$ ./gan.sh -d ngx-root            #--- 为所有项目建立nginx root目录
$ ./gan.sh -d ngx-root 项目1       #--- 为项目1建立nginx root目录
```

```bash
# nginx conf
$ ./gan.sh -d ngx-conf --help

    用途：用以生成项目nginx配置文件，并放置到nginx服务器上
    依赖：
        /etc/profile.d/run-env.sh
        /root/deploy-bmp/init/nginx-config/nginx.list
    注意：运行在deploy节点上
    用法:
        /root/deploy-bmp/init/nginx-config/nginx-conf.sh  [-h|--help]
        /root/deploy-bmp/init/nginx-config/nginx-conf.sh  [-l|--list]
        /root/deploy-bmp/init/nginx-config/nginx-conf.sh  [ [-p|--protocol http] | [-p|--protocol https  -c|--cert wildcard|single] ]  <{项目1}  {项目2} ... {项目n}>
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -l|--list      列出可构建的项目清单
        -p|--protocol  协议，可选值【http|https】
        -c|--cert      证书类型，可选值【wildcard|single】，分别代表泛域名证书或单域名证书
    示例:
        #
        /root/deploy-bmp/init/nginx-config/nginx-conf.sh  -h     #--- 帮助
        /root/deploy-bmp/init/nginx-config/nginx-conf.sh  -l     #--- 列出项目清单
        #
        /root/deploy-bmp/init/nginx-config/nginx-conf.sh  -p http                              #--- http方式，为所有项目创建配置文件
        /root/deploy-bmp/init/nginx-config/nginx-conf.sh  -p http                项目a 项目b   #--- http方式，为【项目a、项目b】创建配置文件
        /root/deploy-bmp/init/nginx-config/nginx-conf.sh  -p https  -c single                  #--- https普通域名证书方式，为所有项目创建配置文件
        /root/deploy-bmp/init/nginx-config/nginx-conf.sh  -p https  -c wildcard                #--- https泛域名证书方式，为所有项目创建配置文件
        /root/deploy-bmp/init/nginx-config/nginx-conf.sh  -p https  -c wildcard  项目a 项目b   #--- https泛域名证书方式，为【项目a、项目b】创建配置文件
        
        
$ ./gan.sh -d ngx-conf  -p https  -c single            #--- 为所有项目生成配置文件并部署，使用https+单域名证书
$ ./gan.sh -d ngx-conf  -p https  -c single  项目1      #--- 为项目1生成配置文件并部署，使用https+单域名证书
```

```bash
# dns A记录
$ ./gan.sh -d ngx-dns --help

    用途：根据/root/deploy-bmp/init/nginx-config/nginx.list，在deploy服务器上添加修改域名A记录
    依赖：
        /etc/profile.d/run-env.sh
        /root/deploy-bmp/init/nginx-config/nginx.list
        /root/deploy-bmp/init/nginx-config/../../op/aliyun-dns.sh
        /root/deploy-bmp/init/nginx-config/../../op/godaddy-dns.sh
    注意: 运行在deploy上
    用法:
        /root/deploy-bmp/init/nginx-config/nginx-dns.sh  [-h|--help]
        /root/deploy-bmp/init/nginx-config/nginx-dns.sh  [-l|--list]
        /root/deploy-bmp/init/nginx-config/nginx-dns.sh  [ -p|--provider aliyun|godaddy|你自定义 ]  <{项目1} {项目2} ... {项目n}>
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -l|--list      列出可构建的项目清单
        -p|--provider  指定你的域名解析提供商，可选择aliyun|godaddy，也可以自己添加，毕竟供应商那么多，我也给不全
    示例:
        #
        /root/deploy-bmp/init/nginx-config/nginx-dns.sh  -h     #--- 帮助
        /root/deploy-bmp/init/nginx-config/nginx-dns.sh  -l     #--- 列出项目清单
        #
        /root/deploy-bmp/init/nginx-config/nginx-dns.sh  -p aliyun                #--- 为所有项目添加域名记录，域名解析为阿里云
        /root/deploy-bmp/init/nginx-config/nginx-dns.sh  -p aliyun  项目a 项目b    #--- 为【项目a、项目b】添加域名记录，域名解析为阿里云
        
     
$ ./gan.sh -d ngx-dns        #--- 为所有项目添加域名A记录
$ ./gan.sh -d ngx-dns 项目1   #--- 为项目1添加域名A记录
```

好了，其他就不一一展示了



### 5.6 其他工具使用

#### 5.6.1 私有仓库docker镜像搜索工具

```bash
$ ./deploy/docker-image-search.sh --help

    用途：查询docker镜像
    依赖：
        /root/deploy-bmp/deploy/env.sh
        /root/deploy-bmp/deploy/docker-cluster-service.list
    注意：
        * 输入命令时，参数顺序不分先后
    用法:
        ./docker-image-search.sh [-h|--help]
        ./docker-image-search.sh [-l|--list]
        ./docker-image-search.sh  <-e|--exclude {%镜像版本%}>  <-t|--tag {%镜像版本%}>  <-n|--newest {第几新版本}>  <-o|--output {路径/文件}>  <{服务1} ... {服务2} ...>
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help       此帮助
        -l|--list       清单
        -e|--exclude    排除指定镜像版本，支持模糊定义，一般用于排除今天打包的镜像版本，用于部署回滚
        -t|--tag        镜像版本(tag)。支持模糊查找
        -n|--newest     取第几新的镜像版本，例如： -n 1 ：代表取最新的那个镜像版本，-n 2：代表第二新的镜像，有-n参数时输出格式为：【服务名  tag版本 tag版本2 ...】；无-n参数时输出为服务名 \ntag版本 \ntag版本2 \n...
        -o|--output     输出搜索结果不为空的服务名称 到 指定【路径/文件】
    示例：
        ./docker-image-search.sh  -h
        ./docker-image-search.sh  -l
        #
        ./docker-image-search.sh                       #--- 返回所有服务所有镜像版本
        ./docker-image-search.sh  服务1                #--- 返回服务名为【服务1】的所有镜像版本
        #
        ./docker-image-search.sh  -e 2021  服务1       #--- 返回服务名为服务1，且tag版本不包含【2021】的所有版本
        ./docker-image-search.sh  -t 2021  服务1       #--- 返回服务名为服务1，且tag版本包含【2021】的所有版本
        ./docker-image-search.sh  -n 1     服务1       #--- 返回服务名为服务1，且最新的镜像tag版本
        ./docker-image-search.sh  -n 2     服务1       #--- 返回服务名为服务1，且次新的镜像tag版本（第二新）
        #
        ./docker-image-search.sh  -t 2021        -n 2            #--- 返回所有服务，且tag名包含【2021】，且次新的镜像tag版本
        ./docker-image-search.sh  -t 2021        -n 2   服务1    #--- 返回服务名为【服务1】，且tag版本包含【2021】，且次新的镜像tag版本
        ./docker-image-search.sh  -e 2021.01.22  -n 1   服务1    #--- 返回服务名为【服务1】，且除tag版本包含【2021.01.22】的镜像外，最新的镜像tag版本，一般用于排除今天【2021.01.22】的版本以回滚
        ./docker-image-search.sh  -e 2021.01.22  -t 20  服务1    #--- 返回服务名为【服务1】，且除tag版本包含【2021.01.22】的镜像外，且tag版本包含【20】的镜像tag版本，返回最新的是个
        #
        ./docker-image-search.sh  -e 2021.01.22  -t 2021.01.01.01  -n 1   #--- 返回所有服务，且tag版本不包含【2021.01.22】，且包含【2021.01.01.01】，最新的tag版本
        # 今日发布与回滚：
        ./docker-image-search.sh  -t 2021.01.22  -n 1  -o /root/1.txt     #--- 返回所有服务，且tag名称包含【2021.01.22】(今天)，最新的镜像tag版本，将服务清单输出到文件/root/1.txt，一般用于发布今天打包的服务清单
        ./docker-image-search.sh  -e 2021.01.22  -n 1  -o /root/1.txt     #--- 返回所有服务，且tag名称不包含【2021.01.22】(今天)，最新的镜像tag版本，将服务清单输出到文件/root/1.txt，一般用于今日发布失败后的回滚
```



#### 5.6.2 阿里云dns查询与修改工具

```bash
$ ./op/aliyun-dns.sh --help

    用途：用于查询修改dns信息
    依赖：
        /etc/profile.d/run-env.sh
        阿里云CLI：aliyun
    注意：
        * 输入命令时，参数顺序不分先后
    用法:
          ./aliyun-dns.sh [-h|--help]
          ./aliyun-dns.sh -A [replace|append|delete|query_domain|query_record]  <-d {域名}>  <-t [A|TXT|RNAME|...]>  <-n {dns记录名}>  <-v {dns记录值}>  <-w {关键字}>
    参数说明：
          -h|--help    此帮助
          -A|--Action  指定操作类型replace|append|delete|query_domain|query_record
          -d|--domain  指定域名，默认为/etc/profile.d/run-env.sh中定义的${DOMAIN}
          -t|--type    指定dns记录类型A|TXT|CNAME|...
          -n|--name    指定dns记录名称
          -v|--value   指定dns记录值
          -w|--keyword 指定搜索关键字，在name及value中匹配
    示例:
          # 增加与修改：
          ./aliyun-dns.sh -A [replace|append]  <-d 域名>  [-t [A|TXT|CNAME|...]]  [-n dns记录名]  [-v dns记录值]     #--- replace：删除现有后新增； append：增加多一条
          # 查询：
          ./aliyun-dns.sh -A query_domain  <-d 域名>                                          #--- 查询域名信息
          ./aliyun-dns.sh -A query_record  <-d 域名>                                          #--- 查询域名下所有记录
          ./aliyun-dns.sh -A query_record  <-d 域名>  [-t [A|TXT|CNAME|...]]                  #--- 查询域名下该类型所有的记录
          ./aliyun-dns.sh -A query_record  <-d 域名>  [-t [A|TXT|CNAME|...]]  [-n dns记录名]  #--- 查询域名下该类型该 名称 所有的记录
          ./aliyun-dns.sh -A query_record  <-d 域名>  [-w 关键字]                             #--- 查询域名下模糊匹配该 名称或值 所有的记录
          ./aliyun-dns.sh -A query_record  <-d 域名>  [-t [A|TXT|CNAME|...]]  [-w 关键字]     #--- 查询域名下该类型模糊匹配该 名称或值 所有的记录(此功能aliyun有bug)
```



#### 5.6.3 godaddy dns查询与修改工具

```bash
$ ./op/godaddy-dns.sh --help

    用途：用于查询修改dns信息
    依赖：
    注意：
    用法:
          ./godaddy-dns.sh [-h|--help]
          ./godaddy-dns.sh -A [replace|append|delete|query_domain|query_record]  <-d {域名}>  <-t [A|TXT|RNAME|...]>  <-n {dns记录名}>  <-v {dns记录值}>
    参数说明：
          -h|--help    此帮助
          -A|--Action  指定操作类型replace|append|delete|query_domain|query_record
          -d|--domain  指定域名，默认为/etc/profile.d/run.env.sh中定义的${DOMAIN}
          -t|--type    指定dns记录类型A|TXT|RNAME|...
          -n|--name    指定dns记录名称
          -v|--value   指定dns记录值
    示例:
          # 增加与修改：
          ./godaddy-dns.sh -A [replace|append]  <-d 域名>  [-t [A|TXT|RNAME|...]]  [-n dns记录名]  [-v dns记录值]     #--- replace：删除现有后新增； append：增加多一条
          # 查询：
          ./godaddy-dns.sh -A query_domain  <-d 域名>                                          #--- 查询域名信息
          ./godaddy-dns.sh -A query_record  <-d 域名>                                          #--- 查询域名下所有记录
          ./godaddy-dns.sh -A query_record  <-d 域名>  [-t [A|TXT|RNAME|...]]                  #--- 查询域名下该类型所有的记录
          ./godaddy-dns.sh -A query_record  <-d 域名>  [-t [A|TXT|RNAME|...]]  [-n dns记录名]  #--- 查询域名下该类型该名称所有的记录
```



#### 5.6.4 泛域名证书申请与续期工具（支持阿里云、腾讯云、华为云、godaddy，借助了第三方项目）

```bash
$ ./op/cert-letsencrypt-wildcart.sh --help

    用途：用于申请与更新泛域名证书
          更新Letsencrypt泛域名证书，拷贝到nginx服务器，然后reload
    依赖：
        /etc/profile.d/run-env.sh
        certbot
        /root/deploy-bmp/op/certbot-letencrypt-wildcardcertificates-sh/au.sh
    注意：
        * 本脚本基于项目https://github.com/ywdblog/certbot-letencrypt-wildcardcertificates-alydns-au
        * 输入命令时，参数顺序不分先后
    用法:
        ./cert-letsencrypt-wildcart.sh  [-h|--help]
        ./cert-letsencrypt-wildcart.sh  [-y|--yun [aly|hwy|godaddy]]  [ [-r|--request=]<{主域名}> | [-u|--update=]<{主域名}> ]  <-t|--test>   #--- 申请或renew泛域名证书
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help         此帮助
        -y|--yun          指定dns解析商，aly：阿里云；txy：腾讯云；hwy：华为云；godaddy，需要设置certbot-letencrypt-wildcardcertificates-sh/au.sh中相应的key、secret
        -r|--request      申请Letsencrypt泛域名证书，短-选项与参数之间不能有空格，默认主域名为run-env.sh中定义的${DOMAIN}
        -u|--update       renew泛域名证书，要求同上
        -t|--test         以--dry-run方式运行演练测试
    示例:
        ./cert-letsencrypt-wildcart.sh  -h
        ./cert-letsencrypt-wildcart.sh  -y aly  -r  -t              #--- 测试申请泛域名证书，dns域名解析商是阿里云，域名是默认为run-env.sh定义的${DOMAIN}
        ./cert-letsencrypt-wildcart.sh  -y aly  -r                  #--- 申请泛域名证书，dns域名解析商是阿里云，域名是默认为run-env.sh中定义的${DOMAIN}
        ./cert-letsencrypt-wildcart.sh  -y aly  -raaa.com           #--- 申请泛域名证书，dns域名解析商是阿里云，域名是aaa.com
        ./cert-letsencrypt-wildcart.sh  -y aly  -u                  #--- 更新泛域名证书，dns域名解析商是阿里云，域名是默认为run-env.sh中定义的${DOMAIN}
```



#### 5.6.5 邮件发送工具

```bash
$ ./op/send_mail.sh --help

    用途：使用mailx发送邮件
    依赖：
        mailx
        /usr/local/bin/dingding_send_markdown.py
    注意：
        * 输入命令时，参数顺序不分先后
    用法：
        ./send_mail.sh [-h|--help]
        ./send_mail.sh [-s|--subject {主题}]  [-c|--content {邮件内容}]  <[-a|--attach {文件名1}] ... [-a|--attach {文件名n}]>  <-o|--origin-option [{mailx选项]}>  [{收件人1} ... <{收件人n}>]
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help       查看本帮助
        -s|--subject    邮件主题，注意事项：为避免空格问题，一定要用引号引起来，不管是字符串还是变量
        -c|--content    邮件内容，注意事项同上
        -a|--attach     邮件附件，可以有多个
        -o|--origin-option     mailx自带的其他非必须参数选项，可以有多个，注意事项同上
    示例：
        # 一般用法：(-a 附件文件名不能有空格)
        ./send_mail.sh  [-s "邮件主题"]  [-c "邮件内容"]  <[-a 文件名1] ... <[-a 文件名n]>>   [收件人1] ... <收件人n>

        # -c 之 邮件内容高级用法(邮件主题同之)：
        ./send_mail.sh  [-s 邮件主题]    [-c "[邮件内容]" | "`echo ${邮件内容变量}`" | "`cat 邮件内容文件名`" ]   [收件人1] ... <收件人n>

        # -o 之 mailx自带的高级选项用法，例如：添加-c、-b，如下：(更多高级选项请参考man mailx)
        ./send_mail.sh  [-s 邮件主题]    [-c "[邮件内容]" ]  <[-o "-c 抄送地址"] ... <-o "-b 暗送地址">>   [收件人1] ... <收件人n>
        # 例如：(注意,分隔处不能有空格)
        ./send_mail.sh  -s "${SS}" -c "222 33" -o "-c admin@gc.com,zhu@gc.com" -o "-b 猪猪侠@163.com"  reg@gc.com
        ./send_mail.sh  -s "${SS}" -c "222 33" -o "-c admin@gc.com,zhu@gc.com      -b 猪猪侠@163.com"  reg@gce.com
```



#### 5.6.6 将数据输出为表格工具1

```bash
$ ./op/format_table.sh --help

    用途：将数据输出为表格
    依赖：
    注意：
        * 输入命令时，参数顺序不分先后
    用法:
        ./format_table.sh [-h|--help]
        ./format_table.sh <-d|--delimeter {分隔符}>  <-t|--title {字段名1, 字段名2, ...}>  <-r|--row {值1, 值2, ...}>  <-f|--file {文件x}    #--- 默认分隔符为【,】
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -d|--delimeter  : 表格分隔符，默认分隔符为【,】
        -t|--title      ：标题，例如： 'aa, bb,cc'
        -r|--row        : 行，例如：'aaaa, bbbbb,cccc'
        -f|--file       : 表格文件名
    示例：
        #
        ./format_table.sh          -f 文件1          #--- 默认分隔符，标题与内容皆取自【文件1】
        ./format_table.sh  -d '|'  -f 文件1          #--- 分隔符为【|】，标题与内容皆取自【文件1】
        #
        ./format_table.sh  -d '|'  -t 'A|B|C'  -r 'aa|bb|cc'  -r 'vv| |xx'    #--- 定义标题，内容取自【'aa|bb|cc' ； 'vv| |xx'】
        ./format_table.sh  -d '|'  -t 'A|B|C'  -f 文件1                       #--- 定义标题，内容取自【文件1】
```



#### 5.6.7 将数据输出为表格工具2（彩色）

```bash
$ ./op/draw_table.sh --help

    用途：将文件以表格的形式输出
    依赖：
    注意：
        * 默认使用【\t】作为表格分隔符，如果是其他，请自行指定，否则会出错；
        * 表格连标题一起至少2行，至少有一行有2个及以上的字段，否则出错。
        * 输入命令时，参数顺序不分先后
    用法：
        ./draw_table.sh [-h|--help]
        ./draw_table.sh <-d|--delimeter {表格分隔符}>  <-s|--style [预定义样式 | {%自定义样式}]>  <-c|--color [预定义颜色前景,背景,文字 | {%自定义颜色}]>  < {文件名}
        echo -e "AB\na\tb ......" | ./draw_table.sh <-d|--delimeter {表格分隔符}>  <-s|--style [预定义样式 | {%自定义样式}]>  <-c|--color [预定义颜色前景,背景,文字 | {%自定义颜色}]>
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -d|--delimeter ：定义表格列之间的分隔符，默认为【\t】
        -s|--style     ：定义表格样式，默认为【+++++++++,---|||】
                         # 前9位表示表格边框，第10位表示填充字符，第11-13 表示行的上、中、下分隔符，第14-16表示列的左、中、右分隔符
                         s0  :'                '        s8  : └─┘│┼│┌─┐ ─ ─│ │
                         s1  : └┴┘├┼┤┌┬┐ ───│││         s9  : ╚╩╝╠╬╣╔╦╗ ═ ═║ ║
                         s2  : └─┘│┼│┌─┐ ───│││         s10 : ╚═╝║╬║╔═╗ ═ ═║ ║
                         s3  : ╚╩╝╠╬╣╔╦╗ ═══║║║         s11 : ╙╨╜╟╫╢╓╥╖ ─ ─║ ║
                         s4  : ╚═╝║╬║╔═╗ ═══║║║         s12 : ╘╧╛╞╪╡╒╤╕ ═ ═│ │
                         s5  : ╙╨╜╟╫╢╓╥╖ ───║║║         s13 : ╘╧╛╞╪╡╒╤╕ ═ ═│ │
                         s6  : ╘╧╛╞╪╡╒╤╕ ═══│││         s14 : ╚╩╝╠╬╣╔╦╗ ───│││
                         s7  : └┴┘├┼┤┌┬┐ ─ ─│ │         s15 : +++++++++ ---|||
                         # 自定义
                         以【%】开头，比如：【%123456789 abcABC】
                         #
        -c|--color     ：定义表格颜色，默认为【@4,@8,@4】，含义为【拐角颜色,文字颜色,表格颜色】，或理解为【背景,前景,表格】颜色
                         # 颜色定义：
                         @1|@black         @5|@blue
                         @2|@red           @6|@purple
                         @3|@green         @7|@cyan
                         @4|@yellow        @8|@white
                         # 组合颜色
                         1  : @2,@8,@3
                         2  : @2,@8,@5
                         3  : @2,@5,@8
    示例：
        # 表格输入
        ./draw_table.sh  < 文件1                      #--- 将【文件1】输出为表格，所有皆为默认
        echo -e AB\na\tb | bash ./draw_table.sh       #--- 将echo内容输出为表格，所有皆为默认
        # 分隔符
        ./draw_table.sh        < 文件1                #--- 使用默认分隔符
        ./draw_table.sh  -t :  < 文件1                #--- 使用默认分隔符【:】
        ./draw_table.sh  -t |  < 文件1                #--- 使用默认分隔符【|】
        # 样式
        ./draw_table.sh  -s s15                  < 文件1       #--- 使用表格样式【s15】
        ./draw_table.sh  -s '%123456789 abcABC'  < 文件1       #--- 使用自定义表格样式【%123456789 abcABC】
        # 颜色
        ./draw_table.sh  -c @red,@blue,@white              < 文件1       #--- 使用背景前景表格颜色为【红,蓝,外】
        ./draw_table.sh  -c @2,@5,@8                       < 文件1       #--- 同上
        ./draw_table.sh  -c 3                              < 文件1       #--- 同上
        ./draw_table.sh  -c \033[31m,\033[34m,\033[29m     < 文件1       #--- 同上
        #
        ./draw_table.sh  -t :  -s s15                        < 文件1     #--- 使用【:】作为分隔符，【s15】为表格样式
        ./draw_table.sh  -t :          -c @2,@5,@8           < 文件1     #--- 使用【:】作为分隔符，【红,蓝,外】为表格颜色
        ./draw_table.sh        -s s15  -c @red,@blue,@white  < 文件1     #--- 使用【s15】为表格样式，【红,蓝,外】为表格颜色
        ./draw_table.sh  -t :  -s s15  -c @red,@blue,@white  < 文件1     #--- 使用【:】作为分隔符，【s15】为表格样式，【红,蓝,外】为表格颜色
```



#### 5.6.8 钉钉消息发送工具

```bash
$ ./init/envs.sample/dingding_send_markdown.py
# 用法： ./dingding_send_markdown.py  --title='sssss'  --message="`cat mmm.txt`"
#        ./dingding_send_markdown.py  --title 'sssss'  --message "$( echo -e "### 用户：${USER} \n### 时间：${TIME} \n\n" )"
#        ./dingding_send_markdown.py  --title 'sssss'  --message "$( echo -e "### 用户：${USER} \n### 时间：`date` \n\n" )"
# 请将变量【dingding_api_url】修改为你自己的
```

```bash
$ ./init/envs.sample/dingding_conver_to_markdown_list.py
# 用法： ./dingding_conver_to_markdown_list.py "[Title]"
#        ./dingding_conver_to_markdown_list.py "[Title]" "aaa"
#        ./dingding_conver_to_markdown_list.py "[Title]" "aaa" "bbb"
#        ./dingding_conver_to_markdown_list.py "[Title]" "aaa" "bbb" ... "<list>"
# 请将变量【api_url】修改为你自己的
```



#### 5.6.9 登录警报

```bash
$ ./init/send_login_alert_msg.sh

# 用途：用户登录时发送消息通知
# 注意：脚本拷贝到/etc/profile.d/下
       # 自动从/etc/profile.d/run-env.sh引入以下变量，以实现IP白名单及其他依赖变量：
       # RUN_ENV=${RUN_ENV:-'dev'}
       # EMAIL=${EMAIL:-"kevinzu@xxx.com"}
       # TRUST_IPS=${TRUST_IPS:-'办公室:111.111.111., 家:222.222.22'}
# 依赖：/etc/profile.d/run-env.sh
#       /usr/local/bin/dingding_send_markdown-login.py
# 用法：
#      用户登录时自动执行/etc/profile.d/下的脚本，包含本程序
```



#### 5.6.10 旧docker镜像清理工具

```bash
$ ./init/delete-docker-registry-image/clean_old_versions.py
$ ./init/delete-docker-registry-image/delete_docker_registry_image.py
# 用法（详细请看README.md）：
export REGISTRY_DATA_DIR="/srv/docker/docker_registry/data/docker/registry/v2" \
; cd /root/delete-docker-registry-image \
; ./clean_old_versions.py -s ./delete_docker_registry_image.py  -i gcl  -u https://127.0.0.1:5000 -l 30  -U ufipf -P 123456  --no_check_certificate \
; docker exec -ti dockerregistry_docker_registry_1   registry garbage-collect /etc/docker/registry/config.yml
```



#### 5.6.11 pg数据备份还原工具

```bash
$ ./pg_backup_or_restore.sh --help

    用途：用于pg数据库备份or还原，一次仅处理一个数据库。
    依赖：
        /root/postgresql_daemon.sh
        /backup/pg/pg_backup_or_restore_by_user_postgres.sh
    注意：需在root账户下运行，会自动设置访问限制、删库、创建、导入、取消限制。
    用法:
        ./pg_backup_or_restore.sh  [-h|--help]
        ./pg_backup_or_restore.sh  [-b|--backup]   {PATH/TO/FILENAME}  {数据库名}     #--- 备份，文件格式为gzip，备份时会自动在指定的名字后面自动加上.gz
        ./pg_backup_or_restore.sh  [-r|--resotore] {PATH/TO/FILENAME}  {数据库名}     #--- 恢复，文件须为gzip格式
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        #
        -b|--backup      备份
        -r|--resotore    还原
    示例:

```

```bash
 ./pg_list_backup_or_restore.sh --help

    用途：用于pg数据库备份or还原，仅备份或恢复pg_db.list中的数据库。
    依赖：
        /root/postgresql_daemon.sh
        /backup/pg/pg_list_backup_or_restore_by_user_postgres.sh
    注意：需在root账户下运行，在还原时会自动设置访问限制、删库、创建、导入、取消限制。
    用法：
        ./pg_list_backup_or_restore.sh [-h|--help]
        ./pg_list_backup_or_restore.sh [-b|--backup]   <-d|--path-dir {备份目录路径}>   <-c<{目标路径}>|--copy-to-path=<{目标路径}>>   #--- 特别注意-c参数用法
        ./pg_list_backup_or_restore.sh [-r|--resotore] [-d|--path-dir {备份目录路径}]
        ./pg_list_backup_or_restore.sh [-s|--search]   <-p|--search-path {搜索父目录}>  <-n|--search-name {搜索子目录名}>
    参数说明：
        $0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        #
        -b|--backup          备份
        -r|--resotore        还原
        -s|--search          搜索备份，用来帮助选择用以还原的备份
        -d|--path-dir        目录，可以是相对或绝对路径。在备份时，目标目录必须是不存在的或者是空的，且可写，默认路径为./bak；在还原时，必须是已存在的，可读
        -c|--copy-to-path    拷贝副本到新路径，默认为/oss/backup/pg-pufi/${YEAR}
        -p|--search-path     指定搜索路径，可以是相对或绝对路径，默认为/oss/backup/pg-pufi/${YEAR}
        -n|--search-name     指定搜索子目录名，支持模糊搜索，默认为修改日期最新的那个
    示例:
        # 备份：
        ./pg_list_backup_or_restore.sh  -b                          #--- 备份到默认目录
        ./pg_list_backup_or_restore.sh  -b  -c./aa/bbb              #--- 备份到默认目录，并拷贝副本到./aa/bbb目录下
        ./pg_list_backup_or_restore.sh  -b  -d ./xxx                #--- 备份到./xxx目录下
        ./pg_list_backup_or_restore.sh  -b  -d ./xxx -c./aa/bbb     #--- 备份到./xxx目录下，并拷贝副本到./aa/bbb目录下
        # 还原：
        ./pg_list_backup_or_restore.sh  -r  -d ./xxx/nnn            #--- 从./xxx/nnn还原数据库
        # 搜索：
        ./pg_list_backup_or_restore.sh  -s                          #--- 在默认位置搜索最新的备份
        ./pg_list_backup_or_restore.sh  -s  -n nnn                  #--- 在默认位置搜索名字为nnn的备份
        ./pg_list_backup_or_restore.sh  -s  -p ./aaa/bbb            #--- 在./aaa/bbb目录下搜索最新备份
        ./pg_list_backup_or_restore.sh  -s  -p ./aaa/bbb  -n nnn    #--- 在./aaa/bbb目录下搜索名字为*nnn*的备份
```



## 6 后话

**写文档是停费神的，将就看吧。如果你在使用中遇到任何问题请在Issues中提出，或留下联系方式线下沟通也可以。**

![mmexport1654556730558-2](https://img-blog.csdnimg.cn/img_convert/9b8748abeedc4f8eef5a2e69baec8c64.jpeg)

**写文档是停费神的，将就看吧。如果你在使用中遇到任何问题请在Issues中提出，或留下联系方式线下沟通也可以。**



## 7 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request

## 8 特技

1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md
2.  Gitee 官方博客 [blog.gitee.com](https://blog.gitee.com)
3.  你可以 [https://gitee.com/explore](https://gitee.com/explore) 这个地址来了解 Gitee 上的优秀开源项目
4.  [GVP](https://gitee.com/gvp) 全称是 Gitee 最有价值开源项目，是综合评定出的优秀开源项目
5.  Gitee 官方提供的使用手册 [https://gitee.com/help](https://gitee.com/help)
6.  Gitee 封面人物是一档用来展示 Gitee 会员风采的栏目 [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
