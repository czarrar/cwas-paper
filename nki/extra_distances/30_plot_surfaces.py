#!/usr/bin/env python

"""
This script will plot IQ CWAS (scans 1 and 2), Neurosynth (Intelligence, Reasoning, and WM), and the Overlap.
"""

import sys
# This is needed for the _imaging package
sys.path.insert(0, '/home/data/PublicProgram/epd-7.2-2-rh5-x86_64/lib/python2.7/site-packages/PIL')
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")
sys.path.append("/home/data/PublicProgram/epd-7.2-2-rh5-x86_64/lib/python2.7/site-packages")

import os
import numpy as np
from surfer import io
from os import path as op
from newsurf import *


###
# Setup (General)
###

def run(cmd):
    print(cmd)
    os.system(cmd)

base = "/home2/data/Projects/CWAS"
idir = op.join(base, "share/nki/extra_distances")
odir = op.join(base, "nki/extra_distances")

scan = "short"
distbase = op.join(base, "nki/cwas", scan, "try_distances")

k = "0800"
measures = ["pearson", "spearman", "kendall", "concordance", 
            "euclidean", "chebyshev", "mahalanobis"]

###
# Setup (Data)
###

prefixes = ["no", "yes"]

# paths to cwas
all_surf_files = {}
all_sfiles = []

for measure in measures:
    # Base Directories
    mdmrdir = op.join(distbase, "%s_k%s_to_k%s" % (measure, k, k),  
                      "iq_age+sex+meanFD.mdmr")
    correctdir = op.join(mdmrdir, "cluster_correct_v05_c05", "easythresh")
    
    # Input Volume Files
    unthr = op.join(correctdir, "zstat_FSIQ.nii.gz")
    thr = op.join(correctdir, "thresh_zstat_FSIQ.nii.gz")
    
    # Generate Surface Files
    cmd = "./x_vol2surf.py %s %s %s/surfs/%s" % (unthr, thr, odir, measure)
    run(cmd)
    
    # Save Surface File Paths
    all_surf_files[measure] = {
        "lh": op.join(odir, "surfs/%s_lh.nii.gz" % measure), 
        "rh": op.join(odir, "surfs/%s_rh.nii.gz" % measure)
    }
    all_sfiles.extend(all_surf_files[measure].values())


###
# Get minimum and maximum values across the scans
def get_range(fname):
    img = nib.load(fname)
    data = img.get_data()
    data_max = data.max()
    if data_max == 0:
        data_min = data_max
    else:
        data_min = data[data.nonzero()].min()
    return [data_min, data_max]

print 'getting range'
ranges = np.array([ get_range(sfile) for sfile in all_sfiles ])
dmin = ranges.min()
dmax = ranges.max()
print 'min=%.4f; max=%.4f' % (dmin,dmax)



###
# Read surfaces
###

print "...reading surfaces"
surfs = {}
for measure in measures:
    surfs[measure] = {}
    for hemi in ["lh", "rh"]:
        tmp = io.read_scalar_data(all_surf_files[measure][hemi])
        surfs[measure][hemi] = tmp


###
# Plot
###

print "...plotting"

cbarfile = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"
cbar = load_colorbar(cbarfile)

# Overlap
for measure in measures:
    oprefix     = op.join(odir, "surf_%s" % measure)
    for hemi in ["lh","rh"]:
        brain   = fsaverage(hemi)
    
        surf    = surfs[measure][hemi]
        brain   = add_overlay("overlap", brain, surf, cbar, 
                              dmin, dmax, "pos")
        
        save_imageset(brain, oprefix, hemi)
    
    montage(oprefix, compilation='box')
    montage(oprefix, compilation='horiz')
