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


#################   don't touch following lines

print_usage() {

cat - <<EOF

Instruction load miss benchmark

Run benchmark and measure percentage of L1 load cache miss

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

# Check on input parameters
if [[ x$BENCH == "x" || x$ID_BENCH == "x" || x$DIM == "x" ]]; then
	print_usage
	exit
fi

# --- local variables

MONITOR="${MONITOR_NOTRACE}_${DIM}KB"
PREFIX="l1i_load_bench_${PER_DIM_TAG}"
PREFIX_BENCH="${PREFIX}_`uname -r`"
NAME_BENCH="${PREFIX_BENCH}_${ID_BENCH}"

LOAD_MISS="L1-icache-load-misses"
LOAD_REF="L1-icache-loads"
LOAD_EVENT="L1-icache-load"

# TODO guarda il discorso dei ns
TIME_UNIT="" 

# --- produced files
# contain statistics data
STATS_FILE="${PREFIX_BENCH}_stats.txt"
TAG="<$NAME_BENCH><$DIM>"

# --- header for graphics 
PREF_PERC="perc"
PREF_ACC="acc"

TITLE_PERC="Percentage_instr_load_misses"
XLAB_PERC="KB"
YLAB_PERC="%"
PREFIX_BENCH_PERC="${PREF_PERC}_${PREFIX_BENCH}"

TITLE_ACC="Number_of_instr_access"
XLAB_ACC="KB"
YLAB_ACC="nr_access"
PREFIX_BENCH_ACC="${PREF_ACC}_${PREFIX_BENCH}"

touch $DATA_FOLDER/$STATS_FILE
# parameters for "local" graphics construction
HEADER=`cat $DATA_FOLDER/$STATS_FILE | grep "$TITLE_TAG"`
# There could be different header in STATS_FILE but there
# must be only one copy for each header
if [ x$HEADER == "x" ]; then
	
	# header read from local_graphics.sh to build graphic

	# graphic's title
	echo "#${TITLE_TAG}$TITLE_PERC" >> $DATA_FOLDER/$STATS_FILE
	# label of x axis
	echo "#${XLAB_TAG}$XLAB_PERC" >> $DATA_FOLDER/$STATS_FILE
	# label of y axis
	echo "#${YLAB_TAG}$YLAB_PERC" >> $DATA_FOLDER/$STATS_FILE
	# prefix to use to give a name at "local" graphic
	echo "#${PREFIX_PLOT_TAG}${PREFIX_BENCH_PERC}" >> $DATA_FOLDER/$STATS_FILE
	# index of column that contains average values read by local_graphics.sh
	echo "#${AVG_COL_TAG}${AVG_COL}" >> $DATA_FOLDER/$STATS_FILE
	# index of column that contains variance values read by local_graphics.sh
	echo "#${VAR_COL_TAG}${UNC_COL}" >> $DATA_FOLDER/$STATS_FILE


	# header read from local_graphics.sh to build graphic

	# graphic's title
	echo "#${TITLE_TAG}$TITLE_ACC" >> $DATA_FOLDER/$STATS_FILE
	echo "#${XLAB_TAG}$XLAB_ACC" >> $DATA_FOLDER/$STATS_FILE
	echo "#${YLAB_TAG}$YLAB_ACC" >> $DATA_FOLDER/$STATS_FILE
	echo "#${PREFIX_PLOT_TAG}${PREFIX_BENCH_ACC}" >> $DATA_FOLDER/$STATS_FILE
	echo "#${AVG_COL_TAG}${AVG_ACC_COL}" >> $DATA_FOLDER/$STATS_FILE
	echo "#${VAR_COL_TAG}${UNC_ACC_COL}" >> $DATA_FOLDER/$STATS_FILE
fi

# read if GLOBAL_LIST has already $PREFIX entry
# because an entry in GLOBAL_LIST correspond to a 
# "global" graphic 
HEADER_GLOBAL_LIST=`cat $TA_RESULTS_PATH/$GLOBAL_LIST | grep $TITLE_PERC`
if [ x$HEADER_GLOBAL_LIST == "x" ]; then
	echo "${PREF_PERC}_${PREFIX}#$TITLE_PERC#$XLAB_PERC#$YLAB_PERC" >> $TA_RESULTS_PATH/$GLOBAL_LIST
fi
HEADER_GLOBAL_LIST=

HEADER_GLOBAL_LIST=`cat $TA_RESULTS_PATH/$GLOBAL_LIST | grep $TITLE_ACC`
if [ x$HEADER_GLOBAL_LIST == "x" ]; then
	echo "${PREF_ACC}_${PREFIX}#$TITLE_ACC#$XLAB_ACC#$YLAB_ACC" >> $TA_RESULTS_PATH/$GLOBAL_LIST
fi
HEADER_GLOBAL_LIST=

# run benchmark with perf in order to read L1 load
# cache miss 
for i in `seq $NUM_REPEAT_PERF`; do
        perf stat -i -a -e $LOAD_REF -e $LOAD_MISS chrt -f $PRIO_RUN_BENCH run_benchs.sh $BENCH $MONITOR > $PERF_FILE.$i 2>&1
done

cat $PERF_FILE.* | grep $LOAD_EVENT | \
                awk '
                        BEGIN { 
                                i=0; 
                                loads=0; 
                              } 
                        
                        i==0 { 
                                loads=$1; 
                                i=1; 
                                next 
                        } 
                        
                        i==1 {
				mean=$1/loads; 
				print mean*100
                                i=0; 
                                next  
                        } 
			' > cache_miss_rate.txt

# cache_miss_rate.txt contains NUM_REPEAT_PERF 
# percentages of load misses, now compute average
# and variance of this list of value
CACHE_MISS="Percent_miss:`calc_stat.sh -f "cache_miss_rate.txt" -n 1 -l -t "$TIME_UNIT"`"
cat $PERF_FILE.* | grep $LOAD_REF | awk '{print $1}' > temp_access.txt
CACHE_ACCESS="Access_cache:`calc_stat.sh -f "temp_access.txt" -n 1 -l -t "$TIME_UNIT"`"

# put CACHE_MISS value in STATS_FILE tagged with TAG 
# CACHE_MISS will have this format:
# 
# Average = %lf Var = %lf Min = %lf Max = %lf
# Where:
# -> Average = mean of values contained in cache_miss_rate.txt
# -> Variance = variance of values ...
# -> Max = max of values ...
# -> Min = min of values ...

ALL_STATS="$CACHE_MISS $CACHE_ACCESS"
echo "${TAG}$ALL_STATS"  >> $DATA_FOLDER/$STATS_FILE

CACHE_MISS_DATA="${NAME_BENCH}_$DIM"
mkdir $DATA_FOLDER/$CACHE_MISS_DATA

mv cache_miss_rate.txt $DATA_FOLDER/$CACHE_MISS_DATA 
mv $PERF_FILE.* $DATA_FOLDER/$CACHE_MISS_DATA

echo "done"

