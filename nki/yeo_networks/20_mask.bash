#!/usr/bin/env bash

base="/home2/data/Projects/CWAS"

3dresample -inset ${base}/rois/yeo_combined/all_7networks_2mm.nii.gz \
    -master ${base}/nki/rois/standard_4mm.nii.gz \
    -prefix ${base}/rois/yeo_combined/all_7networks_4mm.nii.gz

3dcalc -a ${base}/rois/yeo_combined/all_7networks_4mm.nii.gz \
    -b ${base}/nki/rois/mask_gray_4mm.nii.gz \
    -expr 'a*step(b)' \
    -prefix ${base}/nki/rois/all_7networks_4mm.nii.gz
