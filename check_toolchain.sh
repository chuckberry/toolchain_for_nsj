#!/bin/bash

if [ ! -f test_init.env ]; then
	echo "run init_env.sh to select which profile do you want"
	exit 1;
fi

source test_init.env


function print_usage {
cat - <<EOF

Check if reults dir, log dir and other status files are not 
clean, in this case not execute run.sh

EOF
}

# check results
pushd $TA_RESULTS_PATH >/dev/null
CLEAN=`cat $CLEAN_RESULTS`
if [ x$CLEAN != "x" ]; then
	echo "ERROR: clean results"
	CHECK_FAILED=1;
fi
popd >/dev/null 2>&1


# check log files
pushd $TA_LOG_PATH >/dev/null
DATE_TODAY="`date --rfc-3339='date'`.log"
LOG_FILES=`ls -l | grep "$DATE_TODAY" | awk '{print $NF}'`
if [[ x$LOG_FILES != "x" ]]; then
	echo "ERROR: clean log files"
	CHECK_FAILED=1;
fi
popd >/dev/null 2>&1


# check kernel images
pushd $TA_IMAGES_PATH >/dev/null
if [ -f $TA_IMAGES_PATH ]; then
	KERNELS=`cat $TA_IMAGES_LIST | awk '{print $1}' | sed -e 's/<//g' -e 's/>//g'`
	for i in $KERNELS; do
		KERNEL=`ls -l | grep $i`
		if [[ x$KERNEL == "x" ]]; then
			echo "ERROR: image_list not correct"
			CHECK_FAILED=1;
		fi
	done
fi
popd >/dev/null 2>&1

if [ x$CHECK_FAILED != "x" ]; then
	echo "checks failed"
	# deny to perform run.sh
	echo 0 > $START_BENCH
	exit 1;
fi

echo "Toolchain cleared, start test"
echo > $START_BENCH
