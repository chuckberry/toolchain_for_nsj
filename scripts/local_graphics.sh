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

############### don't touch

function print_header {
cat >> $1 <<EOF
=nogridy
legendx=right
legendy=center
=norotate
font=Times
EOF

}

function print_usage {

cat - <<EOF

Generate "local" graphic, namely a graphic built using data
that take in account only one kernel, in briefly this graphic
will have only one column

-h 
	help
-f
	file from which read to data to build graphic
-d 
	list of element to use in label for x axis
	for ex.: a list of buffer dimension used (2 4 8 16)
	
EOF

}

while getopts "hf:d:" optionName; do

	case "$optionName" in
		h) 
			print_usage	
			exit
			;;
		f)	#file list where I find data for graphics;
			STATS_FILE="$OPTARG" 
			;;
		d)
			ROW_LIST="$OPTARG"
			;;
		\?) 
			print_usage	
			exit
			;;
	esac
done

# Parsing STATS_FILE's header to retrive element used to build graphic.
# An header in this file is composed by thesse tags:
# <TITLE> title of graphic
# <XLAB> name of label of x axis
# <YLAB> name of lable of y axis
# <PREFIX_PLOT> prefix used to search files (used in global_graphic)
# <AVG_COL> number of column used to retrive average values (*)
# <VAR_COL> number of column used to retrive variance value (*)
#
# A STATS_FILE can contain different header, there is one graphic
# for one header, therefore from a STATS_FILE can be genearated
# different graphics
#

i=0
TITLES=`cat $STATS_FILE | grep $TITLE_TAG |  sed -e 's/^#//g' -e 's/'$TITLE_TAG'//g' `
for j in $TITLES; do
	AR_TITLE[$i]="$j"
	i=`echo "$i+1" | bc`
done

i=0
XLAB=`cat $STATS_FILE | grep $XLAB_TAG | sed -e 's/^#//g'  -e 's/'$XLAB_TAG'//g'`
for j in $XLAB; do
	AR_XLAB[$i]="$j"
	i=`echo "$i+1" | bc`
done

i=0
YLAB=`cat $STATS_FILE | grep $YLAB_TAG | sed -e 's/^#//g'  -e 's/'$YLAB_TAG'//g'`
for j in $YLAB; do
	AR_YLAB[$i]="$j"
	i=`echo "$i+1" | bc`
done

i=0
PREFIX_PLOT=`cat $STATS_FILE | grep $PREFIX_PLOT_TAG | sed -e 's/^#//g'  -e 's/'$PREFIX_PLOT_TAG'//g'`
for j in $PREFIX_PLOT; do
	AR_PREFIX_PLOT[$i]="$j"
	i=`echo "$i+1" | bc`
done

i=0
COLUMNS=`cat $STATS_FILE | grep $AVG_COL_TAG | sed -e 's/^#//g'  -e 's/'$AVG_COL_TAG'//g'`
for j in $COLUMNS; do
	AR_AVG_COLS[$i]="$j"
	i=`echo "$i+1" | bc`
done

i=0
COLUMNS=`cat $STATS_FILE | grep $VAR_COL_TAG | sed -e 's/^#//g'  -e 's/'$VAR_COL_TAG'//g'`
for j in $COLUMNS; do
	AR_VAR_COLS[$i]="$j"
	i=`echo "$i+1" | bc`
done

# number of titles, xlabs, ylabs are always equal
AR_SIZE=`cat $STATS_FILE | grep $TITLE_TAG | wc -l`


# for every header present in STATS_FILE
i=0
for i in `seq $AR_SIZE`; do 
	i=`echo "$i-1" | bc` # i start from 1

	GRAPH_FILE="${AR_PREFIX_PLOT[$i]}.plot"
	#print header for global graphics in .plot file
	echo "#$TITLE_TAG${AR_TITLE[$i]}" >> $GRAPH_FOLDER/$GRAPH_FILE 
	echo "#$XLAB_TAG${AR_XLAB[$i]}" >> $GRAPH_FOLDER/$GRAPH_FILE
	echo "#$YLAB_TAG${AR_YLAB[$i]}" >> $GRAPH_FOLDER/$GRAPH_FILE
	echo "#$PREFIX_PLOT_TAG${AR_PREFIX_PLOT[$i]}" >> $GRAPH_FOLDER/$GRAPH_FILE	

	echo "title=${AR_TITLE[$i]}" >> $GRAPH_FOLDER/$GRAPH_FILE
	echo "ylabel=${AR_YLAB[$i]}" >> $GRAPH_FOLDER/$GRAPH_FILE
	echo "xlabel=${AR_XLAB[$i]}" >> $GRAPH_FOLDER/$GRAPH_FILE

	print_header $GRAPH_FOLDER/$GRAPH_FILE
	echo "=table" >> $GRAPH_FOLDER/$GRAPH_FILE

	# Print average values
	for d in $ROW_LIST; do 
		#locally there is only one section
		echo -n "${AVG_TAG}<$d>	" >> $GRAPH_FOLDER/$GRAPH_FILE
		# make a query SQL-like
		# SELECT ${AR_AVG_COLS[$i]}
		# FROM STATS_FILE
		# WHERE tag=<$d>
		#
		# query is a PROJECTION of the column ${AR_AVG_COLS[$i]} where
		# rows are tagged with <$d>, then call calc_stat to compute
		# average of theese numbers 

		cat $STATS_FILE | grep "<$d>" | \
				awk -v "avg_col=${AR_AVG_COLS[$i]}" '{print $(avg_col)}' > temp_stat
		AVG=`calc_stat.sh -f "temp_stat" -a -n 1 `
		echo "$AVG" >> $GRAPH_FOLDER/$GRAPH_FILE
	done		
	
	echo "=yerrorbars" >> $GRAPH_FOLDER/$GRAPH_FILE
	
	# Print variance values
	for d in $ROW_LIST; do 
		echo -n "${VAR_TAG}<$d>	" >> $GRAPH_FOLDER/$GRAPH_FILE
		# make same query but with ${AR_VAR_COLS[$i]}
		cat $STATS_FILE | grep "<$d>" | \
				awk -v "var_col=${AR_VAR_COLS[$i]}" '{print $(var_col)}' > temp_stat

		# In general ${AR_AVG_COLS[$i]} and ${AR_VAR_COLS[$i]} are different
		# but when they are equal, it means that two executed query were performed
		# on the same column, in this case calc_stat must calculate variance and not 
		# average like other case
		if [ ${AR_AVG_COLS[$i]} != ${AR_VAR_COLS[$i]} ]; then
			VAR=`calc_stat.sh -f "temp_stat" -a -n 1 `
		else
			VAR=`calc_stat.sh -f "temp_stat" -v -n 1 ` #same columns compute variance
		fi
		echo "$VAR" >> $GRAPH_FOLDER/$GRAPH_FILE
	done		
done
rm temp_stat
