#!/bin/bash

TIME=`date +%Y-%m-%dT%H:%M%S`
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}


# push到nexus

DST_REPO_URL="http://mvn-repo:8081/repository/my-mvn-releases/"
DST_REPO_ID="nexus"
JAR_DIR="./jars"

mvn deploy:deploy-file -DgroupId=org.apache.commons -DartifactId=commons-imaging -Dversion=1.0-SNAPSHOT -Dpackaging=jar -Dfile=${JAR_DIR}/commons-imaging-1.0-SNAPSHOT.jar -Durl=${DST_REPO_URL}  -DrepositoryId=${DST_REPO_ID}
mvn deploy:deploy-file -DgroupId=org.vaadin.addons -DartifactId=dcharts-widget -Dversion=0.10.0 -Dpackaging=jar -Dfile=${JAR_DIR}/dcharts-widget-0.10.0.jar -Durl=${DST_REPO_URL} -DrepositoryId=${DST_REPO_ID}



# 请根据需要，自己下载jar包到jars目录下，然后在这里添加push命令





