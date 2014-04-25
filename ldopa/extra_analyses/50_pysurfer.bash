#!/usr/bin/env bash

base="/home2/data/Projects/stan_bike"
strategy="compcor"

# Inputs
subdir="${base}/subinfo"
cwasdir="${base}/cwas"
sdistdir="${cwasdir}/${strategy}_voxs_res4_sm6"
mdmrdirnames="lmin_age+sex+meanFD.mdmr age_lmin+sex+meanFD.mdmr ageXlmin_lmin+age+sex+meanFD.mdmr vO2_weight+age+sex+meanFD.mdmr weight_vo2+age+sex+meanFD.mdmr"

###
# Convert volume to surface
###

## Loop through and do the conversion
#for mdmrdirname in ${mdmrdirnames}; do
#    name=$( echo $mdmrdirname | sed s/_.*mdmr// )
#    
#    echo ${name}
#    
#    mdmrdir="${sdistdir}/${mdmrdirname}"
#    easydir="${mdmrdir}/cluster_correct_v05_c05/easythresh"
#    
#    ./x_vol2surf.py ${easydir} 
#done




###
# Render data
###

outdir="/home2/data/Projects/stan_bike/results/cwas"

for mdmrdirname in ${mdmrdirnames}; do
    name=$( echo $mdmrdirname | sed s/_.*mdmr// )
    
    echo ${name}
    
    mdmrdir="${sdistdir}/${mdmrdirname}"
    easydir="${mdmrdir}/cluster_correct_v05_c05/easythresh"
    
    ./x_pysurfer.py --name ${name} \
        --rh ${easydir}/surf_${name}_lh.nii.gz \
        --lh ${easydir}/surf_${name}_rh.nii.gz \
        --color /home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt \
        --outdir ${outdir}
done



