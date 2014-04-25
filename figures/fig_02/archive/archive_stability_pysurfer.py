#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
from surfwrap import SurfWrap
import numpy as np
import nibabel as nib


###
# Setup

basedir = "/home2/data/Projects/CWAS/nki/stability"
strategy = "compcor"
kstr = "kvoxs_smoothed_to_kvoxs_smoothed"
measures = ["scan_average_mean", "scan_average_sd", "scan_average_cv", "consistency"]

# Input Directory
indir = path.join(basedir, "%s_%s" % (strategy, kstr))

# Input Measure Files
infiles = [ path.join(indir, "%s.nii.gz" % measure) for measure in measures ]
if not path.exists(infiles[0]):
    raise Exception("infiles %s doesn't exist" % infiles[0])

# Output prefixes
obase = "/home2/data/Projects/CWAS/figures"
odir = path.join(obase, "fig_02")
if not path.exists(odir): os.mkdir(odir)

###


###
# Surface Viz

for i,infile in enumerate(infiles):
    print "%i: %s" % (i,infile)
    oprefix = path.join(odir, "A_surface_%s" % measures[i])
    sw = SurfWrap(name=measures[i], infile=infile, cbar="spectral-cb", 
                  outprefix=oprefix)
    sw.run(compilation="box")
    sw.montage(compilation="stick")
    print ''

###
