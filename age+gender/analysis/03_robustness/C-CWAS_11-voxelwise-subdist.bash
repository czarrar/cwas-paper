#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share"
outdir="${basedir}/age+gender"

# Discovery Sample
connectir_subdist.R -i ${indir}/subinfo/04_discovery_funcpaths_4mm.txt \
    --ztransform \
    --brainmask1 ${indir}/rois/mask_for_age+sex_gray_4mm.nii.gz \
    --bg ${indir}/rois/standard_4mm.nii.gz \
    --forks 1 --threads 20 \
    --memlimit 80 \
    ${outdir}/cwas_discovery

# Replication Sample
connectir_subdist.R -i ${basedir}/share/subinfo/04_replication_funcpaths_4mm.txt \
    --ztransform \
    --brainmask1 ${indir}/rois/mask_for_age+sex_gray_4mm.nii.gz \
    --bg ${indir}/rois/standard_4mm.nii.gz \
    --forks 1 --threads 20 \
    --memlimit 80 \
    ${outdir}/cwas_replication

