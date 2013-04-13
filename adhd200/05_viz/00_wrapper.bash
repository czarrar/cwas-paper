#!/bin/bash

# This runs all the scripts in this directory in proper order

## Standardize

# Convert LDOPA CWAS from MNI152 to MNI305 for freesurfer
./10_to_fsaverage.bash


## Images

# Surface images for left hemisphere
./20_pysurfer_lh.py
./21_glm-regress_pysurfer-lh.py

# Surface images for right hemisphere
./20_pysurfer_rh.py
./21_glm-regress_pysurfer-rh.py

# Crop
./22_crop_images.bash


## Report

# Generate report page
# see http://czarrar.github.com/cwas-paper/50_dev-motion/report_surfaces.html
# after doing git commit and push
rdir="/home2/data/Projects/CWAS/reports"
mkdir ${rdir}/50_dev-motion 2> /dev/null
../../lib/x_knit.R 40_report-surfaces.Rmd ${rdir}/50_dev-motion report_surfaces
