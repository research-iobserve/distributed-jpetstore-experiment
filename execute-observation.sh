#!/bin/bash

BASE=$(cd "$(dirname "$0")"; pwd)/

rm -rf $BASE/data/kieker-*
rm -rf $BASE/analysis/*

$BASE/collector-0.0.2-SNAPSHOT/bin/collector -d $BASE/data -p 9876

$BASE/kieker-1.12/bin/trace-analysis.sh -i $BASE/data/kieker-* --plot-Deployment-Component-Dependency-Graph --plot-Container-Dependency-Graph --plot-Assembly-Component-Dependency-Graph --plot-Aggregated-Deployment-Call-Tree -o analysis

$BASE/kieker-1.12/bin/dotPic-fileConverter.sh $BASE/analysis svg pdf

# end

