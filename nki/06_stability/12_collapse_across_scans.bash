#!/bin/bash

# Want to combine across scans for the mean and standard-deviation measures

base="/home2/data/Projects/CWAS"
indir="${base}/nki/stability/compcor_kvoxs_smoothed_to_kvoxs_smoothed"

echo "changing to outdir"
cd $indir

# Mean
echo "collapsing mean images"
measure="mean"
3dcalc -a ${measure}_short.nii.gz -b ${measure}_medium.nii.gz -c ${measure}_long.nii.gz \
    -expr '(a+b+c)/3' -prefix scan_average_${measure}.nii.gz

# Standard Deviation
echo "collapsing standard deviation images"
measure="sd"
3dcalc -a ${measure}_short.nii.gz -b ${measure}_medium.nii.gz -c ${measure}_long.nii.gz \
    -expr '(a+b+c)/3' -prefix scan_average_${measure}.nii.gz

# Coefficient of Variation
echo "collapsing coefficient of variation images"
measure="cv"
3dcalc -a ${measure}_short.nii.gz -b ${measure}_medium.nii.gz -c ${measure}_long.nii.gz \
    -expr '(a+b+c)/3' -prefix scan_average_${measure}.nii.gz
