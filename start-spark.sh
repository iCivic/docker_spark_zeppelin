#!/usr/bin/env bash
cd /opt/spark/
export SPARK_MASTER_IP=`awk 'NR==1 {print $1}' /etc/hosts`
export SPARK_LOCAL_IP=`awk 'NR==1 {print $1}' /etc/hosts`
sbin/start-master.sh --host $SPARK_LOCAL_IP --webui-port 8084
bin/spark-class org.apache.spark.deploy.worker.Worker 	spark://${SPARK_LOCAL_IP}:7077 	-i $SPARK_LOCAL_IP 


