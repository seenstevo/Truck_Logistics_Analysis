#!/bin/bash

# create simple file showing the entry and exit times for Net Logistics Joburg geozone
# this will be used to analyse the time spent in depot
working_dir="/home/sean/Documentos/NewEnt_Logistics/History_Files/Formatted_History_Files/"
>${working_dir}All_Time_At_Net.txt;

for f in ${working_dir}*_Merged; do 
    grep -B 2 -A 2 -E "Net Logistics Joburg" ${f} | \
    grep -v -E "^--" | \
    awk 'BEGIN {FS="\t"; OFS="\t"; base="F"} 
    {if($8!="Net Logistics Joburg" && base=="T") {startB=$2; base="F"; print endA, startB, $0} 
    if($8=="Net Logistics Joburg" && base=="F") {endA=$2; base="T"}}' >> ${working_dir}All_Time_At_Net.txt; 
done