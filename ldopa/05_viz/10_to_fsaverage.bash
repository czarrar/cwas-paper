#!/bin/bash

# This script will convert MNI152 output to MNI305 for freesurfer

cd /home/data/Projects/CWAS/ldopa/cwas/rois_random_k3200/ldopa_subjects+meanFD.mdmr

mri_vol2vol --inv \
    --targ log_fdr_pvals_drug.nii.gz \
    --mov /usr/share/freesurfer/5.0/subjects/fsaverage/mri/orig.mgz \
    --reg /usr/share/freesurfer/5.0/average/mni152.register.dat \
    --o mni305_log_fdr_pvals_drug.nii.gz
