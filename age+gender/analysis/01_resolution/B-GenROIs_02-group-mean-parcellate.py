#!/usr/bin/env python

# Create spatially constrained ROIs using Cameron's pyClusterROI

import os, sys
from os import path
sys.path.append("/home2/data/Projects/CWAS/pyClusterROI")

# control mkl
import mkl
mkl.set_num_threads(15)


###
# 1. SETUP
###

print 'Setup'

obase = "/home2/data/Projects/CWAS/age+gender/01_resolution/spatial_cluster"
rbase = "/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution/rois"

# functions for group mean parcellation
from group_mean_binfile_parcellation import *

# Get number of voxels
import nibabel as nib
maskfile = path.join(rbase, "mask_4mm.nii.gz")
mask = nib.load(maskfile)
nvoxs = mask.get_data().sum()


###
# 2. Generate Individual Connectivity Matrices
###

print 'Gathering individual connectivity'

# Input connectivity
from glob import glob
scorr_conn_files = glob(path.join(obase, "scorr_conn_*.npy"))


###
# 3. Group-Mean Clustering
###

print 'Group-mean clustering'

# Breakdown of ROI numbers
ks = [25,50,100,200,400,800,1600,3200,6400]

# Output file
scorr_cluster_ofile = path.join(obase, "group_mean_scorr_cluster")

# Compute!
print 'Group-Mean and Parcellation'
group_mean_binfile_parcellate( scorr_conn_files, scorr_cluster_ofile, ks, nvoxs);

