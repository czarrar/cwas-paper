#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "usage: $0 strategy"
    echo "strategy: global or compcor"
    exit 1
fi

strategy=$1

basedir="/home2/data/Projects/CWAS"
roidir="${basedir}/development+motion/rois"
subdir="${basedir}/share/development+motion/subinfo"

cwasdir="${basedir}/development+motion/cwas"

cd /home2/data/Projects/CWAS/share/lib/clustcor


###
# CORRECT
###

# Voxelwise - Age
echo "Voxelwise - Age"
sdistdir="${cwasdir}/${strategy}_kvoxs_smoothed"
mdmrdir="${sdistdir}/age_sex+tr.mdmr"
./le_correcter.R ${sdistdir} ${mdmrdir}

# Voxelwise - Age + MeanGcor
echo "Voxelwise - Age + MeanGcor"
sdistdir="${cwasdir}/${strategy}_kvoxs_smoothed"
mdmrdir="${sdistdir}/age_sex+tr+meanGcor.mdmr"
./le_correcter.R ${sdistdir} ${mdmrdir}

# Voxelwise - Age + Motion
echo "Voxelwise - Age + Motion"
sdistdir="${cwasdir}/${strategy}_kvoxs_smoothed"
mdmrdir="${sdistdir}/age+motion_sex+tr.mdmr"
./le_correcter.R ${sdistdir} ${mdmrdir}

# Voxelwise - Age + Motion with mean global
echo "Voxelwise - Age + Motion with Mean Global"
sdistdir="${cwasdir}/${strategy}_kvoxs_smoothed"
mdmrdir="${sdistdir}/age+motion_sex+tr+meanGcor.mdmr"
./le_correcter.R ${sdistdir} ${mdmrdir}


## Global

strategy="global"

# Voxelwise - Age
echo "Voxelwise - Age"
sdistdir="${cwasdir}/${strategy}_kvoxs_smoothed"
mdmrdir="${sdistdir}/age_sex+tr.mdmr"
./le_correcter.R ${sdistdir} ${mdmrdir}

# Voxelwise - Age + Motion
echo "Voxelwise - Age + Motion"
sdistdir="${cwasdir}/${strategy}_kvoxs_smoothed"
mdmrdir="${sdistdir}/age+motion_sex+tr.mdmr"
./le_correcter.R ${sdistdir} ${mdmrdir}
