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
$6 --> trace file

EOF
}

LOW_SAM="$1"
UP_SAM="$2"
LOW_LAT="$3"
UP_LAT="$4"
DATA_FILE="$5"
TRACE_FILE="$6"

if [ $# -lt 6 ]; then
	print_usage
	exit 1;
fi

if [ x$DATA_FILE == "x" ]; then
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

TS=`awk -v "low_sam=$LOW_SAM" -v "up_sam=$UP_SAM" -v "low_lat=$LOW_LAT" -v "up_lat=$UP_LAT" '

	NR < low_sam {
		next;
	}
	
	NR > up_sam {
		next;
	}

	NR > low_sam && NR < up_sam {
		if ($1 > low_lat && $1 < up_lat) {
			print  $1 " " $2	
		}
	}
' $DATA_FILE | awk '{print $2}'` 

for i in $TS; do
	ts2gtkw.sh $TRACE_FILE $i
done






