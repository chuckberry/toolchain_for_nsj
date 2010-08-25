#!/bin/bash

function print_usage {
cat - <<EOF

From a png file find corresponding sample in vcd file
data file must have first column with latency
and second column with timestamps

$1 --> lower bound of nr_sample (put def for default value) 
$2 --> upper bound of nr_sample (put def as above)
$3 --> lower bound of latency
$4 --> upper bound of latency
$5 --> data file
$6 --> trace file compressed
$7 --> vcd folder
$8 --> suffix for vcd file

EOF
}

LOW_SAM="$1"
UP_SAM="$2"
LOW_LAT="$3"
UP_LAT="$4"
DATA_FILE="$5"
TRACE_FILE_COMPRESSED="$6"
VCD_FOLDER="$7"
SUFFIX_FILE="$8"

if [ $# -lt 8 ]; then
	print_usage
	exit 1;
fi

if [ $LOW_SAM == "def" ]; then
	echo "default lower bound 1"
	LOW_SAM=1
fi

if [ $UP_SAM == "def" ]; then
	echo "default upper bound length of file"
	UP_SAM=`cat $DATA_FILE | grep -v "#" | wc -l`
fi

if [ x$LOW_LAT == "x" ]; then
	echo "lower bound miss"
	print_usage
	exit 1;
fi

if [ x$UP_LAT == "x" ]; then
	echo "upper bound miss"
	print_usage
	exit 1;
fi

# you must be where there are data files
echo "******* Start to generate vcd file *********"

if [ ! -d $VCD_FOLDER ]; then
	if [ ! -f $TRACE_FILE_COMPRESSED ]; then
		echo "trace compressed file not exist"
		exit 1;	
	fi

	convert_trace.sh . $VCD_FOLDER $SUFFIX_FILE $TRACE_FILE_COMPRESSED
	echo ""
	echo "this command to copy vcd files:"
	echo "scp matteom@lnxast103:`pwd`/$VCD_FOLDER/* ."
else 
	echo "vcd already generated"
fi

echo "******* Find sample *********"
# now there is vcd file and uncompressed trace file
# enter where there are trace file
TRACE_FILE=`basename $TRACE_FILE_COMPRESSED .gz`
if [ ! -f $TRACE_FILE ]; then
	echo "trace file not exists"
	exit 1;
fi

find_sample.sh $LOW_SAM $UP_SAM $LOW_LAT $UP_LAT $DATA_FILE $TRACE_FILE 

# now see vcd file


