#!/bin/bash

BEGIN{
	sum = 0;
	print "# generate_percentili"
}

$1 ~ /^#/ {
	print $0
	next
}

{ 
	sum+=$2;
	print sum/nr_sample*100 "%: " $1 
}
