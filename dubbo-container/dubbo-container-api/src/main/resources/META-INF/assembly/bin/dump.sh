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
LOGS_FILE=`sed '/dubbo.log4j.file/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`

if [ -z "$SERVER_NAME" ]; then
	SERVER_NAME=`hostname`
fi

PIDS=`ps -f | grep java | grep "$CONF_DIR" |awk '{print $2}'`
if [ -z "$PIDS" ]; then
    echo "ERROR: The $SERVER_NAME does not started!"
    exit 1
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
DUMP_DIR=$LOGS_DIR/dump
if [ ! -d $DUMP_DIR ]; then
	mkdir $DUMP_DIR
fi
DUMP_DATE=`date +%Y%m%d%H%M%S`
DATE_DIR=$DUMP_DIR/$DUMP_DATE
if [ ! -d $DATE_DIR ]; then
	mkdir $DATE_DIR
fi

echo -e "Dumping the $SERVER_NAME ...\c"
for PID in $PIDS ; do
	$JAVA_BIN/jstack $PID > $DATE_DIR/jstack-$PID.dump 2>&1
	echo -e ".\c"
	$JAVA_BIN/jinfo $PID > $DATE_DIR/jinfo-$PID.dump 2>&1
	echo -e ".\c"
	$JAVA_BIN/jstat -gcutil $PID > $DATE_DIR/jstat-gcutil-$PID.dump 2>&1
	echo -e ".\c"
	$JAVA_BIN/jstat -gccapacity $PID > $DATE_DIR/jstat-gccapacity-$PID.dump 2>&1
	echo -e ".\c"
	$JAVA_BIN/jmap $PID > $DATE_DIR/jmap-$PID.dump 2>&1
	echo -e ".\c"
	$JAVA_BIN/jmap -heap $PID > $DATE_DIR/jmap-heap-$PID.dump 2>&1
	echo -e ".\c"
	$JAVA_BIN/map -histo $PID > $DATE_DIR/jmap-histo-$PID.dump 2>&1
	echo -e ".\c"
	if [ -r /usr/sbin/lsof ]; then
	/usr/sbin/lsof -p $PID > $DATE_DIR/lsof-$PID.dump
	echo -e ".\c"
	fi
done

if [ -r /bin/netstat ]; then
/bin/netstat -an > $DATE_DIR/netstat.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/iostat ]; then
/usr/bin/iostat > $DATE_DIR/iostat.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/mpstat ]; then
/usr/bin/mpstat > $DATE_DIR/mpstat.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/vmstat ]; then
/usr/bin/vmstat > $DATE_DIR/vmstat.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/free ]; then
/usr/bin/free -t > $DATE_DIR/free.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/sar ]; then
/usr/bin/sar > $DATE_DIR/sar.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/uptime ]; then
/usr/bin/uptime > $DATE_DIR/uptime.dump 2>&1
echo -e ".\c"
fi

echo "OK!"
echo "DUMP: $DATE_DIR"
