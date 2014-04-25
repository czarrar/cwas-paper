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

scan_luts = []

# Scan 1
over_lut            = np.zeros((256,4))
over_lut[:85,:3]    = [253,34,29]
over_lut[85:170,:3] = [24,50,225]
over_lut[170:,:3]   = [123,70,154]
over_lut[:,3]       = 255
scan_luts.append(over_lut)

# Scan 2
over_lut            = np.zeros((256,4))
over_lut[:85,:3]    = [255,0,0]
over_lut[85:170,:3] = [0,255,0]
over_lut[170:,:3]   = [255,255,0]
over_lut[:,3]       = 255
scan_luts.append(over_lut)


###
# Setup

strategy    = "compcor"
hemis       = ["lh", "rh"]
cbarfile    = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"
scans       = ["short", "medium"]


print "strategy: %s; scans: %s" % (strategy, ",".join(scans))

basedir = "/home2/data/Projects/CWAS/nki/cwas"

# Output prefixes
obase = "/home2/data/Projects/CWAS/figures"
odir = op.join(obase, "fig_04")
if not op.exists(odir): os.mkdir(odir)

###


###
# Loop through scans

for i,scan in enumerate(scans):
    infile = op.join(odir, "overlaps_scan_%s.npz" % scan)
    npzfile = np.load(infile)
    overlap_lh = npzfile['lh']
    overlap_rh = npzfile['rh']
    surf_data  = {"lh": overlap_lh, "rh": overlap_rh}
    
    ###
    # Plot overlap
    
    # Color bar
    cbar = load_colorbar(cbarfile)
    
    # Output
    oprefix = path.join(odir, "A_surface_scan%i_overlap_iq_wwo_global" % (i+1))
    
    # Range
    dmin = 1; dmax = 3
    
    for hemi in hemis:    
        brain = fsaverage(hemi)
        brain = add_overlay(scan, brain, surf_data[hemi], scan_luts[i], 
                            dmin, dmax, "pos")
        import code
        code.interact(local=locals())
        sys.exit(2)
        save_imageset(brain, oprefix, hemi)

    montage(oprefix, compilation='box')
    montage(oprefix, compilation='horiz')
    
    ###
    
###
