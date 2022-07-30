# docker registry清理工具

> https://github.com/burnettk/delete-docker-registry-image.git


## 修改docker registry数据目录：
方法一：设置shell环境变量
    export REGISTRY_DATA_DIR="/srv/docker/docker_registry/data/docker/registry/v2"
方法二：修改delete_docker_registry_image.py中registry_data_dir行：
    registry_data_dir = "/srv/docker/docker_registry/data/docker/registry/v2"


## 运行错误解决
**错误**：urllib3 (1.22) or chardet (2.2.1) doesnot match a supported version! RequestsDependencyWarning)
**原因**：python库中urllib3 (1.22) or chardet (2.2.1) 的版本不兼容
```
pip uninstall urllib3
pip uninstall chardet
pip install requests
```


## run
```
# 设置变量
export REGISTRY_DATA_DIR="/srv/docker/docker_registry/data/docker/registry/v2"
# -i gcl ：指定镜像匹配
# -u http://127.0.0.1:5000 ：local访问地址
# -l 30 ：保留最近30个
# -U ufipf -P 123456 ：用户密码
./clean_old_versions.py -s ./delete_docker_registry_image.py  -i gcl  -u http://127.0.0.1:5000 -l 30  -U ufipf -P 123456
# dockerregistry_docker_registry_1 ：改为自己的容器名
docker exec -ti dockerregistry_docker_registry_1   registry garbage-collect /etc/docker/registry/config.yml
```


## 计划任务
```
crontab -l
0 0 * * *  export REGISTRY_DATA_DIR="/srv/docker/docker_registry/data/docker/registry/v2" ; cd /root/delete-docker-registry-image ; ./clean_old_versions.py -s ./delete_docker_registry_image.py  -i gcl  -u http://127.0.0.1:5000 -l 30  -U ufipf -P 123456 ; docker exec -ti dockerregistry_docker_registry_1   registry garbage-collect /etc/docker/registry/config.yml
```





