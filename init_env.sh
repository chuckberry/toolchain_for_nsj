#!/bin/bash

function print_usage {
cat - <<EOF

Initialize benchmark environment according to
following profile

 default
 performance
 function
 cpuaffinity
 experimental

EOF


}

if [ $# -lt 1 ]; then
	print_usage
	exit
fi


case "$1" in
	help) 
		print_usage	
		exit
		;;
	default)
		echo "default profile selected"
		DIM_LIST="2 4 8 16"
		NR_TRY_PERFORMANCE_TEST="5"
		TA_MAKE_PERFORMANCE_TEST="1"
		TASK_LIST="wave0 wave1 wave2 wave3 mixer0 mixer1 mixer2"
		NUM_REPEAT_PERF="10"
		FUNC_LIST="cpupri_find()"
		DIM_FUNC_LIST="2"
		NR_TRY_FUNC_TEST="10"
		TA_MAKE_FUNC_TEST="1"
		;;
	experimental)
		echo "experimental profile selected"
		DIM_LIST="16"
		NR_TRY_PERFORMANCE_TEST="3"
		TASK_LIST="wave0 wave1 wave2 wave3 mixer0 mixer1 mixer2"
		NUM_REPEAT_PERF="5"
		TA_MAKE_PERFORMANCE_TEST="1"
		TA_MAKE_FUNC_TEST="0"
		FUNC_LIST="push_rt_task() pull_rt_task()"
		FUNC_TASK_LIST="wave0 wave1 wave2 wave3 mixer0 mixer1 mixer2 monitor"
		DIM_FUNC_LIST="2 16"
		NR_TRY_FUNC_TEST="2"
		;;
	performance)
		echo "performance profile selected"
		DIM_LIST="2 4 8 16"
		NR_TRY_PERFORMANCE_TEST="5"
		TA_MAKE_PERFORMANCE_TEST="1"
		TASK_LIST="wave0 wave1 wave2 wave3 mixer0 mixer1 mixer2"
		NUM_REPEAT_PERF="10"
		TA_MAKE_FUNC_TEST="0"
		SECTION_LIST="vanilla exper1 exper2 exper3 exper4"
		;;
	function)	
		echo "function profile selected"
		TA_MAKE_PERFORMANCE_TEST="0"
		FUNC_LIST="cpupri_find() select_task_rq_rt() find_lowest_rq() push_rt_task() pull_rt_task()"
		FUNC_TASK_LIST="wave0 wave1 wave2 wave3 mixer0 mixer1 mixer2 monitor"
		DIM_FUNC_LIST="2 16"
		NR_TRY_FUNC_TEST="5"
		TA_MAKE_FUNC_TEST="1"
		;;
	check)	
		echo "check profile selected"
		TA_MAKE_PERFORMANCE_TEST="0"
		FUNC_LIST="cpupri_find() check_preempt_curr_rt()"
		DIM_FUNC_LIST="2"
		NR_TRY_FUNC_TEST="2"
		TA_MAKE_FUNC_TEST="1"
		CPUAFF_TEST=""
		;;
	push)	
		echo "push profile selected"
		TA_MAKE_PERFORMANCE_TEST="0"
		FUNC_LIST="cpupri_find() push_rt_task()"
		DIM_FUNC_LIST="2"
		NR_TRY_FUNC_TEST="2"
		TA_MAKE_FUNC_TEST="1"
		;;
	select)	
		echo "select profile selected"
		TA_MAKE_PERFORMANCE_TEST="0"
		FUNC_LIST="cpupri_find() select_task_rq_rt()"
		DIM_FUNC_LIST="2"
		NR_TRY_FUNC_TEST="2"
		TA_MAKE_FUNC_TEST="1"
		;;
	cpuaffinity)
		echo "cpuaffinity profile selected"
		DIM_LIST="2 4 8 16"
		NR_TRY_PERFORMANCE_TEST="5"
		TA_MAKE_PERFORMANCE_TEST="1"
		TASK_LIST="wave0 wave1 wave2 wave3 mixer0 mixer1 mixer2"
		NUM_REPEAT_PERF="10"
		FUNC_LIST="cpupri_find()"
		DIM_FUNC_LIST="2"
		NR_TRY_FUNC_TEST="2"
		TA_MAKE_FUNC_TEST="1"
		CPUAFF_TEST="optim worst"
		;;	
	\?) 
		print_usage	
		exit
		;;
esac

TEST_INIT_FILE="test_init.env"
# configuring section list
echo "configuring section list ..."
TEMP_LIST=`ls -l images | grep img | awk -F'_' '{print $NF}' | sed -e 's/\.img//g'`
# tricky to remove \n character
SECTION_LIST=`echo $TEMP_LIST` 
 

cat init.env | \
sed -e 's/TA_CONFIGURED=.*/TA_CONFIGURED=1/g'\
 -e 's/DIM_LIST=.*/DIM_LIST="'"$DIM_LIST"'"/g'\
 -e 's/NR_TRY_PERFORMANCE_TEST=.*/NR_TRY_PERFORMANCE_TEST="'"$NR_TRY_PERFORMANCE_TEST"'"/g'\
 -e 's/TA_MAKE_PERFORMANCE_TEST=.*/TA_MAKE_PERFORMANCE_TEST="'"$TA_MAKE_PERFORMANCE_TEST"'"/g'\
 -e 's/TASK_LIST=.*/TASK_LIST="'"$TASK_LIST"'"/g'\
 -e 's/NUM_REPEAT_PERF=.*/NUM_REPEAT_PERF="'"$NUM_REPEAT_PERF"'"/g'\
 -e 's/FUNC_LIST=.*/FUNC_LIST="'"$FUNC_LIST"'"/g'\
 -e 's/FUNC_TASK_LIST=.*/FUNC_TASK_LIST="'"$FUNC_TASK_LIST"'"/g'\
 -e 's/DIM_FUNC_LIST=.*/DIM_FUNC_LIST="'"$DIM_FUNC_LIST"'"/g'\
 -e 's/NR_TRY_FUNC_TEST=.*/NR_TRY_FUNC_TEST="'"$NR_TRY_FUNC_TEST"'"/g'\
 -e 's/TA_MAKE_FUNC_TEST=.*/TA_MAKE_FUNC_TEST="'"$TA_MAKE_FUNC_TEST"'"/g'\
 -e 's/SECTION_LIST=.*/SECTION_LIST="'"$SECTION_LIST"'"/g'\
 -e 's/CPUAFF_TEST=.*/CPUAFF_TEST="'"$CPUAFF_TEST"'"/g' > $TEST_INIT_FILE

# check toolchain
echo "check toolchain ..."
./check_toolchain.sh 
