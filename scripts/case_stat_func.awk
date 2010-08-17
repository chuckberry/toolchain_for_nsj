#!/bin/awk
#
# func_case_stat.awk counts occurrence of different cases and nr of
# call of fun that match each case 
#
# given files: 
# -> trace file produced by fungraph trace, filtered by func_analyse.sh
#    in funcgraph tracer theese options must be enabled
#    -> funcgraph-abstime 
#    -> funcgraph-duration
#    -> funcgraph-cpu
#    -> funcgraph-proc
#
# given variables:
# -> fun: name of function we want to find


BEGIN {

	#put here  variables
	enable_stat=0
	percent=0; #percent of i-th case
	case_count=0; #counts occurrence of each case
	fun_count = 0; #count nr of call of fun for each case
	sum_lat_fun=0; #sum of latency of call of fun for each case
	sum_sqr_lat_fun=0; #sum of sqr of fun for each case
	avg=0;
	var=0;
	
	#used to track functions
	brack_on = 0;
	brack_count = 0;
	
	#idx for stack of calls
	i=0; 
	
	#used for debug
	ts = 0;
	alert = 0;
}

$1 ~ /^#/ {
	next
}	

{
	# check for errors
	if (alert)
		exit;

	# if brackets are opened check for
	# different cases
	if(brack_on == 1){
	
		# this column values can change
		# attention here!!
		if($9 == name_case){
			case_count++;
			enable_stat=1;
		}
		
	}

	# until now I have seen that function call is made 
	# on col $7 and brackets is open at col $8	
	# anyway check trace file

	if($7 == fun && $8 == "{"){
		#used to do a check on number of brackets;
		brack_count++; 
		brack_on = 1;
		#push function call
		stack_call=$7;
		i++; #increment stack pointer
	}
	
	# if I have found functions I'm interested in,
	# I store nested function in stack_call 
	if($7 != fun && $8 == "{" && brack_on){
		brack_count++; 
		stack_call=$7;
		i++; 
	}

	# your function could appear in trace file without 
	# brackets opened, in this case function name should be
	# col. $9 because in the same row is written also latency function
	

	# if brackets are opened (brack_on) and function end
	# pop func call from stack

	if($9 == "}" && brack_on){
		brack_count--;
		i--; 

		if(stack_call == fun && brack_count == 0 && enable_stat == 1){
			
			fun_count++;
			sum_lat_fun+=$6;
			sum_sqr_lat_fun+=$6*$6;
			enable_stat=0;

			#latency of fun
			idx_ar = -1; #reset idx_ar
			case = 0;
			
			brack_on = 0;
		}	
		
		# if in stack remains function we want to track
		# brackets must be closed
		if (stack_call == fun && brack_count != 0){
			print "brackets for fun are not closed: " $1
			alert = 1;
		}
	}
}

END {
	if (alert == 1)
		exit

	#sum of all case occurrences
	
	if(fun_count != 0 && (fun_count - 1) != 0){
		avg=sum_lat_fun/fun_count;
		var=((fun_count)/(fun_count-1))*(sum_sqr_lat_fun/fun_count - avg*avg);
	}
	printf("#Case%s:Average = %f Var = %f occurrence = %f\n",name_case,avg,var,case_count/sum_case*100);
}

