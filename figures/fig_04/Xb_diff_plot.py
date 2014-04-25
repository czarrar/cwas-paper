#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path as op
from os import path
#from surfwrap import SurfWrap, io, Brain
from newsurf import *
import numpy as np
import nibabel as nib


###
# Setup

strategy    = "compcor"
hemis       = ["lh", "rh"]
cbarfile    = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/spectral-reduced-cb.txt"
scans       = ["short", "medium"]


print "strategy: %s; scans: %s" % (strategy, ",".join(scans))

basedir = "/home2/data/Projects/CWAS/nki/cwas"

# Output prefixes
obase = "/home2/data/Projects/CWAS/figures"
odir = op.join(obase, "fig_04")
if not op.exists(odir): os.mkdir(odir)

###

maxes = []
mines = []
for i,scan in enumerate(scans):
    infile = op.join(odir, "difference_scan_%s.npz" % scan)
    npzfile = np.load(infile)
    overlap_lh = npzfile['lh']
    overlap_rh = npzfile['rh']
    maxes.append(overlap_lh.max())
    maxes.append(overlap_rh.max())
    mines.append(overlap_lh.min())
    mines.append(overlap_rh.min())
dmax = np.array(maxes).max()
dmin = np.array(mines).min()

import code
code.interact(local=locals())


###
# Loop through scans

for i,scan in enumerate(scans):
    infile = op.join(odir, "difference_scan_%s.npz" % scan)
    npzfile = np.load(infile)
    overlap_lh = npzfile['lh']
    overlap_rh = npzfile['rh']
    surf_data  = {"lh": overlap_lh, "rh": overlap_rh}
    
    ###
    # Plot overlap
    
    # Color bar
    cbar = load_colorbar(cbarfile)
    
    # Output
    oprefix = path.join(odir, "x_surface_scan%i_difference_iq_wwo_global" % (i+1))
    
    for hemi in hemis:    
        brain = fsaverage(hemi)
        brain = add_overlay(scan, brain, surf_data[hemi] - dmin, cbar, 0.001, dmax - dmin, "pos")
        save_imageset(brain, oprefix, hemi)

    montage(oprefix, compilation='box')
    montage(oprefix, compilation='horiz')
    
    ###
    
###
