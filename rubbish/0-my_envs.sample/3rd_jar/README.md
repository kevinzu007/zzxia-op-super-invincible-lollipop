# 第三方jar包上传

一些直接从网上下载不到的包手动下载到到本地，然后上传到自己的maven仓库中
根据需要修改上传脚本【push-to-maven-repo.sh】
这不是必须的


## 例如：发布到nexus
```
mvn deploy:deploy-file -DgroupId=org.seuksa.itextkhmer -DartifactId=iTextKhmer -Dversion=1.0-SNAPSHOT -Dpackaging=jar -Dfile=iTextKhmer-1.0-SNAPSHOT.jar -Durl=http://mvn-repo:8081/repository/my-mvn-snapshots/ -DrepositoryId=nexus

```

## 例如：安装到本地
```
mvn install:install-file -Dfile=iTextKhmer-1.0-SNAPSHOT.jar -DgroupId=org.seuksa.itextkhmer -DartifactId=iTextKhmer -Dversion=1.0-SNAPSHOT -Dpackaging=jar
```



