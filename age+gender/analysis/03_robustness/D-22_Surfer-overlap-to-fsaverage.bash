#!/bin/bash

basedir="/home2/data/Projects/CWAS/age+gender/03_robustness"

# DISCOVERY
discovery_sdir="${basedir}/cwas/discovery_rois_random_k3200"
discovery_mdir="${discovery_sdir}/age+gender_15k.mdmr"

# REPLICATION
replication_sdir="${basedir}/cwas/replication_rois_random_k3200"
replication_mdir="${replication_sdir}/age+gender_15k.mdmr"

# OVERLAP
overlap_dir="${basedir}/cwas/overlap"
mkdir ${overlap_dir} 2> /dev/null
cd $overlap_dir

## Age
echo "Age"
3dcalc -a ${discovery_mdir}/fdr_logp_age.nii.gz \
       -b ${replication_mdir}/fdr_logp_age.nii.gz \
       -expr 'step(a-2) + 2*step(b-2)' \
       -prefix ${overlap_dir}/fdr_logp_age_thr2.nii.gz
mri_vol2surf \
    --mov fdr_logp_age_thr2.nii.gz \
    --mni152reg \
    --projfrac 0.5 \
    --interp trilinear \
    --hemi lh \
    --out surf_lh_fdr_logp_age_thr2.nii.gz \
    --reshape
mri_vol2surf \
    --mov fdr_logp_age_thr2.nii.gz \
    --mni152reg \
    --projfrac 0.5 \
    --interp trilinear \
    --hemi rh \
    --out surf_rh_fdr_logp_age_thr2.nii.gz \
    --reshape

## Sex
echo "Sex"
3dcalc -a ${discovery_mdir}/fdr_logp_sex.nii.gz \
       -b ${replication_mdir}/fdr_logp_sex.nii.gz \
       -expr 'step(a-2) + 2*step(b-2)' \
       -prefix ${overlap_dir}/fdr_logp_sex_thr2.nii.gz
mri_vol2surf \
    --mov fdr_logp_sex_thr2.nii.gz \
    --mni152reg \
    --projfrac 0.5 \
    --interp trilinear \
    --hemi lh \
    --out surf_lh_fdr_logp_sex_thr2.nii.gz \
    --reshape
mri_vol2surf \
    --mov fdr_logp_sex_thr2.nii.gz \
    --mni152reg \
    --projfrac 0.5 \
    --interp trilinear \
    --hemi rh \
    --out surf_rh_fdr_logp_sex_thr2.nii.gz \
    --reshape

