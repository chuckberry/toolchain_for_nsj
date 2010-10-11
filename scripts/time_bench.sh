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

######################	don't touch here ##########################

print_usage() {

cat - <<EOF

Time benchmark

Run benchmark and measure Average Execution time of samples

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
PREFIX="time_bench_${PER_DIM_TAG}"
PREFIX_BENCH="${PREFIX}_`uname -r`"
NAME_BENCH="${PREFIX_BENCH}_${ID_BENCH}"
TIME_UNIT="us" #TODO guarda sto cazzo di us

# --- produced files

# contain statistics data
STATS_FILE="${PREFIX_BENCH}_stats.txt"
# contain exec. time of each of NR_SAMPLE samples produced by benchmark
SAMPLES_TIME="${NAME_BENCH}_${DIM}_samples_time.txt"
# contain cumulative distribution of exec. times of samples 
PERC_FILE="${NAME_BENCH}_${DIM}_perc.txt"
IMG_PERC_FILE="img_${NAME_BENCH}_${DIM}_perc.png"
IMG_SAMPLES_TIME="img_${NAME_BENCH}_${DIM}_samples_time.png"
TAG="<$NAME_BENCH><$DIM>"

# --- write header in STATS_FILE and in list for "global" graphics
touch $DATA_FOLDER/$STATS_FILE

# header read from local_graphics.sh to build graphic
TITLE="Avg_Ex_time"
XLAB="KB"
YLAB="Time_(us)"

# parameters for "local" graphics construction
HEADER=`cat $DATA_FOLDER/$STATS_FILE | grep "$TITLE_TAG"`
# There could be different header in STATS_FILE but there
# must be only one copy for each header
if [ x$HEADER == "x" ]; then


	# graphic's title
	echo "#${TITLE_TAG}$TITLE" >> $DATA_FOLDER/$STATS_FILE
	# label of x axis
	echo "#${XLAB_TAG}$XLAB" >> $DATA_FOLDER/$STATS_FILE
	# label of y axis
	echo "#${YLAB_TAG}$YLAB" >> $DATA_FOLDER/$STATS_FILE
	# prefix to use to give a name at "local" graphic
	echo "#${PREFIX_PLOT_TAG}${PREFIX_BENCH}" >> $DATA_FOLDER/$STATS_FILE
	# index of column that contains average values read by local_graphics.sh
	echo "#${AVG_COL_TAG}${AVG_COL}" >> $DATA_FOLDER/$STATS_FILE
	# index of column that contains variance values read by local_graphics.sh
	echo "#${VAR_COL_TAG}${VAR_COL}" >> $DATA_FOLDER/$STATS_FILE
fi

# read if GLOBAL_LIST has already $PREFIX_BENCH entry
# because an entry in GLOBAL_LIST correspond to a 
# "global" graphic 
HEADER_GLOBAL_LIST=`cat $TA_RESULTS_PATH/$GLOBAL_LIST | grep $PREFIX`
if [ x$HEADER_GLOBAL_LIST == "x" ]; then
	echo "$PREFIX#$TITLE#$XLAB#$YLAB" >> $TA_RESULTS_PATH/$GLOBAL_LIST
fi

# Run benchmark and monitor to produce Average Exec. time of samples
chrt --fifo $PRIO_BENCH ${BENCH} | chrt --fifo $PRIO_MONITOR ${MONITOR} "$NAME_OF_BENCH_TRACED" 

# remove useless files
rm $MONITOR_OUT_HIST

mv $MONITOR_OUT_TRACE $DATA_FOLDER/$SAMPLES_TIME

# compute statistics 
STATS=`calc_stat.sh -f "$DATA_FOLDER/$SAMPLES_TIME" -n 1 -l -t "$TIME_UNIT"`
AVG_FUN=`calc_stat.sh -f "$DATA_FOLDER/$SAMPLES_TIME" -n 1 -a -t "$TIME_UNIT"`
VAR_FUN=`calc_stat.sh -f "$DATA_FOLDER/$SAMPLES_TIME" -n 1 -v -t "$TIME_UNIT"`
# put STATS value in STATS_FILE tagged with TAG 
# STATS will have this format:
# 
# Average = %lf Var = %lf Min = %lf Max = %lf
# Where:
# -> Average = mean of values contained in SAMPLES_TIME 
# -> Variance = variance of values ...	 
# -> Max = max of values ...
# -> Min = min of values ...
echo "$TAG$STATS" >> $DATA_FOLDER/$STATS_FILE

echo -n "generating graphics..."

#generate_histogram.sh $DATA_FOLDER/$SAMPLES_TIME > hist 
#generate_percentili.sh hist $NR_SAMPLE > $DATA_FOLDER/$PERC_FILE
#rm hist
#
##image of production times of samples
#traceplotgif.sh "$DATA_FOLDER/$SAMPLES_TIME" "$PNG_FOLDER/$IMG_SAMPLES_TIME" "${TITLE}_`uname -r`" "Time (ns)" "nr_of_sample"
#
##image of cumulative distribution of production time of each sample
#traceplotgif.sh "$DATA_FOLDER/$PERC_FILE" "$PNG_FOLDER/$IMG_PERC_FILE"\
#		"fdr: (ns) Avg = $AVG_FUN Var = $VAR_FUN ${TITLE}_`uname -r`" "Percentage" "Time (ns)"

rm $DATA_FOLDER/$SAMPLES_TIME
#gzip $DATA_FOLDER/$SAMPLES_TIME
#gzip $DATA_FOLDER/$PERC_FILE

echo "done"
