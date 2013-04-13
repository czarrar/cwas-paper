#!/bin/bash

# This script will convert MNI152 output to MNI305 for freesurfer

cd /home/data/Projects/CWAS/ldopa/cwas/rois_random_k3200/ldopa_subjects+meanFD.mdmr

factor="drug"

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
