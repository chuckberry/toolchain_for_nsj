#!/bin/awk
#
# template file to create scripts for funcgraph tracer analysis
#
# given files: 
# -> trace file produced by fungraph trace, filtered by stat_func.sh
#    in funcgraph tracer theese options must be enabled
#    -> funcgraph-abstime 
#    -> funcgraph-duration
#    -> funcgraph-cpu
#    -> funcgraph-proc
#    
#
# given variables:
# -> fun: name of function we want to find
# -> task_list: list of task in the trace file
#
# file entries are disposed in chronological order and 
# in cpu order (0 1 2 3)
# Attention! trace file must be filtered from context switch

BEGIN {

	#put here  variables
	fun_count = 0; #count nr of ttwu for each case
	
	split(task_list,ar_task);
	for(i=0; i<length(ar_task); i++) {
		# init arrays:
		task_frequency[i]=0;
	}
	
	nr_task=length(ar_task);
	sum_task = 0;
	old_fun_count = 0;


	#used to track functions
	brack_on = 0;
	brack_count = 0;

	# used for statistics
	sum_lat = 0;
	fun_lat = 0;
	sum_all_latency = 0;	

	i=0; #idx for stack of call
	
	print "#list of exec time of function call "
}

$0 ~ "=>" {
	next
}

$1 ~ /^#/ {

	# change of cpu
	# read cpu finished
	cpu = $NF

	# sum of all frequency	
	for(j=0; j<nr_task; j++) {
		# task found
		sum_task+=task_frequency[j];
	}

	# print statistics
#	printf("#<c%s>call: %d\n",cpu,fun_count-old_fun_count);
#        for(j=0; j<nr_task; j++) {
#		if(sum_task != 0) {
#			printf("#<c%s>%s: nr: %d %: %f\n",cpu,ar_task[j+1],task_frequency[j],task_frequency[j]/sum_task*100);
#		} else {
#			printf("#<c%s>%s: nr: 0 %: 0\n",cpu,ar_task[j+1]);
#		}
#	}
	# reset statistics
        for(j=0; j<nr_task; j++) {
		task_frequency[j] = 0;
	}
	sum_task = 0;
	old_fun_count = fun_count;

	next
}	

{
	# until now I have seen that function call is made 
	# on col $7 and brackets is open at col $8	
	# anyway check trace file

	# if there is a not closed call of fun, stop to parse
	if($7 == fun && $8 == "{" && brack_on){
		sum_lat=0;
		brack_on=0;
		brack_count=0;
	}

	if($7 == fun && $8 == "{"){
		brack_count++; #use to do a check on number of brackets
		brack_on = 1;
		# push function call
		stack_call[i]=$7;
		# store funcgraph entry
		i++; #increment stack pointer
	}
	
	# if I have found functions I'm interested in
	# store nested function in stack_call 

	if($7 != fun && $8 == "{" && brack_on){
		brack_count++; #use to do a check on number of brackets
		stack_call[i]=$7;
		i++; #increment stack_pointer
	}

	# your function could appear in trace file without 
	# brackets opened, in this case function name should be
	# col. $9 because in the same row is written also latency function
	
	if($9 == fun && brack_on){
		sum_lat=0;
		brack_on=0;
		brack_count=0;
	}

	if($9 == fun){
		print  $3 " " $6;
		sum_all_latency+=$6
		fun_count++;
		
		# In which context fun is called?
		# task_frequency and ar_task travel
		# on different index
		for(j=1; j<=nr_task; j++) {
			if ($4 ~ ar_task[j]) {
				task_frequency[j-1]++;
				break;	
			}		
		}
	}
	
	# in this case your fun call a small time function,
	# you have to sum latency of this called function and
	# subtract at your fun's bracket closing
	
	if($6 != "|" && brack_on && $9 != "}"){
		sum_lat+=$6;
		#print "picked fun: " $9 " lat: " $6
	}


	# if brackets are opened (brack_on) and function end
	# pop func call from stack

	if($9 == "}" && brack_on){
		brack_count--;
		i--; # decrement stack pointer
		if (stack_call[i] != fun) {
			# measure latency of stack_call[i]
			fun_lat = $6 - sum_lat;
			sum_lat += fun_lat;
			#print "brack not closed fun: " stack_call[i] " with: " $6 " compute lat: " fun_lat " sum is: " sum_lat;
		}

		if(stack_call[i] == fun && brack_count == 0){
			latency=$6-sum_lat
			# $3 is used to filter file
			print $3 " " latency
			sum_all_latency+=latency;
			#print "fun: " stack_call[i] " with: " $6 " compute lat: " latency;
			fun_count++;
			
			# In which context fun is called?
			# task_frequency and ar_task travel
			# on different index
			for(j=1; j<=nr_task; j++) {
				if ($4 ~ ar_task[j]) {
					task_frequency[j-1]++;
					break;	
				}		
			}
			
			brack_on = 0;
			sum_lat=0;
		}	
		
		# if in stack remains function we want to track
		# brackets must be closed
		if (stack_call[i] == fun && brack_count != 0){
			sum_lat=0;
			brack_on=0;
			brack_count=0;
		}
	}
}

END {
	printf("#<EOF>call: %d\n",fun_count);
	printf("#<EOF>time: %f\n",sum_all_latency);
}
