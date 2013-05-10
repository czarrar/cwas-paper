#!/usr/bin/env bash

if [[ "$#" -ne 2 ]]; then
    echo "usage: $0 scan strategy"
    echo "scan: short or medium"
    echo "strategy: global or compcor"
    exit 1
fi

scan=$1
strategy=$2

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/nki"
subdir="${indir}/subinfo/40_Set1_N104"

roidir="${basedir}/nki/rois"

outbase="${basedir}/nki/cwas"
mkdir $outbase 2> /dev/null


###
# Distances
###

outdir="${outbase}/${scan}"
mkdir ${outdir} 2> /dev/null

## ROI-based
#ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
#for k in ${ks}; do
#    echo "K of ${k}"
#    # Subject Distances
#    time connectir_subdist.R \
#        --infuncs1 ${subdir}/${scan}_${strategy}_rois_random_k${k}.txt \
#        --in2D1 \
#        --infuncs2 ${subdir}/${scan}_${strategy}_funcpaths_4mm.txt \
#        --brainmask2 ${roidir}/mask_gray_4mm.nii.gz \
#        --ztransform \
#        --bg ${roidir}/standard_4mm.nii.gz \
#        --forks 1 --threads 12 \
#        --memlimit 30 \
#        ${outdir}/${strategy}_rois_random_k${k}
#done

# Only ROI-based
ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
for k in ${ks}; do
    echo "K of ${k}"
    # Subject Distances
    time connectir_subdist.R \
        --infuncs1 ${subdir}/${scan}_${strategy}_rois_random_k${k}.txt \
        --in2D1 \
        --ztransform \
        --bg ${roidir}/standard_4mm.nii.gz \
        --forks 1 --threads 12 \
        --memlimit 30 \
        ${outdir}/${strategy}_only_rois_random_k${k}
done

## Voxelwise
#echo "Voxelwise"
#time connectir_subdist.R \
#    --infuncs1 ${subdir}/${scan}_${strategy}_funcpaths_4mm.txt \
#    --brainmask1 ${roidir}/mask_gray_4mm.nii.gz \
#    --ztransform \
#    --bg ${roidir}/standard_4mm.nii.gz \
#    --forks 1 --threads 12 \
#    --memlimit 30 \
#    ${outdir}/${strategy}_kvoxelwise
