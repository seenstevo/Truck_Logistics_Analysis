#!/bin/bash

# first part takes the xlsx files from the MARCH folder, finds the files in the OCT-FEB and APRIL folders 
# for the same driver and then sorts and merges them removing any duplicated rows
# key step here is adding the file name string as new column

working_dir="/home/sean/Documentos/NewEnt_Logistics/History_Files"

# make output folder if needed
if [ ! -d ${working_dir}"/Formatted_History_Files" ]; 
    then mkdir ${working_dir}/Formatted_History_Files; 
fi

# format file names to make sure no spaces and formatting is consistent
for f in ${working_dir}/Raw_xlsx_History_Files/*/*\ *; do 
    mv "$f" "${f// /_}" 2>/dev/null;
done
for x in {1..10}; do
    for f in ${working_dir}/Raw_xlsx_History_Files/*/*_\(${x}\)*; do 
    mv "$f" "${f//_\(${x}\)/}" 2>/dev/null; 
    done;
done

# now loop through the files with formatted names to merge from different history files for same driver/truck
for fmarch in ${working_dir}/Raw_xlsx_History_Files/MARCH/*xlsx; do
    Name=$(basename ${fmarch} .xlsx | sed 's/.*History_//g');
    foct=$(find ${working_dir}/Raw_xlsx_History_Files/OCT-FEB/ -name "*"${Name}"*");
    fapril=$(find ${working_dir}/Raw_xlsx_History_Files/APRIL/ -name "*"${Name}"*");
    xlsx2csv ${fmarch} | sed $'s/[^[:print:]\t]//g' | grep -E "rmed / Tracking" | \
    awk -vOFS="\t" -vFPAT='([^,]*)|("[^"]+")' -vName=${Name} '{print $1,$2,$3,$4,$5,$6,Name}' | \
    sed 's/History_//g' | sed 's/\.xlsx//g' | sed 's/"//g' > ${Name}_MARCH;
    xlsx2csv ${foct} | sed $'s/[^[:print:]\t]//g' | grep -E "rmed / Tracking" | \
    awk -vOFS="\t" -vFPAT='([^,]*)|("[^"]+")' -vName=${Name} '{print $1,$2,$3,$4,$5,$6,Name}' | \
    sed 's/History_//g' | sed 's/\.xlsx//g' | sed 's/"//g' > ${Name}_OCTFEB;
    xlsx2csv ${fapril} | sed $'s/[^[:print:]\t]//g' | grep -E "rmed / Tracking" | \
    awk -vOFS="\t" -vFPAT='([^,]*)|("[^"]+")' -vName=${Name} '{print $1,$2,$3,$4,$5,$6,Name}' | \
    sed 's/History_//g' | sed 's/\.xlsx//g' | sed 's/"//g' > ${Name}_APRIL;
    cat ${Name}_OCTFEB ${Name}_MARCH ${Name}_APRIL| awk 'BEGIN {OFS="\t"} {print $0, NR}' | \
    sort -u -t$'\t' -k1,1 | sort -t$'\t' -k8,8n | cut -f-7 > ${working_dir}/Formatted_History_Files/${Name}_Merged;
    rm ${Name}_MARCH; rm ${Name}_OCTFEB; rm ${Name}_APRIL;
done