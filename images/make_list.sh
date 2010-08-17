#!/bin/bash

source ../init.env

function print_usage {

cat - <<EOF
update list of kernel to test

EOF

}


# sed used to translate vmlinuz in uname format
ls -l vmlinuz-* | awk '{print $NF}' | sed -e 's/vmlinuz-//g' |\
	  awk '	BEGIN {
			i = 0; #array index
		}
	
		{
			#EOF reached
			# $1 has kernel image in unmae -r format
			if (i > 0){
				new[i-1] = $1
			}
		
			prev[i] = $1
			i++

			#close loop, file finished
			if (i >= NR-1) 
				new[i-1] = prev[0]
		}
		
		END {
			for(i = 0; i < NR; i++){
				print "<" prev[i] ">"	" -> " "vmlinuz-" new[i]
			}
			
		}' > $TA_IMAGES_LIST
#TODO anche lui deve vedere init.env	


