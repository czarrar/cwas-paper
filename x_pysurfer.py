#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path as op
path = op
import numpy as np
import nibabel as nib
from pandas import *
from newsurf import *


# Input Paths (SET THESE)
odir    = "XXX"
names   = ["name"]
infiles = ["XXX"]

# Color bar
cbarfile    = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/spectral-reduced-cb.txt"
cbar        = load_colorbar(cbarfile)

# Threshold...combine min and max
tmin = []; tmax = []
for infile in infiles:
    lmin, lmax, _ = auto_minmax(infile)
    tmin.append(lmin); tmax.append(lmax)
min_use  = np.min(tmin)
max_use  = np.max(tmax)
sign_use = "pos"
print "min: %.5f" % min_use
print "max: %.5f" % max_use

# Plot
for i,infile in enumerate(infiles):
    print "%i: %s" % (i,infile)
    name = names[i]
    
    # Vol => Surf
    surf_files, surf_data = vol_to_surf(infile)
    remove_surfs(surf_files)
        
    for hemi in ["lh","rh"]:
        brain = fsaverage(hemi)
        
        ## make data be only positive (ignore vertices without data)
        #nz_inds = surf_data[hemi].nonzero()
        #dat = surf_data[hemi][nz_inds]
        #surf_data[hemi][nz_inds] = dat - manual_min
        
        # Viz
        # adjust min a bit to ignore vertices without data (=0)
        brain = add_overlay(name, brain, surf_data[hemi], cbar, 
                            min_use, max_use, sign_use)
        
        # Save
        outprefix = op.join(odir, "%s_surf" % name)
        save_imageset(brain, outprefix, hemi)
    
    # Montage
    montage(outprefix, compilation='box')
    montage(outprefix, compilation='horiz')

