# 运行环境相关文件


## 重要说明

- 此目录的文件仅为为【init/0-init-envs.sh】所用
- 此目录下的文件可以根据自己的需要增加或减少，与此同时，你需要同步修改项目目录下的环境初始化脚本【init/0-init-envs.sh】
- 文件名末尾的【---dev】代表运行环境是【dev】，是开发环境，【---prod】代表运行环境是【prod】，是生产环境，**这两个名称在代码中有特殊意义，请严格使用**，其他环境你可以随性定义，比如【---staging】、【---test】】、【---uuu】



## 文件用途

```bash
zzxia-om-super-invincible-lollipop/init/envs.sample$ tree
.
├── 3rd_jar                                      #--- 可选，从官方无法正确拉取的包，手动下载，push到自己的maven仓库
│   ├── jars
│   │   ├── commons-imaging-1.0-SNAPSHOT.jar
│   │   └── dcharts-widget-0.10.0.jar
│   ├── push-to-maven-repo.sh
│   └── README.md
├── ansible-hosts---dev                          #--- 必选，ansible主机定义文件
├── backup-center-project.list                   #--- 可选，备份项目目录清单
├── bash_aliases---dev                           #--- 可选，命令别名
├── container-hosts-pub.list---dev               #--- 可选，定义docker容器中的/etc/hosts
├── env.sh---dev                             #--- 必选，最关键的环境变量文件
├── dingding_conver_to_markdown_list.py          #--- 可选，将消息转换成markdown list格式发出来，你需要设置自己的token
├── dingding_send_markdown-login.py              #--- 可选，发送markdown格式消息，用户登录报警用，你需要设置自己的token
├── dingding_send_markdown.py                    #--- 可选，发送markdown格式消息，你需要设置自己的token
├── docker-arg-pub.list---dev                    #--- 可选，一般使用swarm集群是必要的
├── docker-cluster-service.list---dev            #--- 必选，关键参数，这是部署发布用服务清单
├── elasticsearch-srv-env---dev                  #--- 可选，一般用不上
├── fluent.conf---dev                            #--- 可选，一般用不上
├── host-ip.list---dev                           #--- 可选，一般用不上
├── install-hosts.yml---dev                      #--- 必选，maven仓库、docker仓库等需要用到hosts定义，用于构建部署，其他根据需要增减
├── java-options-pub.list---dev                  #--- 可选，所有java app容器启动时需要用到的参数，比如APM相关插件：pinpoint|skywalking需要附加的java运行参数
├── kibana-srv-env---dev                         #--- 可选，一般用不上
├── mailrc---dev                                 #--- 可选，发邮件用，没有会出错
├── nginx.list---dev                             #--- 必选，如果你要发布nginx项目
├── ossfs-backup.service                         #--- 可选，ossfs挂载
├── ossfs-internal-backup.service                #--- 可选，ossfs挂载
├── pg_db.list                                   #--- 可选，pg数据库备份清单
├── project.list                                 #--- 必选，构建项目清单
├── README.md                                    #--- 文件说明
├── zzxia-op-super-invincible-lollipop.run-env.sh---dev                             #--- 必选，万物之根本
└── soft                                         #--- 可选，用于环境安装，maven、java、node，你可以手动安装
    ├── apache-maven-3.5.0-bin.tar.gz
    ├── jdk-8u144-linux-x64.tar.gz
    ├── node-v14.17.5-linux-x64.tar.xz
    └── README.md

3 directories, 32 files
```


