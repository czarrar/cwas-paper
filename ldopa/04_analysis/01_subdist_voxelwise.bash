#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/ldopa"
roidir="${basedir}/ldopa/rois"

###
# CWAS with everything
###

outdir="${basedir}/ldopa/cwas"
mkdir $outdir 2> /dev/null


# Subject Distances
time connectir_subdist.R \
    --infuncs1 ${indir}/subinfo/02_all_funcpaths_4mm_fwhm08.txt \
    --brainmask1 ${roidir}/mask_for_ldopa_gray_4mm.nii.gz \
    --ztransform \
    --bg ${roidir}/standard_4mm.nii.gz \
    --forks 1 --threads 10 \
    --memlimit 20 \
    ${outdir}/compcor_kvoxs_smoothed

