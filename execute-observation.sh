#!/bin/bash

# Run an JPetStore and collect all events.
# Requires
# - JPETSTORE runner script which also runs a workload driver
# - collector

# Parameter
# - $1 = workload path, optional

# execute setup

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

if [ -f $BASE_DIR/config ] ; then
	. $BASE_DIR/config
else
	echo "Missing configuration"
	exit 1
fi

. $BASE_DIR/common-functions.sh

###################################
# check setup

checkDirectory "Data" $DATA_DIR

checkExecutable Collector "${COLLECTOR}"
checkExecutable JPetStore "$JPETSTORE"
checkFile log-configuration $BASE_DIR/log4j.cfg

###################################
# check parameters

if [ "$1" == "" ] ; then
	export INTERACTIVE="yes"
	export EXPERIMENT_ID="interactive"
	information "Interactive mode no specialized workload driver"
else
	export INTERACTIVE="no"
	checkFile workload "$1"
	WORKLOAD_CONFIGURATION="$1"
	export EXPERIMENT_ID=`basename "$WORKLOAD_CONFIGURATION" | sed 's/\.yaml$//g'`
	information "Automatic mode, workload driver is ${WORKLOAD_PATH}"
fi

export COLLECTOR_DATA_DIR="${DATA_DIR}/${EXPERIMENT_ID}"

###################################
# main script

information "--------------------------------------------------------------------"
information "$EXPERIMENT_ID $WORKLOAD_CONFIGURATION"
information "--------------------------------------------------------------------"

###################################
# stoping services

information "Cleanup"

# stop collector
information "Stopping collector ..."

COLLECTOR_PID=`ps auxw | grep "/collector" | grep -v grep | awk '{ print $2 }' | head -1`

while  [ "${COLLECTOR_PID}" != "" ] ; do
	COLLECTOR_PID=`ps auxw | grep "/collector" | grep -v grep | awk '{ print $2 }' | head -1`
	echo "stopping ${COLLECTOR_PID}"
	kill -TERM $COLLECTOR_PID
done

information "done"
echo ""

# remove old data
information "Cleaning data"
rm -rf $COLLECTOR_DATA_DIR/*

mkdir -p $COLLECTOR_DATA_DIR

###################################
# start experiment

information "Deploying experiment..."

##
# collector

information "Start collector"

# configure collector
cat << EOF > collector.config
# common
kieker.monitoring.name=${EXPERIMENT_ID}
kieker.monitoring.hostname=
kieker.monitoring.metadata=true

# TCP collector
kieker.tools.source=kieker.tools.source.MultipleConnectionTcpSourceCompositeStage
kieker.tools.source.MultipleConnectionTcpSourceCompositeStage.port=9876
kieker.tools.source.MultipleConnectionTcpSourceCompositeStage.capacity=8192

# dump stage
kieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter
kieker.monitoring.writer.filesystem.FileWriter.customStoragePath=$COLLECTOR_DATA_DIR/
kieker.monitoring.writer.filesystem.FileWriter.charsetName=UTF-8
kieker.monitoring.writer.filesystem.FileWriter.maxEntriesInFile=25000
kieker.monitoring.writer.filesystem.FileWriter.maxLogSize=-1
kieker.monitoring.writer.filesystem.FileWriter.maxLogFiles=-1
kieker.monitoring.writer.filesystem.FileWriter.mapFileHandler=kieker.monitoring.writer.filesystem.TextMapFileHandler
kieker.monitoring.writer.filesystem.TextMapFileHandler.flush=true
kieker.monitoring.writer.filesystem.TextMapFileHandler.compression=kieker.monitoring.writer.compression.NoneCompressionFilter
kieker.monitoring.writer.filesystem.FileWriter.logFilePoolHandler=kieker.monitoring.writer.filesystem.RotatingLogFilePoolHandler
kieker.monitoring.writer.filesystem.FileWriter.logStreamHandler=kieker.monitoring.writer.filesystem.TextLogStreamHandler
kieker.monitoring.writer.filesystem.FileWriter.flush=true
kieker.monitoring.writer.filesystem.FileWriter.bufferSize=81920
EOF

export COLLECTOR_OPTS=-Dlog4j.configuration=file:///$BASE_DIR/log4j.cfg

$COLLECTOR -c collector.config &
COLLECTOR_PID=$!

sleep 10

# run jpetstore
$JPETSTORE "${WORKLOAD_CONFIGURATION}"

# finally stop the collector
information "Stopping collector"

kill -TERM ${COLLECTOR_PID}

wait ${COLLECTOR_PID}

rm collector.config

information "Experiment complete."
# end
# end
