#!/usr/bin/env bash

if [[ "$#" -ne 4 ]]; then
    echo "usage: $0 scan strategy resolution smoothed"
    echo "  scan: short, medium, or long"
    echo "  strategy: global or compcor"
    echo "  resolution: in mm"
    echo "  smoothed: 0 for no and 1 for yes and any other number for the exact FWHM"
    exit 1
fi

scan=$1
strategy=$2
res=$3
if [[ $4 -eq 1 ]]; then
    sm="_smoothed"
elif [[ $4 -gt 1 ]]; then
    sm="_fwhm$( count -digits 2 $4 $4 | sed s/\ // )"
else
    sm=""
fi

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/nki"

if [[ "$scan" == "short" ]]; then
    subdir="${indir}/subinfo/40_Set1_N104"
elif [[ "$scan" == "medium" ]]; then
    subdir="${indir}/subinfo/40_Set1_N104"
elif [[ "$scan" == "long" ]]; then
    subdir="${indir}/subinfo/40_Set2_N92"
else
    echo "unrecognized scan: ${scan}"
    exit 1
fi

roidir="${basedir}/nki/rois"

suffix="${res}mm${sm}"

outbase="${basedir}/nki/cwas"
mkdir $outbase 2> /dev/null


###
# Distances
###

outdir="${outbase}/${scan}"
mkdir ${outdir} 2> /dev/null

echo "Voxelwise"
echo ${subdir}/${scan}_${strategy}_funcpaths_${suffix}.txt
time connectir_subdist.R \
    --infuncs1 ${subdir}/${scan}_${strategy}_funcpaths_${suffix}.txt \
    --brainmask1 ${roidir}/mask_gray_${res}mm.nii.gz \
    --regress ${subdir}/${scan}_mean_global.txt \
    --ztransform \
    --bg ${roidir}/standard_${res}mm.nii.gz \
    --forks 1 --threads 12 \
    --memlimit 30 \
    ${outdir}/${strategy}_kvoxs${sm}_to_kvoxs${sm}_mean_global
