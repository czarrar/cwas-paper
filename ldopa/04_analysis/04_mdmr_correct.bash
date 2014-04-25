#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "usage: $0 strategy"
    echo "strategy: global or compcor"
    exit 1
fi

strategy=$1

basedir="/home2/data/Projects/CWAS"
roidir="${basedir}/ldopa/rois"
subdir="${basedir}/share/ldopa/subinfo"

cwasdir="${basedir}/ldopa/cwas"

cd /home2/data/Projects/CWAS/share/lib/clustcor


###
# CORRECT
###

echo "Voxelwise"
sdistdir="${cwasdir}/${strategy}_kvoxs_smoothed"
mdmrdir="${sdistdir}/ldopa_subjects+meanFD.mdmr"
./le_correcter.R ${sdistdir} ${mdmrdir}

#echo "Voxelwise"
#sdistdir="${cwasdir}/${strategy}_kvoxs_smoothed"
#mdmrdir="${sdistdir}/ldopa_subjects+meanFD+meanGcor.mdmr"
#./le_correcter.R ${sdistdir} ${mdmrdir}
