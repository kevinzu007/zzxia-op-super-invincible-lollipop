# zzxia-om-super-invincible-lollipop
猪猪侠之运维超级无敌棒棒糖

## 1 介绍

这是一套集环境搭建，代码构建、部署、发布及周边的运维工具箱。适合基于微服务与docker集群的项目使用。当然这些工具也可以独立使用，比如项目构建、部署发布、dns修改、非白名单登录警报、数据库备份归>档还原、表格绘制、申请与续签（泛）域名证书等，具体参考帮助


### 1.1 特点

- 项目构建：可以指定构建方法、输出方法、一键发布方式等（使用自带python钩子程序或其他钩子程序自动化构建发布也很方便）
- 发布环境：支持多种docker容器编排：swarm、k8s、docker-compose（主流工具只支持k8s）；支持目录式发布：nginx等
- 项目发布：可以指定发布相关的所有参数与变量，这个参数变量可以是全局的，也可以是某一项目专有的，这里包括但不限于服务运行参数、变量、端口、副本数、Java运行参数变量，容器变量、容器启动命令参数
等。只需要修改项目发布清单就可以搞定所有项目，方便快捷（不同于一般系统那种每个项目都是一个独立配置文件，难以批量修改，与主流helm工具大相径庭）
- 多环境统一配置，极大降低环境差异造成的参数差异隐患
- 所有微服务在同一个表格中完成配置，非常方便对比差异与增加，和主流helm使用了完全相反的实现理念
- 结果输出界面美观清晰，有表格及颜色区分，也包含耗时、进度条与邮箱手机消息通知
- 标准化错误输出，通过错误消息及代码，可以轻松知道问题所在
- shell语言，模块化编码，使得每个人可以轻松的增加自己的专属功能


### 1.2 适用条件

- 适用于基于微服务docker集群架构与或nginx前端。主要提供java、node语言类别项目（其他语言项目也可以，只需添加相关语言模块即可，这很简单，只是构建命令不一样而已，其他大同小异）

- 特别适用于规矩少，构建发布分支比较随意的中小团队（一般少于50人），脚本命令使用简单，帮助齐全，可以实现你想要的任意构建与发布要求，也可以把这些代码集成到你的CI/CD中（比如Jenkins），实现标准
化管理，对于大团队也可以轻松嵌入

- 从开发层面：使用不固定分支发布代码，使用高度可选择的发布项目、发布时间、发布参数，比如：随意发布某项目、某分支、跳过测试、无更新强制发布、构建日志与结果通知方式、开发自助等（Jenkins适合较>
为固定分支，固定发布条件，特别适合大团队），微服务架构下，随便都是几十上百的项目，如果没有自动化，在网页上点击要发布的项目真是折磨，这比使用脚本发布会慢很多很多，使用这个，初期开发人员可能会
根据过往经验抵触这种发布方式，当他们用久了就会喜欢上这种发布方式，因为这种自己掌控的感觉会让他们欲罢不能

- 从运维层面：通过脚本初始化环境，无需手动进行，添加新项目时，只需维护envs中的清单及相关定制化变量即可，无需大动干戈（可能有些人喜欢一个项目维护一个或几个静态配置文件，如果有多个项目需要修改
时，就需要修改一批文件，这会很低效，而在这里，把所有项目参数都集中起来，全部清单化，只需要修改两三个个配置文清单文件即可），开发人员可以自行完成构建发布（开发测试环境），无需运维在场，构建发布一条命令搞定，发布态势运维可随时掌控，省心省力。另外shell脚本不像Jenkins，运维人都会shell语言编程，可以根据自己的需要定制，而且这些脚本都是模块化的，而且关键点都有注释，自己修改也很容易。>一切尽在掌握，这是运维人的终极追求，不是吗？



### 1.3 功能

- 环境搭建：这个对于每个公司可能会有所不同，但大同小异，自己调整或用其他方式搭建
- 参数初始化：初始化环境，为构建发布做准备
- nginx项目配置初始化：根据参数文件初始化项目目录、配置文件(http|https、端口、运行方式、后端端口、附加配置等)，自动添加修改域名A记录，自动申请https证书
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
<img src="https://img-blog.csdnimg.cn/20210429155627295.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3poZl9zeQ==,size_16,color_FFFFFF,t_70#pic_center" alt="打赏" style="zoom:50%;" />



## 2 软件架构

Linux shell
Python
关系图:



## 3 安装教程


### 服务器准备

一般配置：
| 服务器类别 | 数量 | 说明         | 例如       |
| deploy     | 1    | 用于构建与发布 |          |
| docker集群 | 1~n  | 根据自己需要 | swarm      |
| nginx      | 0~n  | 根据自己需要 |            |
| db         | 0~n  | 根据自己需要 | postgresql |
| docker仓库 | 0~1  | 根据自己需要 | docker registry |
| maven仓库  | 0~1  | 根据自己需要 | nexus      |
| 代码仓库   | 0~1  | 根据自己需要 | 私有gitalb |

系统必须：
运行在Linux系统之上，基本环境安装部分是基于CentOS，如果你用的是Ubuntu，可是自行修改，或手动安装


### 功能与依赖

- 构建工具（build.sh；build-parallel.sh；gogogo.sh）

| 序号 | 类别       | 构建方法            | 输出方法           | 必要软件环境                                |
| :--: | ---------- | ------------------- | ------------------ | ------------------------------------------- |
|  1   | product    | NONE                | NONE               |                                             |
|  2   |            |                     | docker_image_push  | docker；docker仓库                          |
|  3   | Dockerfile | docker_bulid        | NONE               | docker                                      |
|  4   |            |                     | docker_image_push  | docker；docker仓库                          |
|  5   | Java       | mvn_package或gradle | NONE               | java_jdk；maven或gradle                     |
|  6   |            |                     | deploy_war         | java_jdk；maven或gradle                     |
|  7   |            |                     | deploy_jar_to_repo | java_jdk；maven或gradle；maven仓库          |
|  8   |            |                     | docker_image_push  | java_jdk；maven或gradle；docker；docker仓库 |
|  9   | Node       | npm_install         | NONE               | node；npm                                   |
|  10  |            |                     | docker_image_push  | node；npm；docker；docker仓库               |
|  11  |            | npm_build           | direct_deploy      | node；npm                                   |
|  12  |            |                     | docker_image_push  | node；npm；docker；docker仓库               |

- 发布工具（docker-cluster-service-deploy.sh；web-release.sh；gogogo.sh）

| 序号 | 类别           | 部署类型             | 必要软件环境           |
| :--: | -------------- | -------------------- | ---------------------- |
|  1   | docker_cluster | swarm                | docker；swarm          |
|  2   |                | k8s                  | docker；k8s            |
|  3   |                | docker-compose       | docker；docker-compose |
|  4   | web_release    | nginx或其他web服务器 | nginx或其他web服务器   |

- 其他工具

| 序号 | 脚本                                          | 用途                              | 必要软件环境                             |
| :--: | --------------------------------------------- | --------------------------------- | ---------------------------------------- |
|  1   | deploy/docker-image-search.sh                 | 从私有docker仓库搜索docker镜像    | docker；docker仓库                       |
|  2   | deploy/docker-tag-push.sh                     | 推送docker镜像到私有docker仓库    | docker；docker仓库                       |
|  3   | op/aliyun-dns.sh                              | 用阿里云dns做解析的域名修改工具   | 阿里云CLI                                |
|  4   | op/godaddy-dns.sh                             | 用Godaddy dns做解析的域名修改工具 | curl                                     |
|  5   | op/cert-letsencrypt-wildcart.sh               | 在Let'sencrypt上申请泛域名证书    | certbot                                  |
|  6   | op/send_mail.sh                               | 发送邮件                          | mailx                                    |
|  7   | op/dingding_conver_to_markdown_list-deploy.py | 发送钉钉消息                      | python                                   |
|  8   | op/format_table.sh                            | 格式化表格                        | awk                                      |
|  9   | op/draw_table.sh                              | 严格格式化表格                    | awk                                      |
|  10  | init/1-sshkey-copy.sh                         | 免密登录                          | sshpass                                  |
|  11  | init/send_login_alert_msg.sh                  | 发送用户登录警报消息              | python                                   |
|  12  | init/send_mail_attach_my_log.sh               | 发送自定义日志到邮箱              | mailx                                    |
|  13  | init/nginx-config/nginx-cert-letsencrypt-a.sh | 在Let'sencrypt上申请A域名证书     | certbot；nginx                           |
|  14  | init/nginx-config/nginx-root.sh               | 创建nginx web站点目录             |                                          |
|  15  | init/nginx-config/nginx-conf.sh               | 创建nginx配置文件                 | nginx                                    |
|  16  | init/nginx-config/nginx-dns.sh                | 创建nginx站点域名A记录            | op/aliyun-dns.sh；<br> op/godaddy-dns.sh |
|  17  | init/nginx-config/web-release-on-nginx.sh     | 上线或回滚nginx站点               | nginx                                    |
|  18  | init/pg/backup/pg_backup_or_restore.sh        | pg数据库备份                      | pg                                       |
|  19  | init/pg/backup/pg_list_backup_or_restore.sh   | pg数据库备份指定清单              | pg                                       |
|  20  | 其他                                          | 略                                |                                          |



### 3.1 克隆

克隆项目到deploy主机上


### 3.2 创建自己的专属环境配置文件

基于【项目home路径/init/envs.sample】示例创建自己的环境变量文件，一般方法是`cp -r  项目home路径/init/envs.sample  项目home路径/init/envs-myname`，然后修改`home路径/init/envs-myname`中的配置文件，配置文件的修改请参考【init/envs.sample/README.md】

打开终端，进入目录【项目home路径/init】，运行【./0-init-envs.sh -c  -f ./envs-myname】



### 3.3 免密登录

以下皆在目录【项目home路径/init】下完成

- ssh登录跳过RSA key"yes/no"验证，会话保持
```bash
# 在/etc/ssh/ssh_config中修改
    StrictHostKeyChecking no
    ServerAliveInterval 60
```

- 生成sshkey用于免密登录
略

- ssh免密登录设置
```bash
./1-sshkey-copy.sh  [用户]  [密码]  host-ip.list
```


### 3.4 为了减少异常发生，你可能需要关掉一些麻烦：

关闭防火墙，略
关闭selinux，略


### 3.5 base安装设置

以下皆在目录【项目home路径/init】下完成

```bash
ansible-playbook  install-hosts.yml
ansible-playbook  install-base.yml
ansible-playbook  install-config-base.yml
# reboot 重新装载变量RUN_ENV
ansible all --become -m shell -a "reboot"
```


### 3.6 创建自己的密码相关配置文件

基于【项目home路径/init/my_sec.sample】示例创建自己的密码相关配置文件，一般方法是`cp -r  项目home路径/init/my_sec.sample  项目home路径/init/my_sec`，然后修改`home路径/init/my_sec`中的配置>文件，配置文件的修改请参考【init/envs.sample/README.md】




## 4 使用说明
请使用-h|--help参数运行sh脚本即可看到使用帮助


### 4.1 环境变量文件`kvm.env`

基于`kvm.env.sample`创建环境变量文件`kvm.env`，根据你的环境修改相关环境变量，这个非常重要，否则你可能运行出错








docker镜像搜索工具
nginx自动化项目配置
独立域名及泛域名证书的自动化申请与续签，
dns管理工具(阿里云、godaddy)、
仓库管理工具、
数据库自动化备份归档还原工具
非白名单服务器登录警报
shell表格绘制工具
邮件
钉钉



构建：
构建java、node、dockerfile项目，其他项目可以自行添加（都是模块化，很容易添加）
java项目主要输出为docker镜像，以便于部署到docker集群
node项目输出为docker镜像或直接部署到nginx服务器目录中等待发布
dockerfile项目输出为docker镜像，以便于部署到docker集群
以上提供并行构建、静默构建

发布：
java或node类等docker镜像部署到docker集群
node类直接部署到nginx服务器的将其link发布上线
以上皆提供发布回滚功能，也提供一键构建与发布

运行：
docker镜像运行在docker集群下：k8s、swarm、docker-compose，需要自行搭建集群
node项目也可以运行在实体nginx下


构建：
语言类别为：java、node、dockerfile、其他，提供构建服务
输出成品类型为：war、推送jar到maven仓库、推送到docker镜像仓库、直接部署

发布：
发布方式：docker服务、发布上线


仓库：
gitlab
maven repository
docker registary repository


软件：
java
maven
node

docker
swarm
k8s

nginx
certbot
数据库：pg、oracle、mysql

ansible
mail
钉钉



envs/
my_envs/
.my_sec/






# zzxia-om-super-invincible-lollipop

#### 介绍
zzxia-om-super-invincible-lollipop超级无敌棒棒糖

#### 软件架构
软件架构说明


#### 安装教程

1.  xxxx
2.  xxxx
3.  xxxx

#### 使用说明

1.  xxxx
2.  xxxx
3.  xxxx

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


#### 特技

1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md
2.  Gitee 官方博客 [blog.gitee.com](https://blog.gitee.com)
3.  你可以 [https://gitee.com/explore](https://gitee.com/explore) 这个地址来了解 Gitee 上的优秀开源项目
4.  [GVP](https://gitee.com/gvp) 全称是 Gitee 最有价值开源项目，是综合评定出的优秀开源项目
5.  Gitee 官方提供的使用手册 [https://gitee.com/help](https://gitee.com/help)
6.  Gitee 封面人物是一档用来展示 Gitee 会员风采的栏目 [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
