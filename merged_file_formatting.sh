#!/bin/bash

working_dir="/home/sean/Documentos/NewEnt_Logistics/History_Files/Formatted_History_Files/"

# main body to format the merged files ready for R analysis
for f in ${working_dir}*_Merged; do
    cut -f-5 ${f} > tmp1;
    # col6 contains address and is formatted to split the coordinates and any geozone into their own columns
    cut -f6 ${f} | \
    awk 'BEGIN {OFS="\t"; coor=""; place=""} match($0,/[0-9]{2}\.[0-9]{4},-[0-9]{1,2}\.[0-9]{4}/) {coor=substr($0,RSTART,RLENGTH)} \
    match($0,/\([a-zA-Z -]+\) /) {place=substr($0,RSTART+1,RLENGTH-3)} {split($0,a," \\([0-9]{2}\.[0-9]{4},-[0-9]{1,2}\.[0-9]{4}\\)"); 
    split(a[1],b," \\([a-zA-Z]+\\) "); print b[1],place,coor; coor=""; place=""}' > tmp2;
    # col7 contains the added file name string which contains info on truck, driver and license plate - split into 3 cols
    cut -f7 ${f} | \
    awk 'BEGIN {OFS="\t"; FS="\t"} {gsub(/[()]/, "", $0); split($0, a, "_-_");
    if(length(a)==1) {Veh=""; Driv=""; LP=$0};
    if(length(a)==2) {split(a[2], b, "_");
    	if(length(b)==1) {Veh=a[1]; Driv=""; LP=a[2]}; 
    	if(length(b)==2) {Veh=a[1]; Driv=b[1]; LP=b[2]}; 
    	if(length(b)==3) {Veh=a[1]; Driv=b[1]" "b[2]; LP=b[3]}}};
    {print Veh, Driv, LP}' > tmp3;
    # join back the parts and add label AtBase or OnTrip
    paste tmp1 tmp2 tmp3 | grep -v -E "^Time" | \
    awk 'BEGIN {FS="\t"; OFS="\t"; base="OnTrip"} {if($7=="Net Logistics Joburg" && $4==0) {base="AtBase"} 
    if($7!="Net Logistics Joburg" && $4>20) {base="OnTrip"}; print $0, base}' > tmp4;
    # now create more detailed and numbered labels for trips (i.e. LongTrip1, LongTrip2 etc)
    cut -f12 tmp4 | uniq -c | awk 'BEGIN {OFS="\t"}; 
    {if($2=="OnTrip" && $1<500 && $1>10) {mt++;for(c=0;c<$1;c++) print "MiniTrip",mt};
    if($2=="OnTrip" && $1>500) {lt++;for(c=0;c<$1;c++) print "LongTrip", lt}; 
    if($2=="AtBase") {ab++;for(c=0;c<$1;c++) print "AtBase", ab};
    if($2=="OnTrip" && $1<10) {for(c=0;c<$1;c++) print "AtBase", ab}}' > Trip_Tags; # no MiniTrips are created
    # finally add these labels to final file
    paste tmp4 Trip_Tags | cut -f-11,13- | \
    awk 'BEGIN {FS="\t"; OFS="\t"; counter=0}; 
    {if(counter==0 && $12=="LongTrip") {split($1, a, " "); split(a[1], b, "/"); Day=b[2]; Month=b[1]; counter=1; print $11"-"Month"/"Day, $0}; 
    if(counter==1 && $12=="LongTrip") {print $11"-"Month"/"Day, $0}; 
    if(counter==1 && $12=="AtBase") {print $11"-"Month"/"Day, $0; counter=0}}' |\
    uniq > ${f}.txt;	
done

# clean up tmp files
rm Trip_Tags; rm tmp*

# create the merged file with all drivers and trips together which will be main file for R scripts
cat ${working_dir}*_Merged.txt > ${working_dir}All_Merged.txt


#the output columns therefore for these files are:
#Matching Key (LP+Journey, Time/Date, Reason, Key, Speed, Mileage, Address, Named Location(s), Coordinates, Truck Details, Driver, LP 