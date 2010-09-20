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

print_usage() {

cat - <<EOF

Calculate average variance and other statistics

Given a file with numbers filled in columns, 
calculate variance, average, max e min of theese numbers 
and print results in this format
Average = %lf Var = %lf Min = %lf Max = %lf


Input Parameters:

-h 
	help
-l 
	return all statistics in this format
	Average = %lf Var = %lf Min = %lf Max = %lf
-a 
	return only average
-v 
	return only variance
-u
	return only uncertainty
-M 
	return only max
-m 
	return only min
-f 
	file with data
-n
	number of column of data file
	to consider for compute statistics
-t 	
	time unit (us or ns)

EOF

}

while getopts "hlavuMmf:n:t:" optionName; do

	case "$optionName" in
		h) 
			print_usage	
			exit
			;;
		l)
			PRINT_COL="all"
			;;
		a)
			PRINT_COL="avg"
			;;
		v)
			PRINT_COL="var"
			;;
		u)
			PRINT_COL="unc"
			;;
		M)
			PRINT_COL="min"
			;;
		m)
			PRINT_COL="max"
			;;
		f)
			FILE_NAME="$OPTARG"
			;;
		n)
			NR_COL="$OPTARG"
			;;
		t)
			TIME_UNIT="$OPTARG"
			;;
		\?) 
			print_usage	
			exit
			;;
	esac
done

if [ $# -lt 1 ]; then
	print_usage
	exit
fi

# calc_stat.awk will pick data from column nr_col
# of the data file
awk -v "nr_col=$NR_COL" -v "print_col=$PRINT_COL" -v "time=$TIME_UNIT" -f $PATH_SCRIPT/calc_stat.awk $FILE_NAME 




