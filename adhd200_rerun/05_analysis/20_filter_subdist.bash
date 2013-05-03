#!/usr/bin/env bash

if [[ "$#" -eq 0 ]]; then
    echo "usage: $0 strategy"
    echo "strategy: global or compcor"
    exit 1
fi

strategy=$1
basedir="/home2/data/Projects/CWAS"
subdir="${basedir}/share/adhd200_rerun/subinfo"
sdir="${basedir}/adhd200_rerun/cwas/${strategy}_rois_random_k3200"

# TDC vs ADHD-C
connectir_filter_subdist.R -i ${sdir}/subdist.desc \
    -m ${subdir}/30_subjects_matched.csv \
    --expr "diagnosis != 'ADHD-I'" \
    --forks 1 \
    --threads 12 \
    --memlimit 12 \
    ${sdir}/tdc_adhdc

# TDC vs ADHD-I
connectir_filter_subdist.R -i ${sdir}/subdist.desc \
    -m ${subdir}/30_subjects_matched.csv \
    --expr "diagnosis != 'ADHD-C'" \
    --forks 1 \
    --threads 12 \
    --memlimit 12 \
    ${sdir}/tdc_adhdi

# ADHD-C vs ADHD-I
connectir_filter_subdist.R -i ${sdir}/subdist.desc \
    -m ${subdir}/30_subjects_matched.csv \
    --expr "diagnosis != 'TDC'" \
    --forks 1 \
    --threads 12 \
    --memlimit 12 \
    ${sdir}/adhdc_adhdi
