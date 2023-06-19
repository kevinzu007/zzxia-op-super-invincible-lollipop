# docker registry清理工具

> https://github.com/burnettk/delete-docker-registry-image.git


## 主程序./clean_old_versions.py运行参数
这里仅列表，具体用法请看py文件
```text
"-e", "--exclude"
"-E", "--include"
"-i", "--image"
"-v", "--verbose"
"-u", "--registry-url"
"-s", "--script-path"
"-l", "--last"
"-b", "--before-date"
"-a", "--after-date"
"-o", "--order"
"-U", "--user"
"-P", "--password"
"--no_check_certificate"
"--dry-run"
```


## run
```
# 设置docker registry数据目录变量
export REGISTRY_DATA_DIR="/srv/docker_compose_services/docker_registry/data/docker/registry/v2"

# 执行删除blob
#（http）
./clean_old_versions.py  \
  --script-path ./delete_docker_registry_image.py  \
  --image gclife-  \
  --registry-url http://127.0.0.1:5000  \
  --last 15  \
  --user ufipf \
  --password 123456 ;
#（https）
./clean_old_versions.py  \
  --script-path ./delete_docker_registry_image.py  \
  --image gclife-  \
  --registry-url https://127.0.0.1:5000  \
  --last 15  \
  --user ufipf \
  --password 123456  \
  --no_check_certificate ;

# 清理index吧
# dockerregistry_docker_registry_1 ：改为自己的容器名
docker exec -ti dockerregistry_docker_registry_1   registry garbage-collect /etc/docker/registry/config.yml
```


## 计划任务
```
crontab -l
0 0 * * *  export REGISTRY_DATA_DIR="/srv/docker/docker_registry/data/docker/registry/v2" ; cd /root/delete-docker-registry-image ; ./clean_old_versions.py -s ./delete_docker_registry_image.py  -i gcl  -u https://127.0.0.1:5000 -l 30  -U ufipf -P 123456  --no_check_certificate ; docker exec -ti dockerregistry_docker_registry_1   registry garbage-collect /etc/docker/registry/config.yml
```


## 运行错误解决
**错误**：urllib3 (1.22) or chardet (2.2.1) doesnot match a supported version! RequestsDependencyWarning)
**原因**：python库中urllib3 (1.22) or chardet (2.2.1) 的版本不兼容
```
pip uninstall urllib3
pip uninstall chardet
pip install requests
```


