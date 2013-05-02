#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
subdir="${basedir}/share/adhd200/subinfo"
sdir="${basedir}/adhd200/cwas/rois_random_k3200"

# TDC vs ADHD-C
connectir_filter_subdist.R -i ${sdir}/subdist.desc \
    -m ${subdir}/04_subjects_matched.csv \
    --expr "group != 'ADHD-I'" \
    --forks 1 \
    --threads 12 \
    --memlimit 12 \
    ${sdir}/tdc_adhdc

# TDC vs ADHD-I
connectir_filter_subdist.R -i ${sdir}/subdist.desc \
    -m ${subdir}/04_subjects_matched.csv \
    --expr "group != 'ADHD-C'" \
    --forks 1 \
    --threads 12 \
    --memlimit 12 \
    ${sdir}/tdc_adhdi

# ADHD-C vs ADHD-I
connectir_filter_subdist.R -i ${sdir}/subdist.desc \
    -m ${subdir}/04_subjects_matched.csv \
    --expr "group != 'TDC'" \
    --forks 1 \
    --threads 12 \
    --memlimit 12 \
    ${sdir}/adhdc_adhdi
