#!/bin/bash

if [[ "$#" -ne 3 ]]; then
    echo "usage: $0 scan strategy smoothed"
    echo "scan: short or medium"
    echo "strategy: global or compcor"
    echo "smoothed: 0 for no and 1 for yes and any other number for the exact FWHM"
    exit 1
fi

scan=$1
strategy=$2
if [[ $3 -eq 1 ]]; then
    sm="_smoothed"
elif [[ $3 -gt 1 ]]; then
    sm="_fwhm$( count -digits 2 $3 $3 | sed s/\ // )"
else
    sm=""
fi

basedir="/home2/data/Projects/CWAS"
roidir="${basedir}/nki/rois"
subdir="${basedir}/share/nki/subinfo/40_Set1_N104"

cwasdir="${basedir}/nki/cwas"
distbase="${cwasdir}/${scan}"


cd /home2/data/Projects/CWAS/share/lib/clustcor


###
# CORRECT
###

# Voxelwise
echo "Voxelwise"

sdistdir="${distbase}/${strategy}_kvoxs${sm}_to_kvoxs${sm}_mean_global"
mdmrdir="${sdistdir}/iq_age+sex+meanFD.mdmr"
roifile="${roidir}/rois_random_k${k}.nii.gz"

./le_correcter.R ${sdistdir} ${mdmrdir}
