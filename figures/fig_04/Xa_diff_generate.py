#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
from os import path as op
from surfwrap import SurfWrap, io
import numpy as np
import nibabel as nib
from newsurf import vol_to_surf, remove_surfs

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
pfiles1 = [ path.join(mdmrdir, cname, "easythresh", "zstat_%s.nii.gz" % factor) for mdmrdir in mdmrdirs ]


## WITH GLOBAL

# MDMR Directories
mname = "iq_age+sex+meanFD+meanGcor.mdmr"
cname = "cluster_correct_v05_c05"
factor = "FSIQ"

# Input pfile
mdmrdirs = [ path.join(distdir, mname) for distdir in distdirs ]
pfiles2 = [ path.join(mdmrdir, cname, "easythresh", "zstat_%s.nii.gz" % factor) for mdmrdir in mdmrdirs ]

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

pscans = [pfiles1, pfiles2]

for i,scan in enumerate(scans):
    
    tmpfiles, surf_no = vol_to_surf(pscans[i][0])
    remove_surfs(tmpfiles)
    
    tmpfiles, surf_yes = vol_to_surf(pscans[i][1])
    remove_surfs(tmpfiles)
    
    diff_lh = surf_no["lh"] - surf_yes["lh"]
    diff_rh = surf_no["rh"] - surf_yes["rh"]
        
    # Save
    outfile = op.join(odir, "difference_scan_%s.npz" % scan)
    np.savez(outfile, lh=diff_lh, rh=diff_rh)
    
    ###
    
    

###

