#!/usr/bin/env bash

if [[ "$#" -ne 3 ]]; then
    echo "usage: $0 strategy resolution smoothed"
    echo "  strategy: global or compcor"
    echo "  resolution: in mm"
    echo "  smoothed: 0 for no and 1 for yes"
    exit 1
fi

strategy=$1
res=$2
if [[ $3 -eq 1 ]]; then
    sm="_smoothed"
else
    sm=""
fi

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/nki"

subdir="${indir}/subinfo/40_Set1_N104"

roidir="${basedir}/nki/rois"

suffix="${res}mm${sm}"

outbase="${basedir}/nki/cwas"
mkdir $outbase 2> /dev/null


###
# Distances
###

outdir="${outbase}/${scan}_scan_effects"
mkdir ${outdir} 2> /dev/null

## ROI-based
#ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
#for k in ${ks}; do
#    echo "K of ${k}"
#    # Subject Distances
#    time connectir_subdist.R \
#        --infuncs1 ${subdir}/${scan}_${strategy}_rois_random_k${k}.txt \
#        --in2D1 \
#        --infuncs2 ${subdir}/${scan}_${strategy}_funcpaths_${suffix}.txt \
#        --brainmask2 ${roidir}/mask_gray_${res}mm.nii.gz \
#        --ztransform \
#        --bg ${roidir}/standard_${res}mm.nii.gz \
#        --forks 1 --threads 12 \
#        --memlimit 30 \
#        ${outdir}/${strategy}_k${k}_to_kvoxs_${sm}
#done

## Only ROI-based
#ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
#for k in ${ks}; do
#    echo "K of ${k}"
#    # Subject Distances
#    time connectir_subdist.R \
#        --infuncs1 ${subdir}/${scan}_${strategy}_rois_random_k${k}.txt \
#        --in2D1 \
#        --ztransform \
#        --bg ${roidir}/standard_${res}mm.nii.gz \
#        --forks 1 --threads 12 \
#        --memlimit 30 \
#        ${outdir}/${strategy}_k${k}_to_k${k}
#done

echo "Voxelwise"
time connectir_subdist.R \
    --infuncs1 ${subdir}/short+medium_${strategy}_funcpaths_${suffix}.txt \
    --brainmask1 ${roidir}/mask_gray_${res}mm.nii.gz \
    --ztransform \
    --bg ${roidir}/standard_${res}mm.nii.gz \
    --forks 1 --threads 12 \
    --memlimit 30 \
    ${outdir}/${strategy}_kvoxs${sm}_to_kvoxs${sm}

#echo "Voxelwise"
#time connectir_subdist.R \
#    --infuncs1 ${subdir}/${scan}_${strategy}_funcpaths_${res}mm.txt \
#    --brainmask1 ${roidir}/mask_gray_${res}mm.nii.gz \
#    --infuncs2 ${subdir}/${scan}_${strategy}_funcpaths_${suffix}.txt \
#    --brainmask2 ${roidir}/mask_gray_${res}mm.nii.gz \
#    --ztransform \
#    --bg ${roidir}/standard_${res}mm.nii.gz \
#    --forks 1 --threads 12 \
#    --memlimit 48 \
#    ${outdir}/${strategy}_kvoxs_to_kvos${sm}

#echo "Voxelwise"
#time connectir_subdist.R \
#    --infuncs1 ${subdir}/${scan}_${strategy}_funcpaths_${suffix}.txt \
#    --brainmask1 ${roidir}/mask_gray_${res}mm.nii.gz \
#    --infuncs2 ${subdir}/${scan}_${strategy}_funcpaths_${res}mm.txt \
#    --brainmask2 ${roidir}/mask_gray_${res}mm.nii.gz \
#    --ztransform \
#    --bg ${roidir}/standard_${res}mm.nii.gz \
#    --forks 1 --threads 12 \
#    --memlimit 48 \
#    ${outdir}/${strategy}_kvoxs${sm}_to_kvoxs
