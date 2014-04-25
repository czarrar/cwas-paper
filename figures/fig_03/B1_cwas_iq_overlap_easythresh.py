#!/home2/data/PublicProgram/epd-7.2-2-rh5-x86_64/bin/python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
#from surfwrap import Brain, io, SurfWrap
import numpy as np
import nibabel as nib
from newsurf import *


###
# Setup

strategy = "compcor"
scans = ["short", "medium"]
hemis = ["lh", "rh"]
cbarfile = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"
study = "iq"



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
obase = "/home2/data/Projects/CWAS/figures"
odir = path.join(obase, "fig_03")
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

oprefix = path.join(odir, "D_easythresh_surface_overlap")

surf_data = {"lh": overlap_lh, "rh": overlap_rh}
for hemi in hemis:
    brain = fsaverage(hemi)
    brain = add_overlay(study, brain, surf_data[hemi], cbar, 
                        1, 2, "pos")
    save_imageset(brain, oprefix, hemi)

montage(oprefix, compilation='box')
montage(oprefix, compilation='horiz')

