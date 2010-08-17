#!/bin/bash

FILENAME=$1
OUTPUT_NAME=$2
TITLE=$3
YLAB=$4
XLAB=$5

gnuplot << EOF
set terminal png
set output "$OUTPUT_NAME"
set title  "$TITLE"
set ylabel "$YLAB"
set xlabel "$XLAB"
set autoscale
plot "$FILENAME" using (\$0):(\$1) title "" with points
EOF
