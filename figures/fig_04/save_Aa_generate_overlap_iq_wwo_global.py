#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
from os import path as op
from surfwrap import SurfWrap, io
import numpy as np
import nibabel as nib


###
# Setup

strategy = "compcor"
scans = ["short", "medium"]
hemis       = ["lh", "rh"]
study       = "iq"


print "strategy: %s; scans: %s" % (strategy, ",".join(scans))

basedir = "/home2/data/Projects/CWAS/nki/cwas"

# Output prefixes
obase = "/home2/data/Projects/CWAS/figures"
odir = path.join(obase, "fig_04")
if not path.exists(odir): os.mkdir(odir)

# Distance Directory
kstr = "kvoxs_fwhm08_to_kvoxs_fwhm08"
dirname = "%s_%s" % (strategy, kstr)
distdirs = [ path.join(basedir, scan, dirname) for scan in scans ]


## WITHOUT GLOBAL

# MDMR Directories
mname = "iq_age+sex+meanFD.mdmr"
cname = "cluster_correct_v05_c05"
factor = "FSIQ"

# Input pfile
mdmrdirs = [ path.join(distdir, mname) for distdir in distdirs ]
pfiles1 = [ path.join(mdmrdir, cname, "easythresh", "thresh_zstat_%s.nii.gz" % factor) for mdmrdir in mdmrdirs ]

# Intermediate surface files
easydirs = [ path.join(mdmrdir, cname, "easythresh") for mdmrdir in mdmrdirs ]
for easydir in easydirs:
    surfdir = path.join(easydir, "surfs")
    if not path.exists(surfdir):
        os.mkdir(surfdir)
    cmd = "./x_vol2surf.py %s/zstat_%s.nii.gz %s/thresh_zstat_%s.nii.gz %s/surf_thresh_zstat_%s" % (easydir, factor, easydir, factor, surfdir, factor)
    print cmd
    #os.system(cmd)
sfiles = [ path.join(easydir, "surfs/surf_thresh_zstat_%s" % factor) for easydir in easydirs ]
sfiles1 = {
    "short": { hemi : "%s_%s.nii.gz" % (sfiles[0], hemi) for hemi in hemis }, 
    "medium": { hemi : "%s_%s.nii.gz" % (sfiles[1], hemi) for hemi in hemis }, 
}


## WITH GLOBAL

# MDMR Directories
mname = "iq_age+sex+meanFD+meanGcor.mdmr"
cname = "cluster_correct_v05_c05"
factor = "FSIQ"

# Input pfile
mdmrdirs = [ path.join(distdir, mname) for distdir in distdirs ]
pfiles2 = [ path.join(mdmrdir, cname, "easythresh", "thresh_zstat_%s.nii.gz" % factor) for mdmrdir in mdmrdirs ]

# Intermediate surface files
easydirs = [ path.join(mdmrdir, cname, "easythresh") for mdmrdir in mdmrdirs ]
for easydir in easydirs:
    surfdir = path.join(easydir, "surfs")
    if not path.exists(surfdir):
        os.mkdir(surfdir)
    cmd = "./x_vol2surf.py %s/zstat_%s.nii.gz %s/thresh_zstat_%s.nii.gz %s/surf_thresh_zstat_%s" % (easydir, factor, easydir, factor, surfdir, factor)
    print cmd
    #os.system(cmd)
sfiles = [ path.join(easydir, "surfs/surf_thresh_zstat_%s" % factor) for easydir in easydirs ]
sfiles2 = {
    "short": { hemi : "%s_%s.nii.gz" % (sfiles[0], hemi) for hemi in hemis }, 
    "medium": { hemi : "%s_%s.nii.gz" % (sfiles[1], hemi) for hemi in hemis }, 
}


###


###
# Overlap

print "...overlap"

def get_range(data):
    data_max = data.max()
    if data_max == 0:
        data_min = data_max
    else:
        data_min = data[data.nonzero()].min()
    return [data_min, data_max]


print "...loop through scans"

for i,scan in enumerate(scans):
    ###
    # Get individual percentile maps
    
    print "individual data maps"
    
    # MDMR w/o
    mdmr1_lh = io.read_scalar_data(sfiles1[scan]['lh'])
    mdmr1_rh = io.read_scalar_data(sfiles1[scan]['rh'])
    
    # MDMR w/
    mdmr2_lh = io.read_scalar_data(sfiles2[scan]['lh'])
    mdmr2_rh = io.read_scalar_data(sfiles2[scan]['rh'])
    
    ###
    
    
    ###
    # Create overlap

    print "creating and saving overlap"

    # Threshold MDMR w/o global
    mdmr1_lh[mdmr1_lh.nonzero()] = 1
    mdmr1_rh[mdmr1_rh.nonzero()] = 1

    # Threshold MDMR w/ global
    mdmr2_lh[mdmr2_lh.nonzero()] = 2
    mdmr2_rh[mdmr2_rh.nonzero()] = 2
    
    # Overlap
    overlap_lh = mdmr1_lh[:] + mdmr2_lh[:]
    overlap_rh = mdmr1_rh[:] + mdmr2_rh[:]
    
    # Save
    outfile = op.join(odir, "overlaps_scan_%s.npz" % scan)
    np.savez(outfile, lh=overlap_lh, rh=overlap_rh)
    
    ###
    
    

###

