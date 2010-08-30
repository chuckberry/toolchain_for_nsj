#!/bin/bash

function print_usage {
cat - <<EOF
This script generate code to a new measure script
GIVE ONLY NAME WITHOUT .sh

$1 --> name of script to generate

EOF
}

SCRIPT_NAME=`basename $1 .sh`
SCRIPT_FILE="$SCRIPT_NAME.sh"

if [ x$SCRIPT_FILE == "x" ]; then
	print_usage
	exit 1;
fi


cat > $SCRIPT_FILE <<HERE
#!/bin/bash

if [ x\$INIT_SOURCE == "x" ]; then
	echo "export INIT_SOURCE like environment variable"
	exit 1;	
fi

if [ ! -f \$INIT_SOURCE ]; then
	echo "run init_env.sh to select which profile do you want"
	exit 1;
fi

source \$INIT_SOURCE

######################	don't touch here ##########################

print_usage() {

cat - <<EOF

# put here a breifly description of what script measures

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

	case "\$optionName" in
		h) 
			print_usage	
			exit
			;;
		b)
			BENCH="\$OPTARG"
			;;
		i)
			ID_BENCH="\$OPTARG"
			;;
		d)
			DIM="\$OPTARG"
			;;
		\?) 
			print_usage	
			exit
			;;
	esac
done

# Check on input parameters
if [[ x\$BENCH == "x" || x\$ID_BENCH == "x" || x\$DIM == "x" ]]; then
	print_usage
	exit
fi

# --- local variables
# theese variables are not strictly necessary, but if you decided to not use
# change instruction for reading \$GLOBAL_LIST above 

PREFIX="time_bench_\${PER_DIM_TAG}"
PREFIX_BENCH="\${PREFIX}_`uname -r`"
NAME_BENCH="\${PREFIX_BENCH}_\${ID_BENCH}"

# --- produced files

# contain statistics data
# put here STATS_FILE and QUERY_TAG 

QUERY_TAG="<something_for_tag>"

# --- write header in STATS_FILE and in list for "global" graphics
touch \$DATA_FOLDER/\$STATS_FILE

# header read from local_graphics.sh to build graphic
# put here necessary headers

# parameters for "local" graphics construction
HEADER=\`cat \$DATA_FOLDER/\$STATS_FILE | grep "\$TITLE_TAG"\`
# There could be different header in STATS_FILE but there
# must be only one copy for each header
if [ x\$HEADER == "x" ]; then


	# graphic's title
	echo "#\${TITLE_TAG}\$TITLE" >> \$DATA_FOLDER/\$STATS_FILE
	# label of x axis
	echo "#\${XLAB_TAG}\$XLAB" >> \$DATA_FOLDER/\$STATS_FILE
	# label of y axis
	echo "#\${YLAB_TAG}\$YLAB" >> \$DATA_FOLDER/\$STATS_FILE
	# prefix to use to give a name at "local" graphic
	echo "#\${PREFIX_PLOT_TAG}\${PREFIX_BENCH}" >> \$DATA_FOLDER/\$STATS_FILE
	# index of column that contains average values read by local_graphics.sh
	echo "#\${AVG_COL_TAG}\${AVG_COL}" >> \$DATA_FOLDER/\$STATS_FILE
	# index of column that contains variance values read by local_graphics.sh
	echo "#\${VAR_COL_TAG}\${VAR_COL}" >> \$DATA_FOLDER/\$STATS_FILE
fi

# read if GLOBAL_LIST has already \$PREFIX_BENCH entry
# because an entry in GLOBAL_LIST correspond to a 
# "global" graphic 
HEADER_GLOBAL_LIST=\`cat \$TA_RESULTS_PATH/\$GLOBAL_LIST | grep \$PREFIX\`
if [ x\$HEADER_GLOBAL_LIST == "x" ]; then
	echo "\$PREFIX#\$TITLE#\$XLAB#\$YLAB" >> \$TA_RESULTS_PATH/\$GLOBAL_LIST
fi

# Run benchmark and monitor to produce Average Exec. time of samples
HERE
