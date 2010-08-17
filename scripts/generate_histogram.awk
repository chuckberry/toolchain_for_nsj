#!/bin/awk

#TODO controlla sto cazzo di factor se va molitplicato

BEGIN {
	samples[0]=0
	max=0
	if (time == "us"){
		factor=1e3
	}else{
		factor=1
	}
		
}

$1 ~ /^#/ {
	print $0
	next
}

{
	if(!($1*factor in samples)) {
		samples[$1*factor] = 1
		if($1*factor > max)
			max=$1*factor
	}
	else {
		samples[$1*factor]++
	}
}


END {
	for (i=0; i<=max; i++) {
		if(i in samples)
			print i " " samples[i]
		else
			print i " 0" 
	}
}
