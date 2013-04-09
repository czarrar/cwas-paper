#!/bin/bash

# This script will convert MNI152 output to MNI305 for freesurfer

sdists="cwas cwas_regress_motion"

for sdist in ${sdists}; do
    echo "sdist: ${sdist}"
    sdir="/home2/data/Projects/CWAS/development+motion/${sdist}/rois_random_k3200"
    
    ## age and motion
    echo "...age and motion"
    mdir="${sdir}/age+motion_sex+tr.mdmr"
    cd $mdir
    # age
    rm -f mni305_log_fdr_pvals_age.nii.gz
    mri_vol2vol --inv \
        --targ log_fdr_pvals_age.nii.gz \
        --mov $FREESURFER_HOME/subjects/fsaverage/mri/orig.mgz \
        --reg $FREESURFER_HOME/average/mni152.register.dat \
        --o mni305_log_fdr_pvals_age.nii.gz
    # motion
    rm -f mni305_log_fdr_pvals_mean_FD.nii.gz
    mri_vol2vol --inv \
        --targ log_fdr_pvals_mean_FD.nii.gz \
        --mov $FREESURFER_HOME/subjects/fsaverage/mri/orig.mgz \
        --reg $FREESURFER_HOME/average/mni152.register.dat \
        --o mni305_log_fdr_pvals_mean_FD.nii.gz
    
    ## just age
    echo "...age"
    mdir="${sdir}/age_sex+tr.mdmr"
    cd $mdir
    # age
    rm -f mni305_log_fdr_pvals_age.nii.gz
    mri_vol2vol --inv \
        --targ log_fdr_pvals_age.nii.gz \
        --mov $FREESURFER_HOME/subjects/fsaverage/mri/orig.mgz \
        --reg $FREESURFER_HOME/average/mni152.register.dat \
        --o mni305_log_fdr_pvals_age.nii.gz
done

