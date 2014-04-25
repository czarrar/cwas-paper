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

from rpy2 import robjects
from rpy2.robjects.packages import importr


###
# Setup

basedir = "/home2/data/Projects/CWAS/nki/stability"
strategy = "N104_compcor"
kstr = "kvoxs_fwhm08_to_kvoxs_fwhm08"
measures = ["mean_short", "mean_medium", "sd_short", "sd_medium", "cv_short", "cv_medium", "consistency"]

cbarfile = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/spectral-reduced-cb.txt"

# Input Directory
indir = path.join(basedir, "%s_%s" % (strategy, kstr))

# Input Measure Files
infiles = [ path.join(indir, "%s_zscore.nii.gz" % measure) for measure in measures ]
if not path.exists(infiles[0]):
    raise Exception("infiles %s doesn't exist" % infiles[0])

# Output prefixes
obase = "/home2/data/Projects/CWAS/figures"
odir = path.join(obase, "fig_02")
if not path.exists(odir): os.mkdir(odir)

###

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
# write this down
## 
tmin.append(min_use)
tmax.append(max_use)
labels = measures[:]
labels.append("total")
df = DataFrame({'labels': labels, 'min': tmin, 'max': tmax})
df.to_csv(path.join(odir, "00_value_ranges_zscores.csv"))
import sys
sys.exit()

# Adjust to be all positive
cur_min_use = min_use - min_use
cur_max_use = max_use - min_use

# Color bar
cbar = load_colorbar(cbarfile)


###
# Surface Viz

for i,infile in enumerate(infiles):
    print "%i: %s" % (i,infile)
    name = measures[i]
    
    # Vol => Surf
    surf_files, surf_data = vol_to_surf(infile)
    remove_surfs(surf_files)
        
    for hemi in ["lh","rh"]:
        brain = fsaverage(hemi)
        
        # make data be only positive (ignore vertices without data)
        nz_inds = surf_data[hemi].nonzero()
        surf_data[hemi][nz_inds] = surf_data[hemi][nz_inds] - min_use
        
        # Viz
        # adjust min a bit to ignore vertices without data (=0)
        brain = add_overlay(name, brain, surf_data[hemi], cbar, 
                            cur_min_use+0.001, cur_max_use, sign_use)
        
        # Save
        outprefix = op.join(odir, "A_%s_zscore_surf" % name)
        save_imageset(brain, outprefix, hemi)
    
    # Montage
    montage(outprefix, compilation='box')
    montage(outprefix, compilation='horiz')

###
