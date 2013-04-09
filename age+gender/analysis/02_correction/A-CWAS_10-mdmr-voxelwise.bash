#!/usr/bin/env bash

# This will run a few rounds of MDMR
# in order to have a total of 50,0000 permutations

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/age+gender/analysis/01_resolution"
outdir="${basedir}/age+gender/01_resolution/cwas"
mkdir $outdir 2> /dev/null

# MDMR - Round 2
connectir_mdmr.R -i ${outdir}/voxelwise \
    --formula "age + sex + mean_FD" \
    --model ${indir}/z_details.csv \
    --permutations 15000 \
    --factors2perm "age,sex" \
    --forks 1 --threads 4 --jobs 24 \
    --memlimit 4 \
    --save-perms \
    --ignoreprocerror \
    age+gender_with-meanFD_15k_rhs_p2.mdmr

# MDMR - Round 3
connectir_mdmr.R -i ${outdir}/voxelwise \
    --formula "age + sex + mean_FD" \
    --model ${indir}/z_details.csv \
    --permutations 20000 \
    --factors2perm "age,sex" \
    --forks 1 --threads 4 --jobs 24 \
    --memlimit 5 \
    --save-perms \
    --ignoreprocerror \
    age+gender_with-meanFD_20k_rhs_p3.mdmr
