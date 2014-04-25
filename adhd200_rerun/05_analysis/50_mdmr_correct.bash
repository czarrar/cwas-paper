#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "usage: $0 strategy"
    echo "strategy: global or compcor"
    exit 1
fi

strategy=$1

basedir="/home2/data/Projects/CWAS"
roidir="${basedir}/adhd200_rerun/rois"
subdir="${basedir}/share/adhd200_rerun/subinfo"

cwasdir="${basedir}/adhd200_rerun/cwas"

cd /home2/data/Projects/CWAS/share/lib/clustcor


###
# CORRECT
###

echo "Voxelwise"
sdistdir="${cwasdir}/${strategy}_kvoxs_fwhm08"
mdmrdir="${sdistdir}/adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr"
./le_correcter.R ${sdistdir} ${mdmrdir}
