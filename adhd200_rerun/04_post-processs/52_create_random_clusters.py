#!/usr/bin/env python

import os, sys
from os import path
sys.path.append("/home2/data/Projects/CWAS/pyClusterROI")

if len(sys.argv) != 2:
    sys.exit("Usage: %s num-threads" % sys.argv[0])

# control mkl
import mkl
mkl.set_num_threads(int(sys.argv[1]))


###
# 1. SETUP
###

print "1. Setup"

obase = "/home2/data/Projects/CWAS/adhd200_rerun/spatial_cluster"

# functions for connectivity metric
from make_local_connectivity_ones import *

# name of the maskfile that we will be using
roidir = "/home2/data/Projects/CWAS/adhd200_rerun/rois"
maskfile = path.join(roidir, "mask_gray_4mm_combined.nii.gz")


###
# 2. Generate Random Connectivity Matrix
###

print "2. Random Connectivity Matrix"

outfile = path.join(obase, "random_ones_conn.npy")
make_local_connectivity_ones(maskfile, outfile)


###
# 3. 'Clustering'
###

print "3. Clustering"

from binfile_parcellation import *

ks = [25,50,100,200,400,800,1600,3200]

# For random custering, this is all we need to do, there is no need for group
# level clustering, remember that the output filename is a prefix, and 
infile = outfile
outbase = path.join(obase, "random_ones_cluster")
binfile_parcellate(infile, outbase, ks)


###
# 4. Save
###

print "4. Save"

from make_image_from_bin_renum import *

for k in ks:
    print "\tk #%i" % k
    binfile = path.join(obase, "random_ones_cluster_%i.npy" % k)
    imgfile = path.join(roidir, "rois_random_k%04i_combined.nii.gz" % k)
    make_image_from_bin_renum(imgfile, binfile, maskfile)
 

