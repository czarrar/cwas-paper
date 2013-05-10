#!/bin/bash

cd /home2/data/Projects/CWAS/share/nki/subinfo

strategies=("compcor" "global")
scans=( "short" "medium" "long" )
scan_folder=("40_Set1_N104" "40_Set1_N104" "40_Set2_N92")

for strategy in ${strategies}; do
    echo "strategy: ${strategy}"
    for i in $( count -digits 1 0 2); do
        scan=${scans[$i]}
        folder=${scan_folder[$i]}
        echo "  scan: ${scan}"
        
        inpath="${folder}/${scan}_${strategy}_funcpaths.txt"
        outpath="${folder}/${scan}_${strategy}_funcpaths_4mm.txt"
        sed s/functional_mni/functional_mni_4mm/g ${inpath} > ${outpath}        
    done
done
