#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/age+gender/analysis/01_resolution"
outdir="${basedir}/age+gender/01_resolution/cwas"
mkdir $outdir 2> /dev/null

# MDMR
rm -f Rsge*
rm -rf ${outdir}/voxelwise/testing_gelert.mdmr
connectir_mdmr.R -i ${outdir}/voxelwise \
    --formula "age + sex + mean_FD" \
    --model ${indir}/z_details.csv \
    --permutations 14999 \
    --factors2perm "age,sex" \
    --forks 1 --threads 4 --jobs 24 \
    --memlimit 1 \
    --save-perms \
    --ignoreprocerror \
    age+gender_with-meanFD_15k_rhs.mdmr
