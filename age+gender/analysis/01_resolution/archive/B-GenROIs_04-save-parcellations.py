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

ks = [5,10,20,25,40,50,80,100,150,160,200,250,300,320,350,400,450,500,
        550,600,640]

network_names = ["visual", "somatomotor", "dorsal_attention", 
                 "ventral_attention", "limbic", "frontoparietal", 
                 "default"]

for network in network_names:
    print "Network: %s" % network
    for k in ks:
        print "\tk #%i" % k
        binfile = path.join(obase, 
                    "group_mean_scorr_cluster_%s_%i.npy" % (network, k))
        imgfile = path.join(obase, 
                    "group_mean_scorr_cluster_%s_%i.nii.gz" % (network, k))
        roifile = path.join(rbase, 
                    "yeo_%s_3mm.nii.gz" % network)
        make_image_from_bin_renum(imgfile, binfile, roifile)

