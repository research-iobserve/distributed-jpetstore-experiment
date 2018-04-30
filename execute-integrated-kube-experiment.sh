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

# check for directories
if [ ! -d $DATA_DIR ] ; then
	echo "Data directory $DATA_DIR does not exist"
	exit 1
fi
if [ ! -d $DB_DIR ] ; then
	echo "Database directory $DB_DIR does not exist"
	exit 1
fi
if [ ! -d $RESULT_DIR ] ; then
	echo "Result directory $RESULT_DIR does not exist"
	exit 1
fi
if [ ! -d $FIXED_DIR ] ; then
	echo "Fixed data directory $FIXED_DIR does not exist"
	exit 1
fi
if [ ! -d $PCM_DIR ] ; then
	echo "PCM directory $PCM_DIR does not exist"
	exit 1
fi
if [ ! -d $KUBERNETES_DIR ] ; then
	echo "Kubernetes directory $KUBERNETES_DIR does not exist"
	exit 1
fi

#############################################
# check if no leftovers are running

# check all kubernetes services of the experiment are terminated
for I in `frontend account catalog order` ; do
	kubectl delete deployments/$I
done

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
kieker.monitoring.writer.filesystem.FileWriter.customStoragePath=$DATA_DIR
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

for I in account-deployment.yaml catalog-deployment.yaml frontend-deployment.yaml order-deployment.yaml ; do
	kubectl create -f $KUBERNETES_DIR/$I
done

FRONTEND=`kubectl describe pods/frontend | grep "IP:" | awk '{ print $2 }'`

SERVICE_URL="http://$FRONTEND:8080/jpetstore-frontend"

echo "Servie URL $SERVICE_URL"

while ! curl -sSf $SERVICE_URL ; do
	sleep 1
done

echo ">>>>>>>>>>> start workload"

export SELENIUM_EXPERIMENT_WORKLOADS_OPTS=-Dlog4j.configuration=file:///$BASE_DIR/log4j.cfg
$WORKLOAD_RUNNER -c $WORKLOAD_CONFIGURATION -u "$SERVICE_URL" &
WORKLOAD_RUNNER_PID=$!

sleep 30

echo "Migrating service"

#docker run -e LOGGER=$LOGGER -d --name account-usa jpetstore-usa-account-service
#docker rename account account-germany
#docker rename account-usa account
#docker stop account-germany

wait $WORKLOAD_RUNNER_PID

echo "<<<<<<<<<<< term workload"

# shutdown phantomjs
killall -9 phantomjs

# shutdown jpetstore
echo "<<<<<<<<<<< term jpetstore"

for I in `frontend account catalog order` ; do
	kubectl delete deployments/$I
done

# shutdown analysis/collector
echo "<<<<<<<<<<< term analysis"

kill -TERM ${COLLECTOR_PID}
rm collector.config

echo "Done."
# end
