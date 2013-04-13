#!/bin/bash

# This script will convert MNI152 output to MNI305 for freesurfer

sdists="cwas"
# sdists="cwas cwas_regress_motion" # not doing cwas_regression_motion anymore

for sdist in ${sdists}; do
    echo "sdist: ${sdist}"
    sdir="/home2/data/Projects/CWAS/development+motion/${sdist}/rois_random_k3200"
    
    ## age and motion
    echo "...age and motion"
    mdir="${sdir}/age+motion_sex+tr.mdmr"
    cd $mdir
    # age
    factor="age"
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
    # motion
    factor="mean_FD"
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
    
    ## just age
    echo "...age"
    mdir="${sdir}/age_sex+tr.mdmr"
    cd $mdir
    # age
    factor="age"
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

