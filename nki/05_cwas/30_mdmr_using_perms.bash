#!/usr/bin/env bash

# This script runs the medium scan (regular and reference) again
# but with the permutations from the short scan

scan="medium"
ref_scan="short"
strategy="compcor"
sm="_fwhm08"

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/nki"

subdir="${indir}/subinfo/40_Set1_N104"

cwasdir="${basedir}/nki/cwas"
distbase="${cwasdir}/${scan}"


###
# MDMR
###

# Voxelwise
echo "Regular"
sdistdir="${distbase}/${strategy}_kvoxs${sm}_to_kvoxs${sm}"
ref_sdistdir="${cwasdir}/${ref_scan}/${strategy}_kvoxs${sm}_to_kvoxs${sm}"
time connectir_mdmr.R -i ${sdistdir} \
    --formula "FSIQ + Age + Sex + ${scan}_meanFD" \
    --model ${subdir}/subject_info_with_iq_and_gcors.csv \
    --factors2perm "FSIQ" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    --permfiles "${ref_sdistdir}/iq_age+sex+meanFD.mdmr/perms_FSIQ.desc" \
    shortperms_iq_age+sex+meanFD.mdmr

echo "Reference"
sdistdir="${distbase}/${strategy}_kvoxs${sm}_to_kvoxs${sm}"
time connectir_mdmr.R -i ${sdistdir} \
    --formula "FSIQ + Age + Sex + ${scan}_meanFD" \
    --model ${subdir}/subject_info_with_iq_and_gcors.csv \
    --factors2perm "FSIQ" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    --permfiles "${ref_sdistdir}/reference_iq_age+sex+meanFD.mdmr/perms_FSIQ.desc" \
    shortperms_reference_iq_age+sex+meanFD.mdmr
