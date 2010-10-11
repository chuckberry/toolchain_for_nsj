#!/bin/bash

function print_usage {
cat - <<EOF

From a png file find corresponding sample in vcd file
data file must have first column with latency
and second column with timestamps
you must be where there are data files !! (folder data)

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
DATA_FILE_COMPRESSED="$5"
TRACE_FILE_COMPRESSED="$6"
VCD_FOLDER="$7"
SUFFIX_FILE="$8"

if [ $# -lt 8 ]; then
	print_usage
	exit 1;
fi

DATA_FILE=`basename $DATA_FILE_COMPRESSED .gz`
if [[ ! -f $DATA_FILE_COMPRESSED && ! -f $DATA_FILE ]]; then
	echo "data file not exists"
	exit 1;
fi

if [ $LOW_SAM == "def" ]; then
	echo "default lower bound 1"
	LOW_SAM=1
fi

if [ $UP_SAM == "def" ]; then
	echo "default upper bound length of file"
	UP_SAM=`zcat $DATA_FILE_COMPRESSED | grep -v "#" | wc -l`
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

echo "Decompressing data file ..."
if [ -f $DATA_FILE_COMPRESSED ]; then
	gunzip $DATA_FILE_COMPRESSED
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

echo "ts are: "
echo "$TS"
echo "---------"

for i in $TS; do
	ts2gtkw.sh $TRACE_FILE $i
done
# now see vcd file


