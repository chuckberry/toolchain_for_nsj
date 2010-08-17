#!/bin/bash

source $INIT_SOURCE
source $FUNC_SOURCE

#
#	dont' touch here

print_usage() {

cat - <<EOF

func call statistics

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

if [[ x$BENCH == "x" || x$ID_BENCH == "x" || x$DIM == "x" ]]; then
	print_usage
	exit
fi

# --- local variables

MONITOR="${MONITOR_FTRACE}_${DIM}KB"

DATA_FILE="data_`uname -r`${CPUAFF_SUFFIX}_${ID_BENCH}_KB${DIM}.txt"
DATA_COMPRESSED="data_`uname -r`${CPUAFF_SUFFIX}_${ID_BENCH}_KB${DIM}.gz"

# PRIO_BENCH PRIO_MONITOR are config in .conf
chrt --fifo $PRIO_BENCH ${BENCH} | chrt --fifo $PRIO_MONITOR ${MONITOR} "$NAME_OF_BENCH_TRACED" 

rm $MONITOR_OUT_TRACE
rm $MONITOR_OUT_HIST

AR_SIZE=0
j=1
for i in $FUNC_LIST; do 
	AR_FUN[$j]=$i
	j=`echo "$j+1" | bc`
	AR_SIZE=`echo "$AR_SIZE+1" | bc`
done

if [ ! -f $DATA_FILE ]; then
	for k in 0 1 2 3; do
		echo "scanning cpu $k ... "
		cat $TRACE_PATH/trace | sed -e 's/;//g' | awk -v "idx=$k)" \
				 '{if ($3 == idx || ($3 == "=>" && $1 == idx ) ) {print $0} }'  >> $DATA_FILE
		echo "#finish cpu $k" >> $DATA_FILE
		echo "done"
	done
	clean_trace
fi

# calculate statistics 
for i in `seq $AR_SIZE`; do #size of array

	# contains statistics of all tries
	PREFIX="case_stat_func${CPUAFF_SUFFIX}_${AR_FUN[$i]}_${PER_FUNC_TAG}"
	PREFIX_BENCH="${PREFIX}_`uname -r`"
	NAME_BENCH="${PREFIX_BENCH}_${ID_BENCH}_${DIM}"
	
	STATS_FILE="${PREFIX_BENCH}_stats.txt"
	
	touch $DATA_FOLDER/$STATS_FILE
	# parameters for graphics
	HEADER=`cat $DATA_FOLDER/$STATS_FILE | grep "$TITLE_TAG"`
	if [ x"$HEADER" == "x" ]; then

		TITLE_AVG="Avg_Ex_time_(func_stat)"
		XLAB_AVG="Case:"
		YLAB_AVG="Time_(us)"	
		
		echo "#${TITLE_TAG}${TITLE_AVG}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${XLAB_TAG}${XLAB_AVG}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${YLAB_TAG}${YLAB_AVG}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${PREFIX_PLOT_TAG}${PREFIX_BENCH}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${AVG_COL_TAG}${AVG_COL}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${VAR_COL_TAG}${VAR_COL}" >> $DATA_FOLDER/$STATS_FILE
		
		TITLE_COUNT="Number_of_case_occurrence_(func_stat)"
		XLAB_COUNT="Case:"
		YLAB_COUNT="#_occurrence"
	
		echo "#${TITLE_TAG}${TITLE_COUNT}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${XLAB_TAG}${XLAB_COUNT}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${YLAB_TAG}${YLAB_COUNT}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${PREFIX_PLOT_TAG}occurrence_${PREFIX_BENCH}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${AVG_COL_TAG}${OCCURRENCE_COL}" >> $DATA_FOLDER/$STATS_FILE
		echo "#${VAR_COL_TAG}${OCCURRENCE_COL}" >> $DATA_FOLDER/$STATS_FILE
	fi
	
	# read if global list has already $PREFIX_BENCH entry
	HEADER_GLOBAL_LIST=`cat $TA_RESULTS_PATH/$GLOBAL_LIST | grep $PREFIX`
	if [ x"$HEADER_GLOBAL_LIST" == "x" ]; then
		echo "$PREFIX#$TITLE_AVG#$XLAB_AVG#$YLAB_AVG" >> $TA_RESULTS_PATH/$GLOBAL_LIST
		echo "occurrence_$PREFIX#$TITLE_COUNT#$XLAB_COUNT#$YLAB_COUNT" >> $TA_RESULTS_PATH/$GLOBAL_LIST
	fi

	echo "calculating stats..."
	SUM_CASE=`cat $DATA_FILE | grep "Case:" | wc -l`
	echo $SUM_CASE

	VALUE=""	
	for c in $CASE_FUNC_LIST; do
		VALUE=`awk -v "name_case=$c" -v "fun=${AR_FUN[$i]}" -v "sum_case=$SUM_CASE" \
				-f $PATH_SCRIPT/case_stat_func.awk $DATA_FILE`
		echo "<$DIM><$c>$VALUE" >> $DATA_FOLDER/$STATS_FILE   
	done
done

# compress data file
cat $DATA_FILE | gzip > $DATA_FOLDER/$DATA_COMPRESSED
rm $DATA_FILE

