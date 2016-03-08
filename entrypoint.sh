#!/usr/bin/env bash

if [ "$(ls -A /home/udl_spark)" ]; then
	echo "Volume directory contains already files : do nothing ! "
else
	echo "Volume directory is empty : load defaults files "
	cp -R /opt/zeppelin/notebook /home/udl_spark/
	cp /dataset.json /home/udl_spark/dataset.json
	cp /StreamingApp.py /home/udl_spark/StreamingApp.py
	cp /StreamingAppWithWindows.py /home/udl_spark/StreamingAppWithWindows.py
fi

/opt/start-zeppelin.sh
/opt/start-spark.sh

