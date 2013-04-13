#!/bin/bash

# This script will convert MNI152 output to MNI305 for freesurfer


sdir="/home2/data/Projects/CWAS/adhd200/cwas/rois_random_k3200"
factor="group"
comparisons="adhdc_vs_adhdi tdc_vs_adhdc tdc_vs_adhdi"

for comparison in ${comparisons}; do
    echo "${comparison}"
    
    mdir="${sdir}/${comparison}_gender+age+iq+meanFD.mdmr"
    cd $mdir
    
    mri_vol2surf \
        --mov clust_logp_${factor}.nii.gz \
        --mni152reg \
        --projfrac 0.5 \
        --interp trilinear \
        --hemi lh \
        --out surf_lh_clust_logp_${factor}.nii.gz \
        --reshape
    mri_vol2surf \
        --mov clust_logp_${factor}.nii.gz \
        --mni152reg \
        --projfrac 0.5 \
        --interp trilinear \
        --hemi rh \
        --out surf_rh_clust_logp_${factor}.nii.gz \
        --reshape    
done
