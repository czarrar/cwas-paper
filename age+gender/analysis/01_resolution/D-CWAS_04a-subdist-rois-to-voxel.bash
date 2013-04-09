#!/usr/bin/env bash

# This script only runs ROIs for approach 1

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/age+gender/analysis/01_resolution"
outdir="${basedir}/age+gender/01_resolution/cwas"
mkdir $outdir 2> /dev/null

ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"


###
# Regular Parcellations
###
for k in ${ks}; do
    echo "K of ${k}"
    
    # Subject Distances
    time connectir_subdist.R \
        --infuncs1 ${indir}/z_rois_k${k}.txt \
        --in2D1 \
        --infuncs2 ${indir}/z_funcpaths_4mm.txt \
        --ztransform \
        --brainmask2 ${indir}/rois/mask_4mm.nii.gz \
        --bg ${basedir}/rois/standard_4mm.nii.gz \
        --forks 1 --threads 12 \
        --memlimit 30 \
        ${outdir}/rois-to-voxel_k${k}    
done


###
# Random Parcellations
###
for k in ${ks}; do
    echo "K of ${k}"
    
    # Subject Distances
    time connectir_subdist.R \
        --infuncs1 ${indir}/z_rois_random_k${k}.txt \
        --in2D1 \
        --infuncs2 ${indir}/z_funcpaths_4mm.txt \
        --ztransform \
        --brainmask2 ${indir}/rois/mask_4mm.nii.gz \
        --bg ${basedir}/rois/standard_4mm.nii.gz \
        --forks 1 --threads 12 \
        --memlimit 30 \
        ${outdir}/rois-to-voxel_random_k${k}    
done
