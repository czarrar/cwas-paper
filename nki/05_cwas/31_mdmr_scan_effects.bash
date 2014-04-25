#!/usr/bin/env bash

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
indir="${basedir}/share/nki"

subdir="${indir}/subinfo/40_Set1_N104"

cwasdir="${basedir}/nki/cwas"
distbase="${cwasdir}/${scan}_scan_effects"

roidir="${basedir}/nki/rois"


###
# MDMR
###

## Only ROI-based
##ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
#ks="3200"
#for k in ${ks}; do
#    echo "K of ${k}"
#    sdistdir="${distbase}/${strategy}_only_rois_random_k${k}${sm}"
#    time connectir_mdmr.R -i ${sdistdir} \
#        --formula "FSIQ + Age + Sex + ${scan}_meanFD" \
#        --model ${subdir}/subject_info_with_iq.csv \
#        --factors2perm "FSIQ" \
#        --permutations 14999 \
#        --forks 1 --threads 12 \
#        --memlimit 12 \
#        --save-perms \
#        --ignoreprocerror \
#        iq_age+sex+meanFD.mdmr
#done

## ROI-based
#ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
##ks="1600"
#for k in ${ks}; do
#    echo "K of ${k}"
#    sdistdir="${distbase}/${strategy}_rois_random_k${k}${sm}"
#    time connectir_mdmr.R -i ${sdistdir} \
#        --formula "FSIQ + Age + Sex + ${scan}_meanFD" \
#        --model ${subdir}/subject_info_with_iq.csv \
#        --factors2perm "FSIQ" \
#        --permutations 14999 \
#        --forks 1 --threads 12 \
#        --memlimit 12 \
#        --save-perms \
#        --ignoreprocerror \
#        iq_age+sex+meanFD.mdmr
#done

# Voxelwise
echo "Voxelwise"
sdistdir="${distbase}/${strategy}_kvoxs${sm}_to_kvoxs${sm}"
time connectir_mdmr.R -i ${sdistdir} \
    --formula "subject + scan + meanFD" \
    --model ${subdir}/subject_info_with_iq_byscan.csv \
    --factors2perm "scan" \
    --strata "subject" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    scan_subject+meanFD.mdmr

#sdistdir="${distbase}/${strategy}_kvoxs${sm}_to_kvoxs${sm}"
#time connectir_mdmr.R -i ${sdistdir} \
#    --formula "subject + scan + FSIQ + Age + Sex + meanFD" \
#    --model ${subdir}/subject_info_with_iq_byscan.csv \
#    --factors2perm "scan,FSIQ" \
#    --permutations 14999 \
#    --forks 1 --threads 12 \
#    --memlimit 12 \
#    --save-perms \
#    --ignoreprocerror \
#    scan+iq_subject+age+sex+meanFD.mdmr

## Unsmoothed -> Smoothed
#echo "Voxelwise"
#sdistdir="${distbase}/${strategy}_kvoxs_to_kvoxs${sm}"
#time connectir_mdmr.R -i ${sdistdir} \
#    --formula "FSIQ + Age + Sex + ${scan}_meanFD" \
#    --model ${subdir}/subject_info_with_iq.csv \
#    --factors2perm "FSIQ" \
#    --permutations 14999 \
#    --forks 1 --threads 12 \
#    --memlimit 12 \
#    --save-perms \
#    --ignoreprocerror \
#    iq_age+sex+meanFD.mdmr
#
#echo "Voxelwise"
#sdistdir="${distbase}/${strategy}_kvoxs${sm}_to_kvoxs"
#time connectir_mdmr.R -i ${sdistdir} \
#    --formula "FSIQ + Age + Sex + ${scan}_meanFD" \
#    --model ${subdir}/subject_info_with_iq.csv \
#    --factors2perm "FSIQ" \
#    --permutations 14999 \
#    --forks 1 --threads 12 \
#    --memlimit 12 \
#    --save-perms \
#    --ignoreprocerror \
#    iq_age+sex+meanFD.mdmr


