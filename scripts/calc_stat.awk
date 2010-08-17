#!/bin/awk

# touch order of output parameters of printf at your own risk


BEGIN{
	var = 0;
	avg = 0;
	min = 0;
	max = 0;
	sum = 0;
	sum2 = 0;
	nr_sample = 0;
	first_iter = 1;
	if (time == "us") {
		# this is used to reduce
		# ns in us
		factor=1e3;
	} else {
		factor=1;
	}	
}

$1 !~ /^#/ {

	nr_sample++;
	sum += $(nr_col)/factor;
	sum2 += $(nr_col)/factor*$(nr_col)/factor;

	if (first_iter || $(nr_col)/factor > max){	
		max=$(nr_col)/factor;	
	}
	
	if (first_iter || $(nr_col)/factor < min){
		min=$(nr_col)/factor;
	}

	if (first_iter)
		first_iter=0;	
}

END{
	if (nr_sample > 0)
		avg = (sum/nr_sample);
	if (nr_sample > 1)
		var = (nr_sample/(nr_sample-1))*((sum2/nr_sample) - avg*avg); 

	if (print_col == "all") {
		printf("Avg = %lf Var = %lf Min = %lf Max = %lf\n",avg,var,min,max);
	}
 
	if (print_col == "avg") {
		print avg
	}

	if (print_col == "var") {
		print var
	}

	if (print_col == "min") {
		print min
	}

	if (print_col == "max") {
		print max
	}
} 

# calcolo della media
# cat temp | (sed -e 's/^/x+=/'; NR=`cat temp | wc -l`; echo x; echo "scale=3; x/$NR") | bc

