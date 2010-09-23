#!/bin/bash

if [ ! -f test_init.env ]; then
	echo "run init_env.sh to select which profile do you want"
	exit 1;
fi

source test_init.env
source functions

# Check UID
if [ `id -u` -ne 0 ]; then
	echo -e "FAILED: root permissions required\n\n"
	exit 1;
fi

# Check ENV initialization
if [ x$TA_CONFIGURED == "x" ]; then
	echo "Source init.env before running this script"
	exit 1;
fi

# Check structure of toolchain
if [ ! -d $TA_IMAGES_PATH ]; then
	echo "$TA_IMAGES_PATH doesn't exist"
	exit 1;
fi 

if [ ! -d $TA_IMAGES_PATH ]; then
	echo "$TA_IMAGES_PATH doesn't exist"
	exit 1;

fi

if [ ! -d $TA_BMARKS_PATH ]; then
	echo "$TA_BMARKS_PATH doesn't exist"
	exit 1;

fi 

if [ ! -d $TA_SCRIPTS_PATH ]; then
	echo "$TA_SCRIPTS_PATH doesn't exist"
	exit 1;

fi

if [ ! -d $TA_RESULTS_PATH ]; then
	echo "$TA_RESULTS_PATH doesn't exist"
	exit 1;

fi

if [ ! -d $TA_LOG_PATH ]; then
	echo "$TA_LOG_PATH doesn't exist"
	exit 1;

fi

OK_START=`cat $START_BENCH`
if [ x$OK_START != "x" ]; then
	echo "clean toolchain before to run"
	exit 1;
fi

################################################################################
#                       Don't touch the following lines                        #
################################################################################

#----- Local variables

cd $TA_BASE

LOG_DATA="$TA_LOG_PATH/`date --rfc-3339='date'`.log"

# variant of running kernel, used to find suitable 
# benchmark for running kernel
VARIANT="vanilla taskaff"

echo "Running kernel is: `uname -r`" >> $LOG_DATA

for i in $VARIANT; do

	# Collect benchmarks to use for running kernel
	# expected filename: taBench-<variant>_<bsize>
	pushd $TA_BMARKS_PATH >/dev/null
	TA_BMARKS=`find . -executable -name "nwBench-$i*" -exec basename \{\} \; 2>/dev/null`
	popd >/dev/null 2>&1

	if [ x"$TA_BMARKS" == "x" ]; then
		echo "No (runnable) benchmark to use find into [$TA_BMARKS_PATH]" >> $LOG_DATA
		exit 2;
	fi
	echo "Benchmarks to use: ["$TA_BMARKS"]" >> $LOG_DATA

	# Collect test scripts to run
	pushd $TA_SCRIPTS_PATH >/dev/null
	TA_PERFORMANCE_SCRIPTS=`find . -executable -name "*_bench.sh" -exec basename \{\} \; 2>/dev/null`
	popd >/dev/null 2>&1
	if [ x"$TA_PERFORMANCE_SCRIPTS" == "x" ]; then
		echo "No (runnable) performance test scripts to run find into [$TA_SCRIPTS_PATH]" >> $LOG_DATA
		exit 2;
	fi
	echo "Test scripts to run: ["$TA_PERFORMANCE_SCRIPTS"]" >> $LOG_DATA

	pushd $TA_SCRIPTS_PATH >/dev/null
	TA_KERN_FUNC_SCRIPTS=`find . -executable -name "*_func.sh" -exec basename \{\} \; 2>/dev/null`
	popd >/dev/null 2>&1
	if [ x"$TA_KERN_FUNC_SCRIPTS" == "x" ]; then
		echo "No (runnable) kernel function test scripts to run find into [$TA_SCRIPTS_PATH]" >> $LOG_DATA
		exit 2;
	fi
	echo "Test scripts to run: ["$TA_KERN_FUNC_SCRIPTS"]" >> $LOG_DATA

	# setup folder to contain benchmark data

	# mount debufs
	echo "Mountinfg debugfs" >> $LOG_DATA
	mount_debugfs >> $LOG_DATA

	# create folder to contain benchmark data
	TEST_FOLDER="`date --rfc-3339='date'`_$i"
	pushd $TA_RESULTS_PATH >/dev/null
	if [ ! -d $TEST_FOLDER ]; then 
		mkdir $TEST_FOLDER
		echo "TEST_FOLDER created" >> $LOG_DATA
	fi

	echo > $GLOBAL_LIST

	pushd $TEST_FOLDER >/dev/null
	if [ ! -d $GRAPH_FOLDER ]; then
		mkdir $GRAPH_FOLDER
		echo "GRAPH FOLDER created" >> $LOG_DATA
	fi

	if [ ! -d $DATA_FOLDER ]; then
		mkdir $DATA_FOLDER
		echo "DATA FOLDER created" >> $LOG_DATA
	fi

	if [ ! -d $PNG_FOLDER ]; then
		mkdir $PNG_FOLDER
		echo "PNG FOLDER created" >> $LOG_DATA
	fi

	# for NR_TRY_PERFORMANCE_TEST x nr. elem in DIM_LIST
	# perform all *_bench.sh present in TA_PERFORMANCE_SCRIPTS 

	echo "benchmarks starts ..." >> $LOG_DATA

	echo "buffer dim for perf. test: ${DIM_LIST}" >> $LOG_DATA
	echo "number of tries for perf. test: ${NR_TRY_PERFORMANCE_TEST}" >> $LOG_DATA
	echo "enable perf. test: ${TA_MAKE_PERFORMANCE_TEST}" >> $LOG_DATA
	echo "task list: ${TASK_LIST}" >> $LOG_DATA
	echo "kernel functions to trace: ${FUNC_LIST}" >> $LOG_DATA
	echo "buffer dim for kernel func. test: ${DIM_FUNC_LIST}" >> $LOG_DATA
	echo "number of tries for kernel func. test: ${NR_TRY_FUNC_TEST}" >> $LOG_DATA
	echo "enable kernel func test: ${TA_MAKE_FUNC_TEST}" >> $LOG_DATA

	if [ $TA_MAKE_PERFORMANCE_TEST == 1 ]; then
		for i in `seq $NR_TRY_PERFORMANCE_TEST`; do
			for bench in $TA_PERFORMANCE_SCRIPTS; do
				for d in $DIM_LIST; do
					LOG_RUN="run_$bench_`uname -r`_${i}_${d}.log" 
					echo "" >> $LOG_RUN 
					echo "---> Performance test: Start $bench with $d KB buffer dimension (Try $i)" >> $LOG_RUN
					BENCH=`echo "$TA_BMARKS" | grep $d`
					prepare_for_benchmark >> $LOG_RUN
					$bench -b "$BENCH" -i "$i" -d "$d" >> $LOG_RUN 2>&1
					restore_from_benchmark >> $LOG_RUN
					echo "---> Performance test: Finish $bench with $d KB buffer dimension (Try $i)" >> $LOG_RUN
				done	
			done
		done

		# find all stats file related to a benchmark that use 
		# buffer dimensions for x-axis label
		
		PER_DIM_FILE=`find $DATA_FOLDER -type f -name "*_${PER_DIM_TAG}_*_stats.txt" 2>/dev/null`
		for p in $PER_DIM_FILE; do
			local_graphics.sh -f "$p" -d "$DIM_LIST" 
		done
		
		# find all stats file related to a benchmark that use 
		# task name for x-axis label
		
		PER_TASK_FILE=`find $DATA_FOLDER -type f -name "*_${PER_TASK_TAG}_*_stats.txt" 2>/dev/null`
		for m in $PER_TASK_FILE; do	
			local_per_task_graphics.sh -f "$m" -d "$DIM_LIST" -t "$TASK_LIST"
		done
	fi

	# for NR_TRY_FUNC_TEST x nr. elem in DIM_FUNC_LIST
	# perform all *_bench.sh present in TA_KERN_FUNC_SCRIPTS 

	if [ $TA_MAKE_FUNC_TEST == 1 ]; then
		for i in `seq $NR_TRY_FUNC_TEST`; do
			for bench in $TA_KERN_FUNC_SCRIPTS; do	
				for d in $DIM_FUNC_LIST; do
				    LOG_RUN="func_test_$bench_`uname -r`_${i}_${d}.log"
				    echo "" >> $LOG_RUN
				    echo "---> Function call test: Start stat_func with $d KB buffer dimension (Try $i)" >> $LOG_RUN
				    BENCH=`echo "$TA_BMARKS" | grep $d`
				    $bench -b "$BENCH" -i "$i" -d "$d" >> $LOG_RUN 2>&1
				    echo "---> Function call test: Finish stat_func with $d KB buffer dimension (Try $i)" >> $LOG_RUN
				done
			done
		done

		# find all stats file related to a benchmark that use 
		# buffer dimensions for x-axis label, and is related to 
		# benchmark that measure statistics of kernel functions

		FUNC_COUNT_FILE=`find $DATA_FOLDER -type f -name "*_${PER_FUNC_TAG}_*_stats.txt" 2>/dev/null`
		for c in $FUNC_COUNT_FILE; do
			local_graphics.sh -f "$c" -d "$DIM_FUNC_LIST" 
		done
	fi

	popd >/dev/null 2>&1 #I'm in TA_RESULTS_PATH

	popd >/dev/null 2>&1 #I'm in TA_BASE

	echo "benchmarks finished ..." >> $LOG_DATA
done

# find position of running kernel in IMAGES_LIST
# in order to execute next kernel

# generate graphics
pushd $TA_RESULTS_PATH >/dev/null

PER_DIM_LIST=`cat $GLOBAL_LIST | grep $PER_DIM_TAG`
if [ x"$PER_DIM_LIST" != "x" ]; then
	for i in $PER_DIM_LIST; do
		global_graphics.sh -e "$i" -d "$DIM_LIST"
	done
fi

for d in $DIM_LIST; do 
	PER_TASK_LIST=`cat $GLOBAL_LIST | grep $PER_TASK_TAG | grep $d`
	if [ x"$PER_TASK_LIST" != "x" ]; then
		for i in $PER_TASK_LIST; do
			global_per_task_graphics.sh -e "$i" -d "$d" -t "$TASK_LIST"
		done
	fi
done

PER_FUNC_LIST=`cat $GLOBAL_LIST | grep $PER_FUNC_TAG`
if [ x"$PER_FUNC_LIST" != "x" ]; then
	for i in $PER_FUNC_LIST; do
		global_graphics.sh -e "$i" -d "$DIM_FUNC_LIST" 
	done
fi

# signal that results directory it's not clean
echo 0 > $CLEAN_RESULTS
popd >/dev/null 2>&1 #I'm in $TA_BASE

echo "global graphics generated" >> $LOG_DATA

# change owner of performance test result and log
chown -R $USER.$GROUP $TA_RESULTS_PATH
chown -R $USER.$GROUP $TA_LOG_PATH
rm test_init.env

echo "************** test finished ****************" >> $LOG_DATA
