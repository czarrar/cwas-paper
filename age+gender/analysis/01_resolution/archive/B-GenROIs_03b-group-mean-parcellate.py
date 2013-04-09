#!/usr/bin/env python

# Create spatially constrained ROIs using Cameron's pyClusterROI

import os, sys
from os import path
sys.path.append("/home2/data/Projects/CWAS/pyClusterROI")

# control mkl
import mkl
mkl.set_num_threads(int(sys.argv[1]))


###
# 1. SETUP
###

print 'Setup'

obase = "/home2/data/Projects/CWAS/age+gender/01_resolution/spatial_cluster"
rbase = "/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution/rois"

# functions for group mean parcellation
from group_mean_binfile_parcellation import *

# network to focus on
network_name = sys.argv[2]

# Get number of voxels
import nibabel as nib
roifile = path.join(rbase, "yeo_%s_3mm.nii.gz" % network_name)
roi = nib.load(roifile)
nvoxs = roi.get_data().sum()


###
# 2. Generate Individual Connectivity Matrices
###

print 'Gathering individual connectivity'

# Input connectivity
from glob import glob
scorr_conn_files = glob(path.join(obase, "scorr_conn_%s_*.npy" % network_name))


###
# 3. Group-Mean Clustering
###

print 'Group-mean clustering'

# Breakdown of ROI numbers
ks = [5,10,20,25,40,50,80,100,150,160,200,250,300,320,350,400,450,500,550,600,640]

# Output file
scorr_cluster_ofile = path.join(obase, "group_mean_scorr_cluster_%s" % network_name)

# Compute!
print 'Group-Mean and Parcellation'
group_mean_binfile_parcellate( scorr_conn_files, scorr_cluster_ofile, ks, nvoxs);

