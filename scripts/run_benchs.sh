#!/bin/bash

source $INIT_SOURCE

$1 | $2 "$NAME_OF_BENCH_TRACED" 
