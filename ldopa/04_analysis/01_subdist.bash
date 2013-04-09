#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/ldopa"


###
# CWAS with everything
###

outdir="${basedir}/ldopa/cwas"
mkdir $outdir 2> /dev/null

#ks="0025 0050 0100 0200 0400 0800 1600 3200"
ks="3200"

for k in ${ks}; do
    echo "K of ${k}"
    
    # Subject Distances
    time connectir_subdist.R \
        --infuncs1 ${indir}/subinfo/z_rois_random_k${k}.txt \
        --in2D1 \
        --infuncs2 ${indir}/subinfo/02_all_funcpaths_4mm.txt \
        --ztransform \
        --brainmask2 ${indir}/rois/mask_for_ldopa_gray_4mm.nii.gz \
        --bg ${basedir}/rois/standard_4mm.nii.gz \
        --forks 1 --threads 12 \
        --memlimit 24 \
        ${outdir}/rois_random_k${k}
done
