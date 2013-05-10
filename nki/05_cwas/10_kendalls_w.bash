#!/usr/bin/env bash

if [[ "$#" -ne 2 ]]; then
    echo "usage: $0 strategy scan"
    echo "strategy: global or compcor"
    echo "scan: short or medium"
    exit 1
fi

strategy=$1
scan=$2

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/nki"
subdir="${indir}/subinfo/40_Set1_N104"

roidir="${basedir}/nki/rois"

outbase="${basedir}/nki/kendalls_w"
mkdir $outbase 2> /dev/null

outdir="${outbase}/${scan}"
mkdir ${outdir} 2> /dev/null

time connectir_kendall.R \
    --infuncs1 ${subdir}/${scan}_${strategy}_funcpaths_4mm.txt \
    --brainmask1 ${roidir}/mask_gray_4mm.nii.gz \
    --bg ${roidir}/standard_4mm.nii.gz \
    --forks 1 --threads 12 \
    --memlimit 24 \
    ${outdir}/${strategy}_kvoxelwise

