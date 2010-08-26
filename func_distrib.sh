#!/bin/bash

if [ ! -f test_init.env ]; then
	source init.env
else
	source test_init.env
fi
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

if [ x"$CPUAFF_TEST" != "x" ]; then
	echo "This script perform benchmark without cpuaffinity, please disable CPUAFF_TEST"
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

pushd $TA_IMAGES_PATH >/dev/null

# update list
./make_list.sh

popd >/dev/null 2>&1

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

# at the end of test move this file in TEST_FOLDER
LOG_DATA="$TA_LOG_PATH/`date --rfc-3339='date'`.log"

pushd $TA_IMAGES_PATH >/dev/null
# set a link to image of running kernel
if [[ ! -f "$TA_START_LINK" ]]; then
	ln -sT "vmlinuz-`uname -r`" $TA_START_LINK
	echo "******* testing starts ********" >> $LOG_DATA
fi
popd >/dev/null 2>&1

# variant of running kernel, used to find suitable 
# benchmark for running kernel
VARIANT=`uname -r | cut -d'_' -f 2` 

echo "Running kernel is: `uname -r`" >> $LOG_DATA

TA_BMARKS_CHECK="$TA_BASE/bmarks-check"
TA_BMARKS_PUSH="$TA_BASE/bmarks-push"
TA_BMARKS_SELECT="$TA_BASE/bmarks-select"

for t in $TA_BMARKS_CHECK $TA_BMARKS_PUSH $TA_BMARKS_SELECT; do

	if [[ $t ==  $TA_BMARKS_CHECK ]]; then
		./init_env.sh check
		cp $TA_BMARKS_CHECK/* $TA_BMARKS_PATH
		SUFFIX="check"
	fi

	if [[ $t ==  $TA_BMARKS_PUSH ]]; then
		./init_env.sh push
		cp $TA_BMARKS_PUSH/* $TA_BMARKS_PATH
		SUFFIX="push"
	fi

	if [[ $t ==  $TA_BMARKS_SELECT ]]; then
		./init_env.sh select
		cp $TA_BMARKS_SELECT/* $TA_BMARKS_PATH
		SUFFIX="select"
	fi

	# Collect benchmarks to use for running kernel
	# expected filename: taBench-<variant>_<bsize>
	pushd $TA_BMARKS_PATH >/dev/null
	TA_BMARKS=`find . -executable -name "nwBench-$VARIANT*" -exec basename \{\} \; 2>/dev/null`
	popd >/dev/null 2>&1

	if [ x"$TA_BMARKS" == "x" ]; then
		echo "No (runnable) benchmark to use find into [$TA_BMARKS_PATH]" >> $LOG_DATA
		exit 2;
	fi
	echo "Benchmarks to use: ["$TA_BMARKS"]" >> $LOG_DATA


	pushd $TA_SCRIPTS_PATH >/dev/null
	TA_KERN_FUNC_SCRIPTS=`find . -executable -name "*_func.sh" -exec basename \{\} \; 2>/dev/null`
	popd >/dev/null 2>&1
	if [ x"$TA_KERN_FUNC_SCRIPTS" == "x" ]; then
		echo "No (runnable) kernel function test scripts to run find into [$TA_SCRIPTS_PATH]" >> $LOG_DATA
		exit 2;
	fi
	echo "Test scripts to run: ["$TA_KERN_FUNC_SCRIPTS"]" >> $LOG_DATA

	echo "benchmarks starts ..." >> $LOG_DATA
	#
	# setup environment for benchmark execution 

	# mount debufs
	echo "Mountinfg debugfs" >> $LOG_DATA
	mount_debugfs >> $LOG_DATA

	# create folder to contain benchmark data
	pushd $TA_RESULTS_PATH >/dev/null
	if [ ! -d $TEST_FOLDER ]; then 
		mkdir $TEST_FOLDER
	fi

	echo > $GLOBAL_LIST
	echo "TEST_FOLDER created" >> $LOG_DATA

	pushd $TEST_FOLDER >/dev/null
	if [ ! -d $GRAPH_FOLDER ]; then
		mkdir $GRAPH_FOLDER
	fi

	echo "GRAPH FOLDER created" >> $LOG_DATA

	if [ ! -d $DATA_FOLDER ]; then
		mkdir $DATA_FOLDER
	fi

	echo "DATA FOLDER created" >> $LOG_DATA

	if [ ! -d $PNG_FOLDER ]; then
		mkdir $PNG_FOLDER
	fi

	echo "PNG FOLDER created" >> $LOG_DATA

	popd >/dev/null 2>&1 # I'm in TA_RESULTS_PATH

	# launch benchmarks
	pushd $TEST_FOLDER >/dev/null

	for i in `seq $NR_TRY_FUNC_TEST`; do
		for bench in $TA_KERN_FUNC_SCRIPTS; do	
			for d in $DIM_FUNC_LIST; do
			    LOG_RUN="${SUFFIX}_func_test_$bench_`uname -r`_${i}_${d}.log"
			    echo "" >> $LOG_RUN
			    echo "---> Function call test: Start stat_func with $d KB buffer dimension (Try $i)" >> $LOG_RUN
			    BENCH=`echo "$TA_BMARKS" | grep $d`
			    $bench -b "$BENCH" -i "$i" -d "$d" >> $LOG_RUN 2>&1
			    echo "---> Function call test: Finish stat_func with $d KB buffer dimension (Try $i)" >> $LOG_RUN
			done
		done
	done

	TA_FUNC_COUNT_FILE=`find $DATA_FOLDER -type f -name "*_${PER_FUNC_TAG}_*_stats.txt" 2>/dev/null`
	for c in $TA_FUNC_COUNT_FILE; do
		local_graphics.sh -f "$c" -d "$DIM_FUNC_LIST" 
	done
	
	mv $PNG_FOLDER ${PNG_FOLDER}_${SUFFIX}
	mv $GRAPH_FOLDER ${GRAPH_FOLDER}_${SUFFIX}
	mv $DATA_FOLDER ${DATA_FOLDER}_${SUFFIX}

	popd >/dev/null 2>&1 #I'm in TA_RESULTS_PATH
	
	popd >/dev/null 2>&1 #I'm in TA_BASE

	echo "benchmarks finished ..." >> $LOG_DATA

done

#----- Load the last kernel executed (if any)

# find position of running kernel in IMAGES_LIST
# in order to execute next kernel

pushd $TA_IMAGES_PATH >/dev/null
NEXT_KERNEL=`cat $TA_IMAGES_LIST | grep "<\`uname -r\`>" |\
			 awk -v "col_next_kernel=$COL_NEXT_KERNEL"  '{print $(col_next_kernel)}'`
popd >/dev/null 2>&1 #I'm in TA_BASE

if [ x$NEXT_KERNEL == "x" ]; then
	echo "Next kernel to boot not found" >> $LOG_DATA
	exit 2;
fi	

pushd $TA_IMAGES_PATH >/dev/null
TA_START_IMAGE=`readlink $TA_START_LINK  2>/dev/null`
popd >/dev/null 2>&1 #I'm in TA_BASE

if [ x$TA_START_IMAGE == "x" ]; then
	echo "Start image not found in [$TA_START_IMAGE]" >> $LOG_DATA
	exit 2;
fi

# check for stop
if [[ $NEXT_KERNEL != $TA_START_IMAGE ]]; then
	echo "Next kernel to run [$NEXT_KERNEL]" >> $LOG_DATA
	VERSION=`echo $NEXT_KERNEL | cut -d'-' -f 2`
	# copy all kernel stuff under name _test_kernel
	# use \cp because cp is cp -i alias
	pushd $TA_IMAGES_PATH >/dev/null
	\cp config-$VERSION /boot/config-$TEST_KERNEL 
	\cp System.map-$VERSION /boot/System.map-$TEST_KERNEL 
	\cp initrd-$VERSION.img /boot/initrd-$TEST_KERNEL.img 
	\cp vmlinuz-$VERSION /boot/vmlinuz-$TEST_KERNEL	
	popd >/dev/null #I'm in TA_BASE

	# update status
	echo "1" > $STATUS_BENCH

	# update running test
	echo `basename $0` > $RUNNING_BENCH

	#echo "reboot"
	reboot	
else
	echo "************** test finished ****************" >> $LOG_DATA

	# update test status
	echo "0" > $STATUS_BENCH

	# update running test
	echo > $RUNNING_BENCH

	pushd $TA_IMAGES_PATH >/dev/null
	rm $TA_START_LINK
	popd >/dev/null 2>&1 #I'm in $TA_BASE

	chown -R $USER.$GROUP $TA_RESULTS_PATH
	chown -R $USER.$GROUP $TA_LOG_PATH
	rm test_init.env
fi
