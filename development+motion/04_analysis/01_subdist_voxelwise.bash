#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/development+motion"
roidir="${basedir}/development+motion/rois"


###
# CWAS with everything
###

outdir="${basedir}/development+motion/cwas"
mkdir $outdir 2> /dev/null


## Subject Distances
#time connectir_subdist.R \
#    --infuncs1 ${indir}/subinfo/02_funcpaths_4mm_fwhm08.txt \
#    --brainmask1 ${roidir}/mask_gray_4mm.nii.gz \
#    --ztransform \
#    --bg ${roidir}/standard_4mm.nii.gz \
#    --forks 1 --threads 10 \
#    --memlimit 20 \
#    ${outdir}/compcor_kvoxs_smoothed



####
## CWAS regress out motion
####
#
#outdir="${basedir}/development+motion/cwas_regress_motion"
#mkdir $outdir 2> /dev/null
#    
## Subject Distances
#time connectir_subdist.R \
#    --infuncs1 ${indir}/subinfo/02_funcpaths_4mm.txt \
#    --brainmask1 ${indir}/rois/mask_gray_4mm.nii.gz \
#    --regress ${indir}/subinfo/02_motion_regressor.txt \
#    --ztransform \
#    --bg ${basedir}/rois/standard_4mm.nii.gz \
#    --forks 1 --threads 12 \
#    --memlimit 24 \
#    ${outdir}/compcor_kvoxs_smoothed


###
# CWAS with everything (global)
###

outdir="${basedir}/development+motion/cwas"
mkdir $outdir 2> /dev/null


# Subject Distances
time connectir_subdist.R \
    --infuncs1 ${indir}/subinfo/02_funcpaths_global_4mm_fwhm08.txt \
    --brainmask1 ${roidir}/mask_gray_4mm.nii.gz \
    --ztransform \
    --bg ${roidir}/standard_4mm.nii.gz \
    --forks 1 --threads 10 \
    --memlimit 20 \
    ${outdir}/global_kvoxs_smoothed



