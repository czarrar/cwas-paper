#!/usr/bin/env bash

# This script only runs ROIs for approach 1

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/age+gender/analysis/03_robustness"
outdir="${basedir}/age+gender/03_robustness/cwas"
mkdir $outdir 2> /dev/null

#ks="0025 0050 0100 0200 0400 0800 1600 3200"
#ks="1600"
ks="3200"

###
# Discovery Sample
###

for k in ${ks}; do
    echo "K of ${k}"
    
    # Subject Distances
    time connectir_subdist.R \
        --infuncs1 ${indir}/roisinfo/discovery_rois_random_k${k}_nifti.txt \
        --in2D1 \
        --infuncs2 ${indir}/subinfo/04_discovery_funcpaths_4mm.txt \
        --ztransform \
        --brainmask2 ${indir}/rois/mask_for_age+sex_gray_4mm.nii.gz \
        --bg ${basedir}/rois/standard_4mm.nii.gz \
        --forks 1 --threads 12 \
        --memlimit 24 \
        ${outdir}/discovery_rois_random_k${k}
done


###
# Replication Sample
###

for k in ${ks}; do
    echo "K of ${k}"
    
    # Subject Distances
    time connectir_subdist.R \
        --infuncs1 ${indir}/roisinfo/replication_rois_random_k${k}_nifti.txt \
        --in2D1 \
        --infuncs2 ${indir}/subinfo/04_replication_funcpaths_4mm.txt \
        --ztransform \
        --brainmask2 ${indir}/rois/mask_for_age+sex_gray_4mm.nii.gz \
        --bg ${basedir}/rois/standard_4mm.nii.gz \
        --forks 1 --threads 12 \
        --memlimit 24 \
        ${outdir}/replication_rois_random_k${k}
done
