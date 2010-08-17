#!/bin/bash
# compute number of migration of a task
# $1 --> task to which compute number of migration

if [ x$INIT_SOURCE == "x" ]; then
	echo "export INIT_SOURCE like environmento variable"
	exit 1;	
fi

if [ ! -f $INIT_SOURCE ]; then
	echo "run init_env.sh to select what profile do you want"
	exit 1;
fi
source $INIT_SOURCE

awk -v "task=$1" -f $PATH_SCRIPT/get_task_duration_migr.awk
