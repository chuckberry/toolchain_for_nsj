#!/bin/bash

function print_usage {
cat - <<EOF

$1 --> dest_dir
$2 --> directory a mettere via 

EOF
}

DEST_DIR=$1
LIST_FILES=$2

if [[ x$DEST_DIR == "x" || x$LIST_FILES == "x" ]]; then
	print_usage
	exit 1;
fi

if [ -d $DEST_DIR ]; then
	echo "cambia dir" 
	exit 1;
fi

mkdir $DEST_DIR 
mv $LIST_FILES $DEST_DIR
mv *.plot $DEST_DIR
mv *.txt $DEST_DIR
echo > .clean_dir


