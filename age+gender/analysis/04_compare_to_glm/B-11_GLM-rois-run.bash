#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/age+gender/analysis/04_compare_to_glm"
outdir="${basedir}/age+gender/04_compare_to_glm/glm"
mkdir -p $outdir 2> /dev/null

#ks="0025 0050 0100 0200 0400 0800 1600 3200"
#ks="1600"
ks="3200"


###
# Discovery Sample
###

#for k in ${ks}; do
#    echo "K of ${k}"
#    
#    connectir_glm.R \
#        --infuncs1 ${indir}/roisinfo/discovery_rois_random_k${k}_nifti.txt \
#        --regressors ${indir}/subinfo/04_discovery_regressors.txt \
#        --contrasts ${indir}/subinfo/04_discovery_contrasts.txt \
#        --infuncs2 ${indir}/subinfo/04_discovery_funcpaths_4mm.txt \
#        --ztransform \
#        --brainmask2 ${indir}/rois/mask_for_age+sex_gray_4mm.nii.gz \
#        --forks 1 --threads 12 \
#        --memlimit 24 \
#        ${outdir}/discovery_rois_random_k${k}
#    
#done


###
# Replication Sample
###

for k in ${ks}; do
    echo "K of ${k}"

    connectir_glm.R \
        --infuncs1 ${indir}/roisinfo/replication_rois_random_k${k}_nifti.txt \
        --regressors ${indir}/subinfo/04_replication_regressors.txt \
        --contrasts ${indir}/subinfo/04_replication_contrasts.txt \
        --infuncs2 ${indir}/subinfo/04_replication_funcpaths_4mm.txt \
        --ztransform \
        --brainmask2 ${indir}/rois/mask_for_age+sex_gray_4mm.nii.gz \
        --forks 1 --threads 10 \
        --memlimit 24 \
        ${outdir}/replication_rois_random_k${k}

done

