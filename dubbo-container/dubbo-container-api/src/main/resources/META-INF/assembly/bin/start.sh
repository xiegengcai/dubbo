#!/bin/bash

if [ ! -n "$JAVA_HOME" ]; then
    export JAVA_HOME="/usr/local/jdk1.8.0_101"
fi
JAVA_BIN="$JAVA_HOME/bin"

cd `dirname $0`
BIN_DIR=`pwd`
cd ..
DEPLOY_DIR=`pwd`
CONF_DIR=$DEPLOY_DIR/conf

SERVER_NAME=`sed '/dubbo.application.name/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`
SERVER_PROTOCOL=`sed '/dubbo.protocol.name/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`
SERVER_PORT=`sed '/dubbo.protocol.port/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`
LOGS_FILE=`sed '/dubbo.log4j.file/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`
JAVA_MEM_XMS=`sed '/java.mem.xms/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`
JAVA_MEM_XMX=`sed '/java.mem.xmx/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`
JAVA_MEM_MAX_METASPACE_SIZE=`sed '/java.mem.max.metaspace/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`

if [ -z "$JAVA_MEM_XMS" ]; then
   JAVA_MEM_XMS = `512m`
fi

if [ -z "$JAVA_MEM_XMX" ]; then
   JAVA_MEM_XMX = `1g`
fi

if [ -z "$JAVA_MEM_MAX_METASPACE_SIZE" ]; then
   JAVA_MEM_MAX_METASPACE_SIZE = `128m`
fi

if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME=`hostname`
fi

#PIDS=`ps -f | grep java | grep "$CONF_DIR" |awk '{print $2}'`
PIDS=`$JAVA_BIN/jps -v|grep "serverName=$SERVER_NAME"|awk '{print $1}'`
if [ -n "$PIDS" ]; then
    echo "ERROR: The $SERVER_NAME already started!"
    echo "PID: $PIDS"
    exit 1
fi

if [ -n "$SERVER_PORT" ]; then
    SERVER_PORT_COUNT=`netstat -tln | grep $SERVER_PORT | wc -l`
    if [ $SERVER_PORT_COUNT -gt 0 ]; then
        echo "ERROR: The $SERVER_NAME port $SERVER_PORT already used!"
        exit 1
    fi
fi

LOGS_DIR=""
if [ -n "$LOGS_FILE" ]; then
    LOGS_DIR=`dirname $LOGS_FILE`
else
    LOGS_DIR=$DEPLOY_DIR/logs
fi
if [ ! -d $LOGS_DIR ]; then
    mkdir $LOGS_DIR
fi
STDOUT_FILE=$LOGS_DIR/stdout.log

LIB_DIR=$DEPLOY_DIR/lib
LIB_JARS=`ls $LIB_DIR|grep .jar|awk '{print "'$LIB_DIR'/"$0}'|tr "\n" ":"`

JAVA_OPTS=" -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -DserverName=$SERVER_NAME"
JAVA_DEBUG_OPTS=""
if [ "$1" = "debug" ]; then
    JAVA_DEBUG_OPTS=" -Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n "
fi
JAVA_JMX_OPTS=""
if [ "$1" = "jmx" ]; then
    JAVA_JMX_OPTS=" -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false "
fi
JAVA_MEM_OPTS=" -server -Xmx$JAVA_MEM_XMX -Xms$JAVA_MEM_XMS -Xmn256m -XX:MaxMetaspaceSize=$JAVA_MEM_MAX_METASPACE_SIZE -Xss256k -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 "

echo -e "Starting the $SERVER_NAME ...\c"
nohup $JAVA_BIN/java $JAVA_OPTS $JAVA_MEM_OPTS $JAVA_DEBUG_OPTS $JAVA_JMX_OPTS -classpath $CONF_DIR:$LIB_JARS com.alibaba.dubbo.container.Main > $STDOUT_FILE 2>&1 &

COUNT=0
while [ $COUNT -lt 1 ]; do
    echo -e ".\c"
    sleep 1
    COUNT=`$JAVA_BIN/jps -v|grep "serverName=$SERVER_NAME"|awk '{print $1}'|wc -l`
    if [ $COUNT -gt 0 ]; then
        break
    fi
done

echo "OK!"
PIDS=`$JAVA_BIN/jps -v|grep "serverName=$SERVER_NAME"|awk '{print $1}'`
echo "PID: $PIDS"
echo "STDOUT: $STDOUT_FILE"