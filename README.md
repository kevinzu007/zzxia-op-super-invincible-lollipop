# zzxia-om-super-invincible-lollipop
猪猪侠之运维超级无敌棒棒糖

## 1 介绍

这是一套集环境搭建，代码构建、部署、发布及周边的运维工具箱。适合基于微服务与docker集群的项目使用。当然这些工具也可以独立使用，比如项目构建、部署发布、dns修改、非白名单登录警报、数据库备份归>档还原、表格绘制、申请与续签（泛）域名证书等，具体参考帮助


### 1.1 特点

- 项目构建：可以指定构建方法、输出方法、一键发布方式等（使用自带python钩子程序或其他钩子程序自动化构建发布也很方便）
- 发布环境：支持多种docker容器编排：swarm、k8s、docker-compose；支持目录式发布：nginx
- 项目发布：可以指定发布相关的所有参数与变量，这个参数变量可以是全局的，也可以是某一项目专有的，这里包括但不限于服务运行参数、变量、端口、副本数、Java运行参数变量，容器变量、容器启动命令参数
等。只需要修改项目发布清单就可以搞定所有项目，方便快捷（不同于一般系统那种每个项目都是一个独立配置文件，难以批量修改，与主流helm工具大相径庭）
- 多环境统一配置，极大降低环境差异造成的参数差异隐患
- 结果输出界面美观清晰，有表格及颜色区分，也包含耗时及进度条
- markdown格式消息通知
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


### 3.1 克隆

克隆项目到deploy主机上

### 3.2 创建自己的专属环境配置文件

基于【项目home路径/init/envs.sample】示例创建自己的环境变量文件，一般方法是`cp -r  项目home路径/init/envs.sample  项目home路径/init/envs-myname`，然后修改`home路径/init/envs-myname`中的配置文件，配置文件的修改请参考【init/envs.sample/README.md】

打开终端，运行【项目home路径/init/0-init-envs.sh -c  -f ./envs-myname】，完成环境的基本设置，此时你可能需要重新启动【deploy】主机以使环境变量生效


为了减少异常发生，你可能需要关掉一些麻烦：
```bash
# 关闭防火墙
# 略
# 关闭selinux
# 略
# ssh登录跳过RSA key"yes/no"验证
#StrictHostKeyChecking no
```

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
