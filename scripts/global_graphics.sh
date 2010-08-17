#!/bin/bash

if [ x$INIT_SOURCE == "x" ]; then
	echo "export INIT_SOURCE like environmento variable"
	exit 1;	
fi

if [ ! -f $INIT_SOURCE ]; then
	echo "run init_env.sh to select what profile do you want"
	exit 1;
fi
source $INIT_SOURCE

############### don't touch following lines

function print_usage {

cat - <<EOF

Join data related to tested kernel and make a "global" graphic

Read a string in this format:
PREFIX#TITLE#XLAB#YLAB and generate graphics according to parameters read
ex.:

	PREFIX	     #      TITLE    #  XLAB  #  YLAB
 time_bench_per_dim  # Avg ex. time  #   KB   #   Time (us)

PREFIX is used to search "local" graphic from which retrieve data
TITLE is title to give at "global" graphic 
XLAB is label for x axis
YLAB is label for y axis

Input Paramters:

-h 
	help
-e 
	String from which take parameter to build graphic
-d
	list of element to use in label for x axis
	for ex.: a list of buffer dimension used (2 4 8 16)
	
EOF

}

function print_header {

local graph_file=$1

# convert SECTION_LIST in this format:
# ;section1;section2;section3.. 
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


while getopts "he:d:" optionName; do

	case "$optionName" in
		h) 
			print_usage	
			exit
			;;
		e)	# string in format .. # ... # ... # ..
			TABLE_ENTRY="$OPTARG" 
			;;
		d)
			ROW_LIST="$OPTARG"
			;;
		\?) 
			print_usage	
			exit
			;;
	esac
done
	
# Parse string with graphics parameters
PREFIX=`echo $TABLE_ENTRY | awk -F'#' '{print $1}'`
TITLE=`echo $TABLE_ENTRY | awk -F'#' '{print $2}'`
XLAB=`echo $TABLE_ENTRY | awk -F'#' '{print $3}'`
YLAB=`echo $TABLE_ENTRY | awk -F'#' '{print $4}'`
PLOT_FILE="${PREFIX}_*"

# output file
GRAPH_FILE="${PREFIX}_`date --rfc-3339='date'`.plot"

echo > $GRAPH_FILE
echo "title=$TITLE" >> $GRAPH_FILE
echo "ylabel=$YLAB" >> $GRAPH_FILE

print_header $GRAPH_FILE

# Join average values contained in files that are indicated by $PLOT_FILE
VALUE=""
for d in $ROW_LIST; do 
	for i in $SECTION_LIST; do
		FOLDER=`ls -l | grep $i | awk '{print $NF}'`
		# select values tagged wit <$d> from $PLOT_FILE
		# here PLOT_FILE contain only one file present in $FOLDER/$GRAPH_FOLDER/ 
		VALUE=${VALUE}" "`cat $FOLDER/$GRAPH_FOLDER/$PLOT_FILE |  grep "${AVG_TAG}<$d>" | awk '{print $2}'`
	done
	# VALUE contains a number of elements equal to number of element 
	# contained in SECTION_LIST 
	echo "${XLAB}$d ${VALUE}" >> $GRAPH_FILE
	VALUE=""
done		
echo "=yerrorbars" >> $GRAPH_FILE

# Same thing but with variance values
for d in $ROW_LIST; do 
	for i in $SECTION_LIST; do
		FOLDER=`ls -l | grep $i | awk '{print $NF}'`
		VALUE=${VALUE}" "`cat $FOLDER/$GRAPH_FOLDER/$PLOT_FILE |  grep "${VAR_TAG}<$d>" | awk '{print $2}'`
	done
	echo "${XLAB}$d ${VALUE}" >> $GRAPH_FILE
	VALUE=""
done		

