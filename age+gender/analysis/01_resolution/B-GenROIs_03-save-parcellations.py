#!/usr/bin/env python

# Create spatially constrained ROIs using Cameron's pyClusterROI

import os, sys
from os import path
sys.path.append("/home2/data/Projects/CWAS/pyClusterROI")

# control mkl
import mkl
mkl.set_num_threads(4)


###
# 1. SETUP
###

obase = "/home2/data/Projects/CWAS/age+gender/01_resolution/spatial_cluster"
rbase = "/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution/rois"

# functions to save to nifti
from make_image_from_bin_renum import *

# mask
maskfile = path.join(rbase, "mask_4mm.nii.gz")


###
# 2. Generate Individual Connectivity Matrices
###

# Done in 04*


###
# 3. Group-Mean Clustering
###

# Done in 05*


###
# 4. Convert binary output .npy files to nifti
###

ks = [25,50,100,200,400,800,1600,3200,6400]

for k in ks:
    print "\tk #%i" % k
    binfile = path.join(obase, "group_mean_scorr_cluster_%i.npy" % k)
    imgfile = path.join(rbase, "rois_k%04i.nii.gz" % k)
    make_image_from_bin_renum(imgfile, binfile, maskfile)
    

