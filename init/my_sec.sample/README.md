# my_sec密码相关变量

这里的内容全部是机密信息，请放到安全保密的地方（不要放当前仓库）


## 安装方法
ansible-playbook  install-config-my_sec.yml  -e "RUN_ENV=${RUN_ENV}"       #--- ${RUN_ENV}变量在初始化环境时已经放到【/etc/profile.d/】下了，可以不明确指出

## 说明
- dev、stag、prod： 分别对应不同运行环境，可以自定义
- 请根据自己的需要添加删除相关文件，文件名称随意，但扩展名必须是【.sec】。添加文件后，根据部署环境与目标服务器修改【install-config-my_sec.yml】


