#!/bin/bash

if [[ "$#" -ne 2 ]]; then
    echo "usage: $0 strategy smoothed"
    echo "strategy: global or compcor"
    echo "smoothed: 0 for no and 1 for yes"
    exit 1
fi

strategy=$1
if [[ $2 -eq 1 ]]; then
    sm="_smoothed"
else
    sm=""
fi

basedir="/home2/data/Projects/CWAS"
roidir="${basedir}/nki/rois"
subdir="${basedir}/share/nki/subinfo/40_Set1_N104"

cwasdir="${basedir}/nki/cwas"
distbase="${cwasdir}/${scan}_scan_effects"

cd /home2/data/Projects/CWAS/share/lib/clustcor


###
# CORRECT
###

## Voxelwise

# Voxelwise
echo "Voxelwise"

sdistdir="${distbase}/${strategy}_kvoxs${sm}_to_kvoxs${sm}"
mdmrdir="${sdistdir}/scan_subject+meanFD.mdmr"
roifile="${roidir}/rois_random_k${k}.nii.gz"

./le_correcter.R ${sdistdir} ${mdmrdir}
