#!/bin/bash

#let var="$1 - 1"
var=$(($1 - 1))
for i in $(seq 0 1 $var)
do
   printf "read sema_semaphore_raw_entry[$i]" | capview
done
