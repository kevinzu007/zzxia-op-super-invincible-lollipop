# my_sec密码相关变量

**这里的内容全部是机密信息，请放到安全保密的地方（不要放当前仓库）**


## 文件类型

- 以.sec结尾的文件      ：会被引入到所有项目程序中
- 以.sec.env结尾的文件  ：会被引入到指定项目程序中
- 其他文件              ：第三方程序专有配置文件


## 说明

- dev、stag、prod： 分别对应不同运行环境，可以自定义
- 请根据自己的需要添加删除相关文件，文件名称随意，文件扩展名请根据【## 1 文件类型】定义。添加文件后，根据部署环境与目标服务器修改【install-config-my_sec_envs.yml】


## 安装方法

ansible-playbook  install-config-my_sec_envs.yml  -e "RUN_ENV=${RUN_ENV}"       #--- ${RUN_ENV}变量在初始化环境时已经放到【/etc/profile.d/】下了，可以不明确指出
ansible-playbook  install-config-my_sec_envs.yml


