#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/ldopa"
outdir="${basedir}/ldopa"

connectir_mdmr.R -i ${outdir}/cwas/rois_random_k3200 \
    --formula "subjects + conditions + meanFD" \
    --model ${indir}/subinfo/02_demo.csv \
    --factors2perm "conditions" \
    --strata "subjects" \
    --permutations 14999 \
    --forks 1 --threads 10 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    ldopa_subjects+meanFD.mdmr

