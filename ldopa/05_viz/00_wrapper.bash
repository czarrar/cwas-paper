#!/bin/bash

# This runs all the scripts in this directory in proper order

## Standardize

# Convert LDOPA CWAS from MNI152 to MNI305 for freesurfer
./10_to_fsaverage.bash


## Images

# Surface images for left hemisphere
./20_pysurfer_lh.py

# Surface images for right hemisphere
./20_pysurfer_rh.py

# Crop
./22_crop_images.bash


## Report

# Generate report page
# see http://czarrar.github.com/cwas-paper/50_dev-motion/report_surfaces.html
# after doing git commit and push
./42_generate-report.bash
