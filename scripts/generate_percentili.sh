#!/bin/bash
# Take in input the file generated by generate_histogram 
# and generate cucmulative distribution
# $1 --> data file (must be a file with one column of number
# $2 -> nr of samples

if [ x$INIT_SOURCE == "x" ]; then
	echo "export INIT_SOURCE like environmento variable"
	exit 1;	
fi

if [ ! -f $INIT_SOURCE ]; then
	echo "run init_env.sh to select what profile do you want"
	exit 1;
fi

source $INIT_SOURCE


##################   don't touch here  #####################

awk -v "nr_sample=$2" -f $PATH_SCRIPT/generate_percentili.awk "$1"
