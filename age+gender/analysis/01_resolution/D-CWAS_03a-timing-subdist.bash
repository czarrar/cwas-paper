#!/usr/bin/env bash

# This script runs a subset of voxels and times it
# it will run it for the voxelwise and different ROIs distances

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/age+gender/analysis/01_resolution"
outdir="${basedir}/age+gender/01_resolution/cwas/timing"
mkdir $outdir 2> /dev/null

ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"

for (( i = 0; i < 10; i++ )); do
    j=$((i+1))
    echo "ITERATION #${j}"
    
    # ROIs
    for k in ${ks}; do
        echo "K of ${k}"
        touch ${outdir}/time_k${k}.txt
        
        # Subject Distances
        { time connectir_subdist.R -i ${indir}/z_funcpaths_4mm.txt \
            --infuncs2 ${indir}/z_rois_k${k}.txt \
            --in2D2 \
            --ztransform \
            --brainmask1 ${indir}/rois/mask_4mm_100voxs.nii.gz \
            --bg ${basedir}/rois/standard_4mm.nii.gz \
            --forks 1 --threads 24 \
            --memlimit 30 \
            ${outdir}/rois_k${k} >stdout 2>stderr; } 2>>${outdir}/time_k${k}.txt
        
        rm -r ${outdir}/rois_k${k}
    done
    
    # Voxelwise
    touch ${outdir}/time_voxelwise.txt
    { time connectir_subdist.R -i ${indir}/z_funcpaths_4mm.txt \
        --ztransform \
        --brainmask1 ${indir}/rois/mask_4mm_100voxs.nii.gz \
        --brainmask2 ${indir}/rois/mask_4mm.nii.gz \
        --bg ${basedir}/rois/standard_4mm.nii.gz \
        --forks 1 --threads 24 \
        --memlimit 30 \
        ${outdir}/voxelwise >stdout 2>stderr; } 2>>${outdir}/time_voxelwise.txt
    rm -r ${outdir}/voxelwise
done
