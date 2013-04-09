#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/age+gender/analysis/01_resolution"
outdir="${basedir}/age+gender/01_resolution/cwas"
mkdir $outdir 2> /dev/null

# Subject Distances
connectir_subdist.R -i ${indir}/z_funcpaths_4mm.txt \
    --ztransform \
    --brainmask1 ${indir}/rois/mask_4mm.nii.gz \
    --bg ${basedir}/rois/standard_4mm.nii.gz \
    --forks 1 --threads 24 \
    --memlimit 50 \
    ${outdir}/voxelwise

