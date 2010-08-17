#!/bin/awk
#
# template file to create scripts for funcgraph tracer analysis
#
# given files: 
# -> trace file produced by fungraph trace, filtered by func_analyse.sh
#    in funcgraph tracer theese options must be enabled
#    -> funcgraph-abstime 
#    -> funcgraph-duration
#    -> funcgraph-cpu
#    -> funcgraph-proc
#    
#
# given variables:
# -> fun: name of function we want to find
# -> 


BEGIN {

	#put here  variables
	
	#used to track functions
	brack_on = 0;
	brack_count = 0;

	i=0; #idx for stack of call
	
	#used for debug
	ts = 0;
	alert = 0;
}

$1 ~ /^#/ {
	next
}	

{
	if (alert)
		exit;


	# until now I have seen that function call is made 
	# on col $7 and brackets is open at col $8	
	# anyway check trace file

	if($7 == fun && $8 == "{"){
		brack_count++; #use to do a check on number of brackets
		brack_on = 1;
		#push function call
		stack_call[i]=$7;
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
	
	# attention! your function could be appear nested or not 
	# in trace file, you have to decide what to do in both
	# case
	
	if($9 == fun && brack_on){

	}

	
	if($9 == fun){

	}


	# if brackets are opened (brack_on) and function end
	# pop func call from stack

	if($9 == "}" && brack_on){
		brack_count--;
		i--; # decrement stack pointer

		if(stack_call[i] == fun && brack_count == 0){
			# make calculation you have to do
			brack_on = 0;
		}	
		
		# if in stack remains function we want to track
		# brackets must be closed
		if (stack_call[i] == fun && brack_count != 0){
			print "brackets for fun are not closed: " $1
			alert = 1;
		}
	}
}

END {
	if (alert == 1)
		exit

	# print what do you have to print
	
	
#	printf("# Data for graph: \n");
#	printf("title=Occurrence of various case \n");
#	printf("ylabel=Occurrence [%]\n");
#	printf("=norotate\n");
#	printf("font=Times\n");
#	printf("#\n");	
#	printf("#cases \t percent\n");

#	printf("title=\n");
#	printf("ylabel=n");
#	printf("=nogridy\n");
#	printf("legendx=right\n");
#	printf("legendy=center\n");
#	printf("=norotate\n");
#	printf("font=Times\n");
#	printf("xlabel=Case\n");
#	printf("=table\n");
}

