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

## Only ROI-based
#echo "only ROI-based"
#ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
##ks="3200"
#for k in ${ks}; do
#    echo "K of ${k}"
#    
#    sdistdir="${distbase}/${strategy}_only_rois_random_k${k}"
#    mdmrdir="${sdistdir}/iq_age+sex+meanFD+meanGcor.mdmr"
#    roifile="${roidir}/rois_random_k${k}.nii.gz"
#    
#    ./le_correcter.R ${sdistdir} ${mdmrdir} ${roifile}
#done

## ROI-based
#echo "ROI-based"
##ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
#ks="0025"
#for k in ${ks}; do
#    echo "K of ${k}"
#    
#    sdistdir="${distbase}/${strategy}_rois_random_k${k}${sm}"
#    mdmrdir="${sdistdir}/iq_age+sex+meanFD+meanGcor.mdmr"
#    roifile="${roidir}/rois_random_k${k}.nii.gz"
#    
#    if [[ -e "${mdmrdir}/cluster_correct_v05_c05" ]]; then
#        echo "output already exists for ROI-based k${k}"
#    else
#        ./le_correcter.R ${sdistdir} ${mdmrdir} ${roifile}
#    fi
#done


# Voxelwise
echo "Voxelwise"

sdistdir="${distbase}/${strategy}_kvoxs${sm}_to_kvoxs${sm}"
roifile="${roidir}/rois_random_k${k}.nii.gz"

#mdmrdir="${sdistdir}/iq_age+sex+meanFD+meanGcor.mdmr"
#./le_correcter.R ${sdistdir} ${mdmrdir}

mdmrdir="${sdistdir}/meanGcor_iq+age+sex+meanFD.mdmr"
./le_correcter.R ${sdistdir} ${mdmrdir}


## Voxelwise
#echo "Voxelwise"
#
#sdistdir="${distbase}/${strategy}_kvoxs_smoothed_to_kvoxs"
#roifile="${roidir}/rois_random_k${k}.nii.gz"
#
#mdmrdir="${sdistdir}/iq_age+sex+meanFD+meanGcor.mdmr"
#./le_correcter.R ${sdistdir} ${mdmrdir}
#
##mdmrdir="${sdistdir}/meanGcor_iq+age+sex+meanFD.mdmr"
##./le_correcter.R ${sdistdir} ${mdmrdir}
#
#
## Voxelwise
#echo "Voxelwise"
#
#sdistdir="${distbase}/${strategy}_kvoxs_to_kvoxs_smoothed"
#roifile="${roidir}/rois_random_k${k}.nii.gz"
#
#mdmrdir="${sdistdir}/iq_age+sex+meanFD+meanGcor.mdmr"
#./le_correcter.R ${sdistdir} ${mdmrdir}

#mdmrdir="${sdistdir}/meanGcor_iq+age+sex+meanFD.mdmr"
#./le_correcter.R ${sdistdir} ${mdmrdir}
