#!/usr/bin/env bash

export SPARK_LOCAL_IP=`awk 'NR==1 {print $1}' /etc/hosts`
export ZEPPELIN_SPARK_USEHIVECONTEXT=false
export SPARK_SUBMIT_OPTIONS="--conf spark.sql.warehouse.dir=/tmp"
export MASTER="spark://${SPARK_LOCAL_IP}:7077"
export SPARK_HOME=/opt/spark
/opt/zeppelin/bin/zeppelin-daemon.sh start
