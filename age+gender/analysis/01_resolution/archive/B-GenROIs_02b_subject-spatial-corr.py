#!/usr/bin/env python

import os, sys
from os import path
sys.path.append("/home2/data/Projects/CWAS/pyClusterROI")

if len(sys.argv) != 4:
    sys.exit("Usage: %s num-threads subject-id input-functional" % sys.argv[0])

# control mkl
import mkl
mkl.set_num_threads(int(sys.argv[1]))


###
# 1. SETUP
###

obase = "/home2/data/Projects/CWAS/age+gender/01_resolution/spatial_cluster"

# functions for connectivity metric
from make_local_roi_connectivity_scorr import *

# name of the maskfile that we will be using
roidir = "/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution/rois"
maskfile = path.join(roidir, "mask.nii.gz")

# subject id and functional path
sid = int(sys.argv[2])
infile = sys.argv[3]


###
# 2. Generate Individual Connectivity Matrices
###

network_names = ["visual", "somatomotor", "dorsal_attention", 
                 "ventral_attention", "limbic", "frontoparietal", 
                 "default"]

# Loop through each network
for name in network_names:
    print "network: %s" % name
    roifile = path.join(roidir, "yeo_%s_3mm.nii.gz" % name)
    outfile = path.join(obase, "scorr_conn_%s_%03i.npy" % (name, sid))
    make_local_roi_connectivity_scorr( infile, roifile, maskfile, outfile, 0.5 )
    
