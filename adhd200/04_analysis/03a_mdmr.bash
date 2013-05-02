#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/adhd200"
outdir="${basedir}/adhd200"

sdir="${outdir}/cwas/rois_random_k3200"

## TDC vs ADHD-C
connectir_mdmr.R -i ${sdir} \
    --subdist ${sdir}/tdc_adhdc_subdist_gower.desc \
    --formula "group + gender + age + iq + mean_FD" \
    --model ${sdir}/tdc_adhdc_model.csv \
    --factors2perm "group" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    tdc_vs_adhdc_gender+age+iq+mean_FD.mdmr

## TDC vs ADHD-I
connectir_mdmr.R -i ${sdir} \
    --subdist ${sdir}/tdc_adhdi_subdist_gower.desc \
    --formula "group + gender + age + iq + mean_FD" \
    --model ${sdir}/tdc_adhdi_model.csv \
    --factors2perm "group" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    tdc_vs_adhdi_gender+age+iq+mean_FD.mdmr

## ADHD-C vs ADHD-I
connectir_mdmr.R -i ${sdir} \
    --subdist ${sdir}/adhdc_adhdi_subdist_gower.desc \
    --formula "group + gender + age + iq + mean_FD" \
    --model ${sdir}/adhdc_adhdi_model.csv \
    --factors2perm "group" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    adhdc_vs_adhdi_gender+age+iq+mean_FD.mdmr

