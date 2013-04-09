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
from make_local_connectivity_scorr import *

# name of the maskfile that we will be using
roidir = "/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution/rois"
maskfile = path.join(roidir, "mask_4mm.nii.gz")

# subject id and functional path
sid = int(sys.argv[2])
infile = sys.argv[3]


###
# 2. Generate Individual Connectivity Matrices
###

outfile = path.join(obase, "scorr_conn_%03i.npy" % sid)
make_local_connectivity_scorr( infile, maskfile, outfile, 0.5 )
