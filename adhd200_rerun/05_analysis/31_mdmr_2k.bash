#!/usr/bin/env bash

# This 2k run is mainly for getting the voxel-level threshold
# that is these permutations will be used to determine the 
# Pseudo-F statistic that corresponds to a given set of p-values

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/adhd200"
outdir="${basedir}/adhd200"

sdir="${outdir}/cwas/rois_random_k3200"

## TDC vs ADHD-C
connectir_mdmr.R -i ${sdir} \
    --subdist ${sdir}/tdc_adhdc_subdist_gower.desc \
    --formula "group + gender + age + iq + meanFD" \
    --model ${sdir}/tdc_adhdc_model.csv \
    --factors2perm "group" \
    --permutations 1999 \
    --forks 1 --threads 8 \
    --memlimit 8 \
    --save-perms \
    --ignoreprocerror \
    perms02k_tdc_vs_adhdc_gender+age+iq+meanFD.mdmr

## TDC vs ADHD-I
connectir_mdmr.R -i ${sdir} \
    --subdist ${sdir}/tdc_adhdi_subdist_gower.desc \
    --formula "group + gender + age + iq + meanFD" \
    --model ${sdir}/tdc_adhdi_model.csv \
    --factors2perm "group" \
    --permutations 1999 \
    --forks 1 --threads 8 \
    --memlimit 8 \
    --save-perms \
    --ignoreprocerror \
    perms02k_tdc_vs_adhdi_gender+age+iq+meanFD.mdmr

## ADHD-C vs ADHD-I
connectir_mdmr.R -i ${sdir} \
    --subdist ${sdir}/adhdc_adhdi_subdist_gower.desc \
    --formula "group + gender + age + iq + meanFD" \
    --model ${sdir}/adhdc_adhdi_model.csv \
    --factors2perm "group" \
    --permutations 1999 \
    --forks 1 --threads 8 \
    --memlimit 8 \
    --save-perms \
    --ignoreprocerror \
    perms02k_adhdc_vs_adhdi_gender+age+iq+meanFD.mdmr

