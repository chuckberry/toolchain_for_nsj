#!/bin/bash

source test_init.env
source functions

# Check UID
if [ `id -u` -ne 0 ]; then
	echo -e "FAILED: root permissions required\n\n"
	exit 1;
fi

# Check ENV initialization
if [ x$TA_CONFIGURED == "x" ]; then
	echo "Run init_env.sh before running this script"
	exit 1;
fi

#
# 	don't touch here

print_usage() {

cat - <<EOF

fast run 

EOF

}

# Testing scripts for performance testing
# enter in fast_test folder
pushd $TA_FAST_TEST_PATH >/dev/null
if [ ! -d $TEST_FOLDER ]; then 
	mkdir $TEST_FOLDER
fi

pushd $TEST_FOLDER >/dev/null
if [ ! -d $GRAPH_FOLDER ]; then
 	mkdir $GRAPH_FOLDER
fi

if [ ! -d $DATA_FOLDER ]; then
	mkdir $DATA_FOLDER
fi

if [ ! -d $PNG_FOLDER ]; then
	mkdir $PNG_FOLDER
fi

# here I will put func_case_test

if [ $FAST_FUNC_TEST == 1 ]; then
	echo ""
	echo "Function call test running ..."
	mount_debugfs
	for i in `seq $FAST_TRY`; do
		stat_func.sh -b "$FAST_BENCH" -i "$i" -d "$FAST_DIM"
		TA_PERFORMANCE_FILE=`find $DATA_FOLDER -type f -name "*_${PER_FUNC_TAG}_*_stats.txt" 2>/dev/null`
		for p in $TA_PERFORMANCE_FILE; do
			local_graphics.sh -f "$p" -d "$FAST_DIM"
		done
	done
fi

#if [ $FAST_CASE_FUNC_TEST == 1 ]; then
#	echo ""
#	echo "Case function test running ..."
#	for i in `seq $FAST_TRY`; do
#		case_stat_func.sh -b "$FAST_BENCH" -i "$i" -d "$FAST_DIM"
#		TA_CASE_FUNC_FILE=`find $DATA_FOLDER -type f -name "*_${PER_FUNC_TAG}_*_stats.txt" 2>/dev/null`
#		for p in $TA_CASE_FUNC_FILE; do
#			local_per_task_graphics.sh -f "$p" -d "$FAST_DIM" -t "$CASE_FUNC_LIST" 
#		done
#	done
#fi

# perform performance benchmark
if [ $FAST_TIME_BENCH == 1 ];then
	echo "" 
	echo "Time benchmark running ..."
	for i in `seq $FAST_TRY`; do 
		time_bench.sh -b "$FAST_BENCH" -i "1" -d "$FAST_DIM"
	done
	TA_PERFORMANCE_FILE=`find $DATA_FOLDER -type f -name "*_${PER_DIM_TAG}_*_stats.txt" 2>/dev/null`
        for p in $TA_PERFORMANCE_FILE; do
                local_graphics.sh -f "$p" -d "$FAST_DIM"
        done
fi

if [ $FAST_TRACE_BENCH == 1 ];then
	echo "" 
	echo "Trace benchmark running ..."
	mount_debugfs
	for i in `seq $FAST_TRY`; do 
		trace_bench.sh -b "$FAST_BENCH" -i "1" -d "$FAST_DIM"
	done
	TA_PERFORMANCE_FILE=`find $DATA_FOLDER -type f -name "*_${PER_TASK_TAG}_*_stats.txt" 2>/dev/null`
        for p in $TA_PERFORMANCE_FILE; do
                local_per_task_graphics.sh -f "$p" -d "$FAST_DIM" -t "$TASK_LIST"
        done
fi

if [ $FAST_L1_LOAD_BENCH == 1 ];then
	echo "" 
	echo "l1 load benchmark running ..."
	l1_load_bench.sh -b "$FAST_BENCH" -i "1" -d "$FAST_DIM"
	TA_PERFORMANCE_FILE=`find $DATA_FOLDER -type f -name "*_${PER_DIM_TAG}_*_stats.txt" 2>/dev/null`
        for p in $TA_PERFORMANCE_FILE; do
                local_graphics.sh -f "$p" -d "$FAST_DIM"
        done
fi

if [ $FAST_L1_STORE_BENCH == 1 ];then
	echo "" 
	echo "l1 store benchmark running ..."
	l1_store_bench.sh -b "$FAST_BENCH" -i "1" -d "$FAST_DIM"
	TA_PERFORMANCE_FILE=`find $DATA_FOLDER -type f -name "*_${PER_DIM_TAG}_*_stats.txt" 2>/dev/null`
        for p in $TA_PERFORMANCE_FILE; do
                local_graphics.sh -f "$p" -d "$FAST_DIM"
        done
fi


popd >/dev/null 2>&1 # I'm in TA_FAST_RESULTS_PATH
chown $USER.$GROUP -R *

popd >/dev/null 2>&1
