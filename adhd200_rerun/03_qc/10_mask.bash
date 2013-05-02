#!/usr/bin/env bash

# This script sets up the grey-matter mask

resolution=2

roidir="/home2/data/Projects/CWAS/adhd200_rerun/rois"
cd $roidir

echo "cp $FSLDIR/data/standard/MNI152_T1_GREY_2mm_25pc_mask.nii.gz grey_matter_${resolution}mm.nii.gz"
cp $FSLDIR/data/standard/MNI152_T1_GREY_2mm_25pc_mask.nii.gz grey_matter_${resolution}mm.nii.gz

echo "3dcalc -a mask_overlap_${resolution}mm.nii.gz \
    -b grey_matter_${resolution}mm.nii.gz \
    -expr 'step(a)*step(b)' \
    -prefix mask_grey_${resolution}mm.nii.gz"
3dcalc -a mask_overlap_${resolution}mm.nii.gz \
    -b grey_matter_${resolution}mm.nii.gz \
    -expr 'step(a)*step(b)' \
    -prefix mask_grey_${resolution}mm.nii.gz
