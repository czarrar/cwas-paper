#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/adhd200"
outdir="${basedir}/adhd200"

sdir="${outdir}/cwas/rois_random_k3200"

if [[ "$#" -ne 2 ]]; then
    echo "usage: $0 scan strategy"
    echo "scan: short or medium"
    echo "strategy: global or compcor"
    exit 1
fi

scan=$1
strategy=$2

basedir="/home2/data/Projects/CWAS"
subdir="${basedir}/share/nki/subinfo/40_Set1_N104"

cwasdir="${basedir}/nki/cwas"
distbase="${cwasdir}/${scan}"


###
# MDMR
###

# ROI-based
#ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
ks="3200"
for k in ${ks}; do
    echo "K of ${k}"
    sdistdir="${strategy}_rois_random_k${k}"
    time connectir_mdmr.R -i ${sdistdir} \
        --formula "IQ + Age + Sex + ${scan}_meanFD" \
        --model ${subdir}/subject_info.csv \
        --factors2perm "IQ" \
        --permutations 14999 \
        --forks 1 --threads 12 \
        --memlimit 12 \
        --save-perms \
        --ignoreprocerror \
        iq_age+sex+meanFD.mdmr
done

# Voxelwise
echo "Voxelwise"
sdistdir="${strategy}_kvoxelwise"
time connectir_mdmr.R -i ${sdistdir} \
    --formula "IQ + Age + Sex + ${scan}_meanFD" \
    --model ${subdir}/subject_info.csv \
    --factors2perm "IQ" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    iq_age+sex+meanFD.mdmr
