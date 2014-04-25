#!/usr/bin/env bash

if [[ "$#" -eq 0 ]]; then
    echo "usage: $0 strategy"
    echo "strategy: global or compcor"
    exit 1
fi

strategy=$1
basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/adhd200_rerun"
roidir="${basedir}/adhd200_rerun/rois"


###
# CWAS
###

outdir="${basedir}/adhd200_rerun/cwas"
mkdir $outdir 2> /dev/null

# ROIs Only
#ks="0025 0050 0100 0200 0400 0800 1600 3200"
ks="0800"

for k in ${ks}; do
    echo "K of ${k}"
    
    # Subject Distances
    time connectir_subdist.R \
        --infuncs1 ${indir}/subinfo/z_${strategy}_rois_random_k${k}_combined.txt \
        --in2D1 \
        --ztransform \
        --bg ${roidir}/standard_4mm.nii.gz \
        --forks 1 --threads 10 \
        --memlimit 24 \
        ${outdir}/${strategy}_rois_random_k${k}_only
done

## ROIs with voxelwise
##ks="0025 0050 0100 0200 0400 0800 1600 3200"
#ks="0800"
#
#for k in ${ks}; do
#    echo "K of ${k}"
#    
#    # Subject Distances
#    time connectir_subdist.R \
#        --infuncs1 ${indir}/subinfo/z_${strategy}_rois_random_k${k}_combined.txt \
#        --in2D1 \
#        --infuncs2 ${indir}/subinfo/30_${strategy}_funcpaths_4mm_combined.txt \
#        --ztransform \
#        --brainmask2 ${roidir}/mask_gray_4mm.nii.gz \
#        --bg ${roidir}/standard_4mm.nii.gz \
#        --forks 1 --threads 10 \
#        --memlimit 24 \
#        ${outdir}/${strategy}_rois_random_k${k}
#done

## Voxelwise
#time connectir_subdist.R \
#    --infuncs1 ${indir}/subinfo/30_${strategy}_funcpaths_4mm_combined.txt \
#    --ztransform \
#    --brainmask2 ${roidir}/mask_gray_4mm_combined.nii.gz \
#    --bg ${roidir}/standard_4mm.nii.gz \
#    --forks 1 --threads 12 \
#    --memlimit 30 \
#    ${outdir}/${strategy}_kvoxelwise_combined

