#!/usr/bin/env bash

# This script only runs ROIs for approach 1

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/age+gender/analysis/01_resolution"
outdir="${basedir}/age+gender/01_resolution/cwas"
mkdir $outdir 2> /dev/null

ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"


###
# Regular Parcellations
###

for k in ${ks}; do
    echo "K of ${k}"
    
    # MDMR
    time connectir_mdmr.R -i ${outdir}/rois-to-voxel_k${k} \
        --formula "age + sex + mean_FD" \
        --model ${indir}/z_details.csv \
        --permutations 14999 \
        --factors2perm "age,sex" \
        --forks 1 --threads 4 --jobs 24 \
        --memlimit 6 \
        --save-perms \
        --ignoreprocerror \
        age+gender_with-meanFD_15k_rhs.mdmr
done


###
# Random Parcellations
###

for k in ${ks}; do
    echo "K of ${k}"
    
    # MDMR
    time connectir_mdmr.R -i ${outdir}/rois-to-voxel_random_k${k} \
        --formula "age + sex + mean_FD" \
        --model ${indir}/z_details.csv \
        --permutations 14999 \
        --factors2perm "age,sex" \
        --forks 1 --threads 4 --jobs 24 \
        --memlimit 6 \
        --save-perms \
        --ignoreprocerror \
        age+gender_with-meanFD_15k_rhs.mdmr
done

