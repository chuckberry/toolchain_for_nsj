#!/bin/bash

print_usage() {

cat - <<EOF

this script find all files named trace and
generate a vcd file from trace.txt 
(it's better use sched_switch tracer to generate trace.txt but
if you want to use function tracer, it's needed enable
sched_switch and sched_wakeup events) 
 
\$1 --> mailbox from where pick trace files
\$2 --> output where place vcd files  (direrctory will be created)
\$3 --> suffix to give at files (scrivi normal o taksaff se no si sovrascrivono i file)
\$4 --> file to convert

EOF

}

IN_PATH=$1
OUT_PATH=$2
SUFFIX_VCD=$3
IN_FILE=$4

if [[ $IN_PATH == "--help" || $# -lt 4 ]]; then
        print_usage
        exit
fi

if [ ! -d $IN_PATH ]; then
	echo "incorrect mailbox: $IN_PATH "
	exit
fi

if [ ! -f ${IN_PATH}/${IN_FILE} ]; then
	echo "$IN_FILE not exist"
	exit 1;
fi

mkdir -p $OUT_PATH

# trace file is now compressed
echo -n "Decompressing file ..."
gunzip "${IN_PATH}/${IN_FILE}"
echo "done"

#to do to use ctx-switch tracer
TEMP_FILE=`basename $IN_FILE .gz`
for i in $TEMP_FILE; do
	echo -n "Converting sched_switch tracer: $i files  ..." 
	#tracer is function tracer
	if [ ! -f $IN_PATH/$i ]; then
		echo "$IN_PATH/$i not exist"
		exit 1;
	fi
	trace2vcd  "$IN_PATH/$i" "$OUT_PATH/${SUFFIX_VCD}_`basename $i .txt`.vcd"
	echo "done"
done


