#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path as op
import numpy as np
import nibabel as nib
from pandas import read_csv
from newsurf import *

from rpy2 import robjects
from rpy2.robjects.packages import importr

# Plots each of the applicability CWAS results
# ldopa, development+motion, adhd200_rerun

dirnames    = lambda paths: [ op.dirname(path) for path in paths ]
rjoins      = lambda paths,add_path: [ op.join(path, add_path) for path in paths ]
ljoins      = lambda add_path,paths: [ op.join(path, add_path) for path in paths ]

# General Variables
base     = "/home2/data/Projects/CWAS"
cbarfile = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"

# Input Paths
study       = "nki"
scan        = "short"
prefix      = op.join(base, study, "cwas", scan)
suffix      = "cluster_correct_v05_c05/easythresh/thresh_zstat_FSIQ.nii.gz"
subdist_subpaths = { "kvoxs_smoothed" : "compcor_kvoxs_smoothed_to_kvoxs_smoothed" }
mdmr_subpaths = { k : op.join(v, "iq_age+sex+meanFD.mdmr") for k,v in subdist_subpaths.iteritems() }
logp_paths    = { k : op.join(prefix, v, suffix) for k,v in mdmr_subpaths.iteritems() }

# Output Path
outdir   = op.join(base, "figures/sfig_roi_comparison")
if not op.exists(outdir): os.mkdir(outdir)

# Threshold...combine min and max
tmin = []; tmax = []
for name,logp_path in logp_paths.iteritems():
    lmin, lmax, _ = auto_minmax(logp_path)
    tmin.append(lmin); tmax.append(lmax)
min_use  = np.min(tmin)
max_use  = np.max(tmax)
sign_use = "pos" 
print "min: %.5f" % min_use
print "max: %.5f" % max_use

# Color bar
cbar = load_colorbar(cbarfile)

for name,logp_path in logp_paths.iteritems():
    # Vol => Surf
    logp_files, logp_surf = vol_to_surf(logp_path)
    remove_surfs(logp_files)
    
    for hemi in ["lh","rh"]:
        brain = fsaverage(hemi)
        # Viz
        brain = add_overlay(name, brain, logp_surf[hemi], cbar, 
                            min_use, max_use, sign_use)
        # Save
        outprefix = op.join(outdir, "A_%s_surf" % name)
        save_imageset(brain, outprefix, hemi)
    
    # Montage
    montage(outprefix, compilation='box')
    montage(outprefix, compilation='horiz')
    montage(outprefix, compilation='horiz_lh')
    montage(outprefix, compilation='horiz_rh')
