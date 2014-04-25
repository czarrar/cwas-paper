#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
import numpy as np
import nibabel as nib
from pandas import read_csv
from newsurf import *

from rpy2 import robjects
from rpy2.robjects.packages import importr


###
# Setup

strategy = "compcor"
scans = ["short", "medium"]
hemis = ["lh", "rh"]
cbarfile = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"
study = "iq"

roi_df   = read_csv("/home/data/Projects/CWAS/nki/sca/seeds/rois_all_info.csv")



print "strategy: %s; scans: %s" % (strategy, ",".join(scans))

basedir = "/home2/data/Projects/CWAS/nki/cwas"

# Distance Directory
kstr = "kvoxs_fwhm08_to_kvoxs_fwhm08"
dirname = "%s_%s" % (strategy, kstr)
distdirs = [ path.join(basedir, scan, dirname) for scan in scans ]

# MDMR
mname = "iq_age+sex+meanFD.mdmr"
cname = "cluster_correct_v05_c05"
factor = "FSIQ"

# Input pfile

# Sfiles
mdmrdirs = [ path.join(distdir, mname) for distdir in distdirs ]
easydirs = [ path.join(mdmrdir, cname, "easythresh") for mdmrdir in mdmrdirs ]
sfiles  = [ path.join(easydir, "surfs/surf_thresh_zstat_%s" % factor) for easydir in easydirs ]
surf_files = {"scan1": ["%s_lh.nii.gz" % sfiles[0], "%s_rh.nii.gz" % sfiles[0]], 
              "scan2": ["%s_lh.nii.gz" % sfiles[1], "%s_rh.nii.gz" % sfiles[1]]}

# Output prefixes
obase = "/home2/data/Projects/CWAS/results"
odir = path.join(obase, "50_mdmr_sca")
if not path.exists(odir): os.mkdir(odir)

###


###
# Get scan overlays

# Scan 1
print "scan1"
scan1_lh = io.read_scalar_data(surf_files["scan1"][0])
scan1_rh = io.read_scalar_data(surf_files["scan1"][1])

# Scan 2
print "scan2"
scan2_lh = io.read_scalar_data(surf_files["scan2"][0])
scan2_rh = io.read_scalar_data(surf_files["scan2"][1])

###


###
# Create overlap

overlap_lh = (scan1_lh[:]>0) * (scan2_lh[:]>0)
overlap_rh = (scan1_rh[:]>0) * (scan2_rh[:]>0)

###

###
# Plot overlap

# Color bar
cbar = load_colorbar(cbarfile)

# Colors for the peaks
colorspace = importr('colorspace')
cols = np.array(robjects.r('rbind(col2rgb(rainbow_hcl(4, c=100, l=65, start=15)), rep(255, 4))'))
cols = cols.T/255

# Input
surf_data = {"lh": scan2_lh, "rh": scan2_rh}


## Just maxima

# Output
oprefix = path.join(odir, "check_scan2_with_maxima")

# Loop
for hemi in hemis:
    print "hemi: %s" % hemi
    
    # Plot brain
    brain = fsaverage(hemi)
    
    # Plot activation maps
    brain = add_overlay(study, brain, surf_data[hemi], cbar, 
                        1, 2, "pos")
    
    # Only plot maxima
    ri = 0; rtype = "maxima"
    coords = roi_df.ix[roi_df.label == rtype, ["x", "y", "z"]]
    brain.add_foci(coords, map_surface="white", color=cols[ri,:], name=rtype)
    
    save_imageset(brain, oprefix, hemi)

montage(oprefix, compilation='box')
montage(oprefix, compilation='horiz')


## Just significant

# Output
oprefix = path.join(odir, "check_scan2_with_significant")

# Loop
for hemi in hemis:
    print "hemi: %s" % hemi
    
    # Plot brain
    brain = fsaverage(hemi)
    
    # Plot activation maps
    brain = add_overlay(study, brain, surf_data[hemi], cbar, 
                        1, 2, "pos")
    
    # Only plot significant
    ri = 1; rtype = "significant"
    coords = roi_df.ix[roi_df.label == rtype, ["x", "y", "z"]]
    brain.add_foci(coords, map_surface="white", color=cols[ri,:], name=rtype)
    
    save_imageset(brain, oprefix, hemi)

montage(oprefix, compilation='box')
montage(oprefix, compilation='horiz')
