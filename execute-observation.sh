#!/bin/bash

BASE=$(cd "$(dirname "$0")"; pwd)/
DATA_DIR="$BASE/data"
ANALYSIS_DIR="$DATA/analysis"

COLLECTOR="$BASE/../collector-0.0.2-SNAPSHOT/bin/collector"
KIEKER="$BASE/../kieker-1.12/bin"

if [ ! -d "$DATA_DIR" ] ; then
	mkdir "$DATA_DIR"
fi
if [ ! -d "$ANALYSIS_DIR" ] ; then
	mkdir "$ANALYSIS_DIR"
fi

rm -rf $DATA_DIR/kieker-*
rm -rf $ANALYSIS_DIR/*

$COLLECTOR -d "$DATA_DIR" -p 9876 &



"$KIEKER/trace-analysis.sh" -i "$DATA_DIR"/kieker-* --plot-Deployment-Component-Dependency-Graph --plot-Container-Dependency-Graph --plot-Assembly-Component-Dependency-Graph --plot-Aggregated-Deployment-Call-Tree -o analysis

"$KIEKER/dotPic-fileConverter.sh" "$ANALYSIS_DIR" svg pdf

# end

