#!/bin/bash

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

if [ -f $BASE_DIR/config ] ; then
	. $BASE_DIR/config
else
	echo "Missing configuration"
	exit 1
fi

LAST=`ls -t $DATA_DIR | head -1`

if [ "$LAST" != "" ] ; then
	LAST_DATA_DIR=$DATA_DIR/$LAST

	cat $LAST_DATA_DIR/kieker.map

	DEPLOY=`cat $LAST_DATA_DIR/kieker.map | grep 'ServletDeployedEvent' | cut -d= -f1 | cut -c2-`
	UNDEPLOY=`cat $LAST_DATA_DIR/kieker.map | grep 'ServletUndeployedEvent' | cut -d= -f1 | cut -c2-`

	LAST_LOG_FILE=`ls -t $LAST_DATA_DIR/kieker-* | head -1`

	echo "Last log"
	tail -10 $LAST_LOG_FILE

	echo ""
	echo "Deploy"
	for I in $DEPLOY ; do
		cat $LAST_LOG_FILE | grep "^\$$I;"
	done
	echo ""
	echo "Undeploy"
	for I in $UNDEPLOY ; do
		cat $LAST_LOG_FILE | grep "^\$$I;"
	done
else
	echo "No log dir"
fi

# end

