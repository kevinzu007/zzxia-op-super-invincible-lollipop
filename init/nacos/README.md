# 说明


nacos数据库使用docker-compose启动，数据初始化sql请从官方包中获取【https://github.com/alibaba/nacos/releases/tag/2.1.2】

nacos-server运行在集群中，需要先把镜像拉取并推送到自己的仓库【运行nacos-image-pull.sh】





=============================================================================
作者：ZZXia
参考摘抄：`https://github.com/nacos-group/nacos-docker.git`
模式：单机+mysql5.7


## nacos部署架构
- 模式：单机（运行在一台机器上没有必要搞成集群模式）
- 数据库：mysql 5.7（nacos数据库会自动初始化，无需手动导入nacos sql脚本，第一次启动初始化后可能需要重新down然后再up，否则可能发现访问nacos 8848异常）



## nacos属性配置变量列表

> 可以根据需要选择性添加一些变量

| 属性名称                                | 描述                                               | 选项                                                         |
| --------------------------------------- | -------------------------------------------------- | ------------------------------------------------------------ |
| MODE                                    | 系统启动方式: 集群/单机                            | cluster/standalone 默认 **cluster**                          |
| NACOS_SERVERS                           | 集群地址                                           | p1:port1空格ip2:port2 空格ip3:port3                          |
| PREFER_HOST_MODE                        | 支持IP还是域名模式                                 | hostname/ip 默认**IP**                                       |
| NACOS_SERVER_PORT                       | Nacos 运行端口                                     | 默认**8848**                                                 |
| NACOS_SERVER_IP                         | 多网卡模式下可以指定IP                             |                                                              |
| SPRING_DATASOURCE_PLATFORM              | 单机模式下支持MYSQL数据库                          | mysql / 空 默认:空                                           |
| MYSQL_SERVICE_HOST                      | 数据库 连接地址                                    |                                                              |
| MYSQL_SERVICE_PORT                      | 数据库端口                                         | 默认 : **3306**                                              |
| MYSQL_SERVICE_DB_NAME                   | 数据库库名                                         |                                                              |
| MYSQL_SERVICE_USER                      | 数据库用户名                                       |                                                              |
| MYSQL_SERVICE_PASSWORD                  | 数据库用户密码                                     |                                                              |
| MYSQL_SERVICE_DB_PARAM                  | 数据库连接参数                                     | 默认:**characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useSSL=false** |
| MYSQL_DATABASE_NUM                      | 数据库个数                                         | 默认:**1**                                                   |
| JVM_XMS                                 | -Xms                                               | 默认 :1g                                                     |
| JVM_XMX                                 | -Xmx                                               | 默认 :1g                                                     |
| JVM_XMN                                 | -Xmn                                               | 512m                                                         |
| JVM_MS                                  | - XX:MetaspaceSize                                 | 默认 :128m                                                   |
| JVM_MMS                                 | -XX:MaxMetaspaceSize                               | 默认 :320m                                                   |
| NACOS_DEBUG                             | 是否开启远程DEBUG                                  | y/n 默认 :n                                                  |
| TOMCAT_ACCESSLOG_ENABLED                | server.tomcat.accesslog.enabled                    | 默认 :false                                                  |
| NACOS_AUTH_SYSTEM_TYPE                  | 权限系统类型选择,目前只支持nacos类型               | 默认 :nacos                                                  |
| NACOS_AUTH_ENABLE                       | 是否开启权限系统                                   | 默认 :false                                                  |
| NACOS_AUTH_TOKEN_EXPIRE_SECONDS         | token 失效时间                                     | 默认 :18000                                                  |
| NACOS_AUTH_TOKEN                        | token                                              | 默认 :SecretKey012345678901234567890123456789012345678901234567890123456789 |
| NACOS_AUTH_CACHE_ENABLE                 | 权限缓存开关 ,开启后权限缓存的更新默认有15秒的延迟 | 默认 : false                                                 |
| MEMBER_LIST                             | 通过环境变量的方式设置集群地址                     | 例子:192.168.16.101:8847?raft_port=8807,192.168.16.101?raft_port=8808,192.168.16.101:8849?raft_port=8809 |
| EMBEDDED_STORAGE                        | 是否开启集群嵌入式存储模式                         | `embedded`  默认 : none                                      |
| NACOS_AUTH_CACHE_ENABLE                 | nacos.core.auth.caching.enabled                    | default : false                                              |
| NACOS_AUTH_USER_AGENT_AUTH_WHITE_ENABLE | nacos.core.auth.enable.userAgentAuthWhite          | default : false                                              |
| NACOS_AUTH_IDENTITY_KEY                 | nacos.core.auth.server.identity.key                | default : serverIdentity                                     |
| NACOS_AUTH_IDENTITY_VALUE               | nacos.core.auth.server.identity.value              | default : security                                           |
| NACOS_SECURITY_IGNORE_URLS              | nacos.security.ignore.urls                         | default : `/,/error,/**/*.css,/**/*.js,/**/*.html,/**/*.map,/**/*.svg,/**/*.png,/**/*.ico,/console-fe/public/**,/v1/auth/**,/v1/console/health/**,/actuator/**,/v1/console/server/**` |

> **如果以上配置还不能满足你的要求，请直接使用卷命令替换`application.properties`，例如：`-v /path/application.properties:/home/nacos/conf/application.properties`**
> **nacos版本号在当前目录下`.env`文件里指定**


## 注意

nacos 2.x 新增了两个端口（gRPC协议），这两个端口是基于http端口8848的偏移量生成，偏移量分别为1000及1001，所以如果http端口用的是8848，则新增的端口为9848、9849
还有端口9555是debug端口（如果开启debug）



