#!/bin/bash

# download
# tar zxf
#ln -s  jdk1.8.0_144  java

export JAVA_HOME="/opt/java"
export PATH="$JAVA_HOME/bin:$PATH"
export CLASSPATH=".:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar:${JAVA_HOME}/lib"


