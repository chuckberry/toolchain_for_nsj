#!/bin/bash

if [ x$INIT_SOURCE == "x" ]; then
	echo "export INIT_SOURCE like environment variable"
	exit 1;	
fi

if [ ! -f $INIT_SOURCE ]; then
	echo "run init_env.sh to select which profile do you want"
	exit 1;
fi

source $INIT_SOURCE
source $FUNC_SOURCE


################  dont' touch here ########################

print_usage() {

cat - <<EOF

Function call benchmark

Run benchmark and measure average execution time of 
kernel function call traced with funcgraph tracer

-h 
	help
-b
	binaries of benchmark to use
-i
	number of iteration of performance test in progress
-d
	buffer dimension used to perform benchmark


EOF

}

while getopts "hb:i:d:" optionName; do

	case "$optionName" in
		h) 
			print_usage	
			exit
			;;
		b)
			BENCH="$OPTARG"
			;;
		i)
			ID_BENCH="$OPTARG"
			;;
		d)
			DIM="$OPTARG"
			;;
		\?) 
			print_usage	
			exit
			;;
	esac
done

#Check on input parameters
if [[ x$BENCH == "x" || x$ID_BENCH == "x" || x$DIM == "x" ]]; then
	print_usage
	exit
fi

# --- local variables

MONITOR="${MONITOR_FTRACE}_${DIM}KB"

DATA_FILE="data_`uname -r`_${ID_BENCH}_KB${DIM}.txt"

# Run benchmark
chrt --fifo $PRIO_BENCH ${BENCH} | chrt --fifo $PRIO_MONITOR ${MONITOR} "$NAME_OF_BENCH_TRACED" 

rm $MONITOR_OUT_TRACE
rm $MONITOR_OUT_HIST

# computation will be executed for all functions in FUNC_LIST
AR_SIZE=0
j=1
for i in $FUNC_LIST; do 
	AR_FUN[$j]=$i
	j=`echo "$j+1" | bc`
	AR_SIZE=`echo "$AR_SIZE+1" | bc`
done

# Records in trace file are arranged in chronological order
# in this way we have this situation
#  
# ts   	 cpu	   	time 	    func_name 		
# 1	  1)                     	ttwu() {
# 2       2)	   			ttwu() {
# 3 	  1)		0.5 us		}
# 4       2)		0.4 us		}
#
# What we want to do is to transform trace file in this file
#
# ts   	 cpu	   	time 	    func_name 		
# 1	  1)                     	ttwu() {
# 3 	  1)		0.5 us		} -> we are sured that is refferred at ttwu() on cpu 1
# 2       2)	   			ttwu() {
# 4       2)		0.4 us		}
#
# If functions we want to trace are in a not preemptable kernel section,
# we are sure that a call of this function starts on a certain cpu
# and will end on that cpu. In this way it is easy, with an awk scripts, 
# calculate exec. time of each function call
#
# Attention!!! This trick is correct ONLY IF function that you want
# to trace is in a not preemptable kernel section, otherwise 
# we are not sure that a function starts and ends on same cpu
#

for k in 0 1 2 3; do
	echo "scanning cpu $k ... "
	cat $TRACE_PATH/trace | sed -e 's/;//g' | awk -v "idx=$k)" \
			 '{if ($3 == idx || ($3 == "=>" && $1 == idx ) ) {print $0} }'  >> $DATA_FOLDER/$DATA_FILE
	echo "#finish cpu $k" >> $DATA_FOLDER/$DATA_FILE
	echo "done"
done

# restore debugfs at original condition
clean_trace

# calculate statistics 
for i in `seq $AR_SIZE`; do #size of array

	# contains statistics 
	PREFIX="stat_func_${AR_FUN[$i]}_${PER_FUNC_TAG}"
	PREFIX_BENCH="${PREFIX}_`uname -r`"
	NAME_BENCH="${PREFIX_BENCH}_${ID_BENCH}_${DIM}"
	
	STATS_FILE="${PREFIX_BENCH}_stats.txt"
	STATS_FILE_CPU="${PREFIX_BENCH}_stats_cpu.txt"
	SAMPLES_TIME="${NAME_BENCH}_samples_time.txt"
	IMG_SAMPLES_TIME="img_${NAME_BENCH}_samples_time.png"
	PERC_FILE="${NAME_BENCH}_perc.txt"
	IMG_PERC_FILE="img_${NAME_BENCH}_perc.png"

	SAMPLES_TIME_PREFIX_CPU="${NAME_BENCH}_samples_time_cpu"
	IMG_SAMPLES_TIME_PREFIX_CPU="img_${NAME_BENCH}_samples_time_cpu"
	PERC_FILE_PREFIX_CPU="${NAME_BENCH}_perc_cpu"
	IMG_PERC_FILE_PREFIX_CPU="img_${NAME_BENCH}_perc_cpu"

	# --- header for graphic
	PREF_AVG="avg"
	PREF_COUNT="call"

	# header read from local_graphics.sh to build graphic
	TITLE_AVG="Avg_Ex_time_${AR_FUN[$i]}"
	XLAB_AVG="KB"
	YLAB_AVG="Time_(us)"	
	PREFIX_BENCH_AVG="${PREF_AVG}_${PREFIX_BENCH}"

	TITLE_COUNT="Number_of_call_${AR_FUN[$i]}"
	XLAB_COUNT="KB"
	YLAB_COUNT="nr_call"
	PREFIX_BENCH_COUNT="${PREF_COUNT}_${PREFIX_BENCH}"

	touch $DATA_FOLDER/$STATS_FILE
	# parameters for "local" graphics construction
	HEADER=`cat $DATA_FOLDER/$STATS_FILE | grep "$TITLE_TAG"`
	# There could be different header in STATS_FILE but there
	# must be only one copy for each header
	if [ x"$HEADER" == "x" ]; then

		# graphic's title
		echo "#${TITLE_TAG}$TITLE_AVG" >> $DATA_FOLDER/$STATS_FILE
		# label of x axis
		echo "#${XLAB_TAG}$XLAB_AVG" >> $DATA_FOLDER/$STATS_FILE
		# label of y axis
		echo "#${YLAB_TAG}$YLAB_AVG" >> $DATA_FOLDER/$STATS_FILE
		# prefix to use to give a name at "local" graphic
		echo "#${PREFIX_PLOT_TAG}${PREFIX_BENCH_AVG}" >> $DATA_FOLDER/$STATS_FILE
		# index of column that contains average values read by local_graphics.sh
		echo "#${AVG_COL_TAG}${AVG_COL}" >> $DATA_FOLDER/$STATS_FILE
		# index of column that contains variance values read by local_graphics.sh
		echo "#${VAR_COL_TAG}${UNC_COL}" >> $DATA_FOLDER/$STATS_FILE

		echo "#${TITLE_TAG}${TITLE_COUNT}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${XLAB_TAG}${XLAB_COUNT}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${YLAB_TAG}${YLAB_COUNT}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${PREFIX_PLOT_TAG}${PREFIX_BENCH_COUNT}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${AVG_COL_TAG}${COUNT_COL}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${VAR_COL_TAG}${COUNT_COL}" >> $DATA_FOLDER/$STATS_FILE
	fi
	
	# read if GLOBAL_LIST has already an entry for each graphic
	# that this file want to generate, because an entry in GLOBAL_LIST
	# correspond to a "global" graphic
	HEADER_GLOBAL_LIST=`cat $TA_RESULTS_PATH/$GLOBAL_LIST | grep "${PREF_AVG}_$PREFIX"`
	if [ x"$HEADER_GLOBAL_LIST" == "x" ]; then
		echo "${PREF_AVG}_$PREFIX#$TITLE_AVG#$XLAB_AVG#$YLAB_AVG" >> $TA_RESULTS_PATH/$GLOBAL_LIST
	fi
	HEADER_GLOBAL_LIST=""

	HEADER_GLOBAL_LIST=`cat $TA_RESULTS_PATH/$GLOBAL_LIST | grep "${PREF_COUNT}_$PREFIX"`
	if [ x"$HEADER_GLOBAL_LIST" == "x" ]; then
		echo "${PREF_COUNT}_$PREFIX#$TITLE_COUNT#$XLAB_COUNT#$YLAB_COUNT" >> $TA_RESULTS_PATH/$GLOBAL_LIST
	fi
	HEADER_GLOBAL_LIST=""

	echo "calculating stats for func ${AR_FUN[$i]}"
	awk -v "fun=${AR_FUN[$i]}" -v "task_list=${FUNC_TASK_LIST}" -f $PATH_SCRIPT/stat_func.awk $DATA_FOLDER/$DATA_FILE >> $DATA_FOLDER/$SAMPLES_TIME
#	echo "*************** Try $ID_BENCH **********************" >> $DATA_FOLDER/$STATS_FILE_CPU 
#	cat $DATA_FOLDER/$SAMPLES_TIME | grep "#" >> $DATA_FOLDER/$STATS_FILE_CPU	

	## calculate how are distributed call of function to trace
	#NR_FUNC_CALL=`cat $DATA_FOLDER/$SAMPLES_TIME | sed -e '/^#/d' | wc -l`
	#echo "total call: $NR_FUNC_CALL" >> $DATA_FOLDER/$CPU_CALL_FILE

#	SAMPLES=`cat $DATA_FOLDER/$SAMPLES_TIME`
#	for k in 0 1 2 3; do
#		SAMPLE_TIME_CPU="${SAMPLES_TIME_PREFIX_CPU}_$k.txt"
#		PERC_FILE_CPU="${PERC_FILE_PREFIX_CPU}_$k.txt"
#		IMG_SAMPLE_TIME_CPU="${IMG_SAMPLES_TIME_PREFIX_CPU}_$k.png"
#		IMG_PERC_FILE_CPU="${IMG_PERC_FILE_PREFIX_CPU}_$k.png"
#
#		echo "$SAMPLES" | grep -v "#" | grep "$k)" | sed -e 's/'$k')//g' >> $DATA_FOLDER/$SAMPLE_TIME_CPU
#		AVG_FUN=`calc_stat.sh -f "$DATA_FOLDER/$SAMPLE_TIME_CPU" -n 1 -a`
#		VAR_FUN=`calc_stat.sh -f "$DATA_FOLDER/$SAMPLE_TIME_CPU" -n 1 -u`
#		COUNT=`echo "$SAMPLES" | grep "<c$k>call" | awk '{print $NF}'`
#
#		generate_histogram.sh $DATA_FOLDER/$SAMPLE_TIME_CPU "us" > hist
#		generate_percentili.sh hist $COUNT > $DATA_FOLDER/$PERC_FILE_CPU
#
#		traceplotgif.sh "$DATA_FOLDER/$SAMPLE_TIME_CPU" "$PNG_FOLDER/$IMG_SAMPLE_TIME_CPU" \
#					"count = $COUNT cpu: $k ${AR_FUN[$i]}_`uname -r`"  "Time (us)" "nr_of_call"
#		traceplotgif.sh "$DATA_FOLDER/$PERC_FILE_CPU" "$PNG_FOLDER/$IMG_PERC_FILE_CPU" \
#					"fdr of cpu: $k (us) Avg = $AVG_FUN Var = $VAR_FUN ${AR_FUN[$i]}_`uname -r`"  "Percentage" "Time (ns)"
#	done

	# put STATS value in STATS_FILE tagged with <DIM> 
	# STATS will have this format:
	# 
	# Average = %lf Var = %lf Min = %lf Max = %lf
	# Where:
	# -> Average = mean of values contained in SAMPLES_TIME 
	# -> Variance = variance of values ...	 
	# -> Max = max of values ...
	# -> Min = min of values ...
	# -> count = number of call of ${AR_FUN[$i]}

	NR_FUNC_CALL=`cat "$DATA_FOLDER/$SAMPLES_TIME"  | grep "<EOF>call" | awk '{print $NF}'`
#	ALL_LATENCIES=`cat "$DATA_FOLDER/$SAMPLES_TIME" | grep "<EOF>time" | awk '{print $NF}'`

	STATS="`calc_stat.sh -f "$DATA_FOLDER/$SAMPLES_TIME" -n 2 -l` count = $NR_FUNC_CALL"
	echo "<$DIM>$STATS" >> $DATA_FOLDER/$STATS_FILE

	AVG_FUN="`calc_stat.sh -f "$DATA_FOLDER/$SAMPLES_TIME" -n 2 -a`"
	# compute an uncertainty
	VAR_FUN="`calc_stat.sh -f "$DATA_FOLDER/$SAMPLES_TIME" -n 2 -u`"

#	FILTER_SAMPLES_TIME="temp"
#	cat $DATA_FOLDER/$SAMPLES_TIME | grep -v "#" | awk '{print $NF}' > $FILTER_SAMPLES_TIME
#
#	generate_histogram.sh $FILTER_SAMPLES_TIME "us" > hist 
#	generate_percentili.sh hist $NR_FUNC_CALL > $DATA_FOLDER/$PERC_FILE
#
#	traceplotgif.sh "$FILTER_SAMPLES_TIME" "$PNG_FOLDER/$IMG_SAMPLES_TIME" \
#			"count = $NR_FUNC_CALL time = $ALL_LATENCIES ${TITLE_AVG}_`uname -r`"  "Time (us)" "nr_of_call"
#	traceplotgif.sh "$DATA_FOLDER/$PERC_FILE" "$PNG_FOLDER/$IMG_PERC_FILE" \
#			"fdr: (us) Avg = $AVG_FUN Var = $VAR_FUN ${AR_FUN[$i]}_`uname -r`" "Percentage" "Time (ns)" 
#
#	gzip $DATA_FOLDER/$SAMPLES_TIME
	rm $DATA_FOLDER/$SAMPLES_TIME
#	gzip $DATA_FOLDER/$PERC_FILE
#	for k in 0 1 2 3; do
#		SAMPLE_TIME_CPU="${SAMPLES_TIME_PREFIX_CPU}_$k.txt"
#		PERC_FILE_CPU="${PERC_FILE_PREFIX_CPU}_$k.txt"
#		gzip $DATA_FOLDER/$SAMPLE_TIME_CPU
#		gzip $DATA_FOLDER/$PERC_FILE_CPU
#	done
done

# compress data file
gzip $DATA_FOLDER/$DATA_FILE
#rm hist
#rm $FILTER_SAMPLES_TIME

