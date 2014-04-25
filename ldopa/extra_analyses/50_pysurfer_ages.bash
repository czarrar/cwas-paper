#!/usr/bin/env bash

if [[ "$#" -ne 1 ]]; then
    echo "$0 age"
    exit 2
fi

age=$1



base="/home2/data/Projects/stan_bike"
strategy="compcor"

# Inputs
subdir="${base}/subinfo"
cwasdir="${base}/cwas"
sdistdir="${cwasdir}/${strategy}_voxs_res4_sm6"
mdmrdirnames="lmin_age+sex+meanFD_ages${age}.mdmr age_lmin+sex+meanFD_ages${age}.mdmr ageXlmin_lmin+age+sex+meanFD_ages${age}.mdmr vO2_weight+age+sex+meanFD_ages${age}.mdmr weight_vo2+age+sex+meanFD_ages${age}.mdmr"

###
# Convert volume to surface
###

# Loop through and do the conversion
for mdmrdirname in ${mdmrdirnames}; do
    name=$( echo $mdmrdirname | sed s/_.*mdmr// )
    
    echo ${name}
    
    mdmrdir="${sdistdir}/${mdmrdirname}"
    easydir="${mdmrdir}/cluster_correct_v05_c05/easythresh"
    
    ./x_vol2surf.py $(ls ${easydir}/zstat_*.nii.gz) $(ls ${easydir}/thresh_zstat_*.nii.gz) ${easydir}/surf_${name}
done




###
# Render data
###

outdir="/home2/data/Projects/stan_bike/results/cwas"

for mdmrdirname in ${mdmrdirnames}; do
    name=$( echo $mdmrdirname | sed s/_.*mdmr// )
    
    echo ${name}
    
    mdmrdir="${sdistdir}/${mdmrdirname}"
    easydir="${mdmrdir}/cluster_correct_v05_c05/easythresh"
    
    if [[ (! -e "${easydir}/surf_${name}_lh.nii.gz") && (! -e "${easydir}/surf_${name}_rh.nii.gz")  ]]; then
        echo "Surfaces don't exist, skipping"
        continue
    fi
    
    ./x_pysurfer.py --name ages${age}_${name} \
        --rh ${easydir}/surf_${name}_lh.nii.gz \
        --lh ${easydir}/surf_${name}_rh.nii.gz \
        --color /home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt \
        --min 1.64 --max 3.8 \
        --outdir ${outdir}
done



