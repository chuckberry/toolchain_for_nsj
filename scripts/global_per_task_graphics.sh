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

############### don't touch

function print_usage {

cat - <<EOF

Join data related to tested kernels and make a "global" graphic
Consider "per_task" data

Read a string in this format:
PREFIX#TITLE#XLAB#YLAB and generate graphics according to parameters read
ex.:

	PREFIX	     #      TITLE    #  XLAB  #  YLAB
 time_bench_per_dim  # Avg ex. time  #   KB   #   Time (us)

PREFIX is used to search "local" graphic from which withdraw data
TITLE is title to give at "global" graphic 
XLAB is label for x axis
YLAB is label for y axis

Input Paramters:

-h 
	help
-e 
	String from which take parameter to build graphic
-t
	list of task run in benchmark
-d
	list of element to use in label for x axis
	for ex.: a list of buffer dimension used (2 4 8 16)
	
EOF

}

# convert SECTION_LIST in this format:
# ;section1;section2;section3.. 
function print_header {

local graph_file=$1
cluster=`echo "$SECTION_LIST" | sed -e 's/^/;/g' -e 's/ /;/g'`

cat >> $graph_file <<EOF
=nogridy
legendx=right
legendy=center
=norotate
font=Times
=cluster$cluster
xlabel=Dimension
=table
EOF
}


while getopts "he:d:t:" optionName; do

	case "$optionName" in
		h) 
			print_usage	
			exit
			;;
		e)	 # string in format .. # ... # ... # ..   
			TABLE_ENTRY="$OPTARG" 
			;;
		d)
			DIM_LIST_GRAPH="$OPTARG"
			;;
		t)
			TASK_LIST_GRAPH="$OPTARG"
			;;
		\?) 
			print_usage	
			exit
			;;
	esac
done

# Parse string with graphic parameters 
PREFIX=`echo $TABLE_ENTRY | awk -F'#' '{print $1}'`
TITLE=`echo $TABLE_ENTRY | awk -F'#' '{print $2}'`
XLAB=`echo $TABLE_ENTRY | awk -F'#' '{print $3}'`
YLAB=`echo $TABLE_ENTRY | awk -F'#' '{print $4}'`
PLOT_FILE="${PREFIX}_*"

# Join average values contained in files that are indicated by $PLOT_FILE
VALUE=""
for d in $DIM_LIST_GRAPH; do

	# GRAPH_FILE depends by $d, therefore there will be a number
   	# of graphics equal to number of elements present in DIM_LIST_GRAPH
	GRAPH_FILE="${PREFIX}_`date --rfc-3339='date'`_KB$d.plot"
	echo > $GRAPH_FILE
	echo "title=${TITLE}" >> $GRAPH_FILE
	echo "ylabel=${YLAB}" >> $GRAPH_FILE

	print_header $GRAPH_FILE

	# Join average values contained in files that are indicated by $PLOT_FILE
	# "per_task", namely consider each task and join average values 
	# related to each task
	for j in $TASK_LIST_GRAPH; do
		for i in $SECTION_LIST; do
			FOLDER=`ls -l | grep $i | awk '{print $NF}'`
			# select values tagged with <$d><j> from $PLOT_FILE
			# here PLOT_FILE contain only one file present in $FOLDER/$GRAPH_FOLDER/ 
			VALUE=${VALUE}" "`cat $FOLDER/$GRAPH_FOLDER/$PLOT_FILE | grep "${AVG_TAG}<$d><$j>" | awk '{print $2}'`
		done
		# VALUE contains a number of elements equal to number of element 
		# contained in SECTION_LIST 
		echo "${XLAB}$j ${VALUE}" >> $GRAPH_FILE
		VALUE=""
	done
	
	# Same thing but with variance values
	echo "=yerrorbars" >> $GRAPH_FILE
	for j in $TASK_LIST_GRAPH; do
		for i in $SECTION_LIST; do
			FOLDER=`ls -l | grep $i | awk '{print $NF}'`
			VALUE=${VALUE}" "`cat $FOLDER/$GRAPH_FOLDER/$PLOT_FILE | grep "${VAR_TAG}<$d><$j>" | awk '{print $2}'`
		done
		echo "${XLAB}$j ${VALUE}" >> $GRAPH_FILE
		VALUE=""
	done
done


