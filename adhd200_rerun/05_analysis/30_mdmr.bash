#!/usr/bin/env bash

if [[ "$#" -eq 0 ]]; then
    echo "usage: $0 strategy"
    echo "strategy: global or compcor"
    exit 1
fi

strategy=$1
study="adhd200_rerun"

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/${study}"
outdir="${basedir}/${study}"
sdir="${outdir}/cwas/${strategy}_rois_random_k3200"

## TDC vs ADHD-C
connectir_mdmr.R -i ${sdir} \
    --subdist ${sdir}/tdc_adhdc_subdist_gower.desc \
    --formula "diagnosis + sex + age + iq + mean_FD" \
    --model ${sdir}/tdc_adhdc_model.csv \
    --factors2perm "diagnosis" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    tdc_vs_adhdc_gender+age+iq+mean_FD.mdmr

## TDC vs ADHD-I
connectir_mdmr.R -i ${sdir} \
    --subdist ${sdir}/tdc_adhdi_subdist_gower.desc \
    --formula "diagnosis + sex + age + iq + mean_FD" \
    --model ${sdir}/tdc_adhdi_model.csv \
    --factors2perm "diagnosis" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    tdc_vs_adhdi_gender+age+iq+mean_FD.mdmr

## ADHD-C vs ADHD-I
connectir_mdmr.R -i ${sdir} \
    --subdist ${sdir}/adhdc_adhdi_subdist_gower.desc \
    --formula "diagnosis + sex + age + iq + mean_FD" \
    --model ${sdir}/adhdc_adhdi_model.csv \
    --factors2perm "diagnosis" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    adhdc_vs_adhdi_gender+age+iq+mean_FD.mdmr

