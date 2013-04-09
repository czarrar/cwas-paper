#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS/age+gender/03_robustness"
factors="age sex"
samples="discovery replication"


for sample in ${samples}; do

    echo "SAMPLE: ${sample}"

    sdir="${basedir}/cwas/${sample}_rois_random_k3200"
    mdir="${sdir}/age+gender_15k.mdmr"
    cd $mdir

    for factor in ${factors}; do

        echo "...factor: ${factor}"
        mri_vol2surf \
            --mov fdr_logp_${factor}.nii.gz \
            --mni152reg \
            --projfrac 0.5 \
            --interp trilinear \
            --hemi lh \
            --out surf_lh_fdr_logp_${factor}.nii.gz \
            --reshape
        mri_vol2surf \
            --mov fdr_logp_${factor}.nii.gz \
            --mni152reg \
            --projfrac 0.5 \
            --interp trilinear \
            --hemi rh \
            --out surf_rh_fdr_logp_${factor}.nii.gz \
            --reshape

    done

done
