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
    
# Subject Distances
time connectir_subdist.R \
    --infuncs1 ${indir}/subinfo/30_${strategy}_funcpaths_4mm_combined_fwhm08.txt \
    --brainmask1 ${roidir}/mask_gray_4mm_combined.nii.gz \
    --ztransform \
    --bg ${roidir}/standard_4mm.nii.gz \
    --forks 1 --threads 10 \
    --memlimit 20 \
    ${outdir}/${strategy}_kvoxs_fwhm08
