#!/usr/bin/env bash

# This script only runs ROIs for approach 1

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/age+gender/analysis/01_resolution"
outdir="${basedir}/age+gender/01_resolution/cwas"
mkdir $outdir 2> /dev/null

ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"


###
# Regular => Regular Parcellations
###
#for k in ${ks}; do
#    echo "K of ${k}"
#    
#    # Subject Distances
#    time connectir_subdist.R \
#        --infuncs1 ${indir}/z_rois_k3200.txt \
#        --in2D1 \
#        --infuncs2 ${indir}/z_rois_k${k}.txt \
#        --in2D2 \
#        --ztransform \
#        --bg ${basedir}/rois/standard_4mm.nii.gz \
#        --forks 1 --threads 10 \
#        --memlimit 20 \
#        ${outdir}/roi-k3200_with_roi-k${k}    
#done


###
# Regular => Random Parcellations
###

for k in ${ks}; do
    echo "K of ${k}"
    
    # Subject Distances
    time connectir_subdist.R \
        --infuncs1 ${indir}/z_rois_k3200.txt \
        --in2D1 \
        --infuncs2 ${indir}/z_rois_random_k${k}.txt \
        --in2D2 \
        --ztransform \
        --bg ${basedir}/rois/standard_4mm.nii.gz \
        --forks 1 --threads 10 \
        --memlimit 20 \
        ${outdir}/roi-k3200_with_random-roi-k${k}
done


###
# Random => Regular Parcellations
###
#for k in ${ks}; do
#    echo "K of ${k}"
#    
#    # Subject Distances
#    time connectir_subdist.R \
#        --infuncs1 ${indir}/z_rois_random_k3200.txt \
#        --in2D1 \
#        --infuncs2 ${indir}/z_rois_k${k}.txt \
#        --in2D2 \
#        --ztransform \
#        --bg ${basedir}/rois/standard_4mm.nii.gz \
#        --forks 1 --threads 10 \
#        --memlimit 20 \
#        ${outdir}/random-roi-k3200_with_roi-k${k}    
#done


###
# Random => Random Parcellations
###

for k in ${ks}; do
    echo "K of ${k}"
    
    # Subject Distances
    time connectir_subdist.R \
        --infuncs1 ${indir}/z_rois_random_k3200.txt \
        --in2D1 \
        --infuncs2 ${indir}/z_rois_random_k${k}.txt \
        --in2D2 \
        --ztransform \
        --bg ${basedir}/rois/standard_4mm.nii.gz \
        --forks 1 --threads 10 \
        --memlimit 20 \
        ${outdir}/random-roi-k3200_with_random-roi-k${k}
done
