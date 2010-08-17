#!/bin/bash
# genearate histogram 
# $1 --> data file (must be a file with one column of number
# $2 --> measure to use (ns or us)

if [ x$INIT_SOURCE == "x" ]; then
	echo "export INIT_SOURCE like environmento variable"
	exit 1;	
fi

if [ ! -f $INIT_SOURCE ]; then
	echo "run init_env.sh to select what profile do you want"
	exit 1;
fi

source $INIT_SOURCE

awk -v "time=$2" -f $PATH_SCRIPT/generate_histogram.awk "$1"

