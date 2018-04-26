#!/bin/bash

# execute setup

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

if [ -f $BASE_DIR/config ] ; then
	. $BASE_DIR/config
else
	echo "Missing configuration"
	exit 1
fi

WORKLOAD_CONFIGURATION="$1"

# check setup
if [ ! -x "$COLLECTOR" ] ; then
	echo "Collector not found at: $COLLECTOR"
	exit 1
fi

# check workload runner
if [ ! -x "$WORKLOAD_RUNNER" ] ; then
	echo "Workloadrunner not found at: $WORKLOAD_RUNNER"
	exit 1
fi

# check workload model
if [ ! -f "$WORKLOAD_CONFIGURATION" ] ; then
	echo "Workload configuration not found at: $WORKLOAD_CONFIGURATION"
	exit 1
fi

#############################################
# check if no leftovers are running

# check all kubernetes services of the experiment are terminated


# killall phantomjs from selenium
killall -9 phantomjs

#####################################################################
# starting

# configure collector
cat << EOF > collector.config
# common
kieker.monitoring.name=$TYPE
kieker.monitoring.hostname=
kieker.monitoring.metadata=true

# TCP collector
iobserve.service.reader=org.iobserve.service.source.MultipleConnectionTcpCompositeStage
org.iobserve.service.source.MultipleConnectionTcpCompositeStage.port=9876
org.iobserve.service.source.MultipleConnectionTcpCompositeStage.capacity=8192

# dump stage
kieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter
kieker.monitoring.writer.filesystem.FileWriter.customStoragePath=$BASE_DIR/data
kieker.monitoring.writer.filesystem.FileWriter.charsetName=UTF-8
kieker.monitoring.writer.filesystem.FileWriter.maxEntriesInFile=25000
kieker.monitoring.writer.filesystem.FileWriter.maxLogSize=-1
kieker.monitoring.writer.filesystem.FileWriter.maxLogFiles=-1
kieker.monitoring.writer.filesystem.FileWriter.mapFileHandler=kieker.monitoring.writer.filesystem.TextMapFileHandler
kieker.monitoring.writer.filesystem.TextMapFileHandler.flush=true
kieker.monitoring.writer.filesystem.TextMapFileHandler.compression=kieker.monitoring.writer.filesystem.compression.NoneCompressionFilter
kieker.monitoring.writer.filesystem.FileWriter.logFilePoolHandler=kieker.monitoring.writer.filesystem.RotatingLogFilePoolHandler
kieker.monitoring.writer.filesystem.FileWriter.logStreamHandler=kieker.monitoring.writer.filesystem.TextLogStreamHandler
kieker.monitoring.writer.filesystem.FileWriter.flush=true
kieker.monitoring.writer.filesystem.FileWriter.bufferSize=8192
EOF

echo ">>>>>>>>>>> start analysis/collector"

export COLLECTOR_OPTS=-Dlog4j.configuration=file:///$BASE_DIR/log4j.cfg
$COLLECTOR -c collector.config &
COLLECTOR_PID=$!

sleep 10

# jpetstore

echo ">>>>>>>>>>> start jpetstore"

docker run -d --name jpetstore jpetstore

ID=`docker ps | grep 'jpetstore' | awk '{ print $1 }'`
FRONTEND=`docker inspect $ID | grep '"IPAddress' | awk '{ print $2 }' | tail -1 | sed 's/^"\(.*\)",/\1/g'`

SERVICE_URL="http://$FRONTEND:8080/jpetstore"

while ! curl -sSf $SERVICE_URL ; do
	sleep 1
done

echo ">>>>>>>>>>> start workload"

export SELENIUM_EXPERIMENT_WORKLOADS_OPTS=-Dlog4j.configuration=file:///$BASE_DIR/log4j.cfg
$WORKLOAD_RUNNER -c $WORKLOAD_CONFIGURATION -u "$SERVICE_URL" &
WORKLOAD_RUNNER_PID=$!

sleep 30

echo "Migrating service"

docker rename account account-germany
docker run -d --name account jpetstore-account-service

wait $WORKLOAD_RUNNER_PID

echo "<<<<<<<<<<< term workload"

# shutdown phantomjs
killall -9 phantomjs

# shutdown jpetstore
echo "<<<<<<<<<<< term jpetstore"

docker stop jpetstore

docker rm jpetstore

# shutdown analysis/collector
echo "<<<<<<<<<<< term analysis"

kill -TERM ${COLLECTOR_PID}
rm collector.config

echo "Done."
# end

