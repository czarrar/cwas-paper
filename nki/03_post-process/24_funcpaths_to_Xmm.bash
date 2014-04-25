#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "usage: $0 strategy resolution"
    exit 2
fi

# Read arguments
strategy="$1"
res="$2"

echo "strategy: ${strategy}"
echo "resolution: ${res}"

# Go to the belly of the beast
echo "cd /home2/data/Projects/CWAS/share/nki/subinfo"
    cd /home2/data/Projects/CWAS/share/nki/subinfo

# Scan details
scans=( "short" "medium" "long" )
scan_folder=("40_Set1_N104" "40_Set1_N104" "40_Set2_N92")

# Replace main functional list with new resampled functionals
# Loop through 3 scans
for i in $( count -digits 1 0 2); do
    scan=${scans[$i]}
    folder=${scan_folder[$i]}
    echo "  scan: ${scan}"
    
    inpath="${folder}/${scan}_${strategy}_funcpaths.txt"
    outpath="${folder}/${scan}_${strategy}_funcpaths_${res}mm.txt"
    sed s/functional_mni/functional_mni_${res}mm/g ${inpath} > ${outpath}        
done
