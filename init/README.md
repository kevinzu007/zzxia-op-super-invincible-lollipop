# 运维环境初始化

当前目录用于环境初始化
运行环境对于不同的公司有不同的要求，这里只是参考，所以这里很多【install-*.yml】文件不是必须的，根据自己的需要添加修改删除，很可能你会使用其他方式初始化运行环境，当仍然建议你把他自动化起来。如果你能写的够通用，请fork她，并合并到此仓库

相对基本安装如下：
```text
0-init-envs.sh*       #--- 基于0-init-envs.sh.sample创建自己专有的
1-sshkey-copy.sh
install-build-envs.sh
install-base.yml
install-config-base.yml
install-docker.yml
install-config-docker.yml
install-docker_registry.yml
install-config-docker_registry.yml
install-nexus.yml
install-config-nginx.yml
```


