#!/usr/bin/env python

"""
This script will plot IQ CWAS (scans 1 and 2), Neurosynth (Intelligence, Reasoning, and WM), and the Overlap.
"""

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

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
idir = op.join(base, "share/nki/compare_transformation")
odir = op.join(base, "share/nki/compare_transformation/images")

# fix_ => used 3dcalc to fix bad floats
p1 = op.join(idir, "nifti/fix_iq_logp_no_transform.nii.gz")
p2 = op.join(idir, "nifti/fix_iq_logp_yes_transform.nii.gz")
sp1 = op.join(idir, "nifti/fix_iq_thresh_logp_no_transform.nii.gz")
sp2 = op.join(idir, "nifti/fix_iq_thresh_logp_yes_transform.nii.gz")

cmd1 = "./x_vol2surf.py %s %s %s/surfs/no_transform" % (p1, sp1, idir)
run(cmd1)
cmd2 = "./x_vol2surf.py %s %s %s/surfs/yes_transform" % (p2, sp2, idir)
run(cmd2)


###
# Setup (Data)
###

prefixes = ["no", "yes"]

# paths to cwas
all_surf_files = {}
all_sfiles = []

for prefix in prefixes:
    all_surf_files[prefix] = {
        "lh": op.join(idir, "surfs/%s_transform_lh.nii.gz" % prefix), 
        "rh": op.join(idir, "surfs/%s_transform_rh.nii.gz" % prefix)
    }
    all_sfiles.extend(all_surf_files[prefix].values())


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
# Overlap
###

no = {}
yes = {}
combined = {}
for hemi in ["lh", "rh"]:
    no[hemi]        = io.read_scalar_data(all_surf_files["no"][hemi])
    yes[hemi]       = io.read_scalar_data(all_surf_files["yes"][hemi])
    combined[hemi]  = np.min(np.vstack((no[hemi], yes[hemi])), axis=0)



###
# Plot
###

# Overlap
oprefix     = op.join(odir, "surface_compare_transformation")
for hemi in ["lh","rh"]:    
    brain   = fsaverage(hemi)
    
    surfov  = no[hemi]
    brain   = add_overlay("overlap", brain, surfov, "Reds", 
                          dmin, dmax, "pos")
    
    surfov  = yes[hemi]
    brain   = add_overlay("overlap", brain, surfov, "Blues", 
                          dmin, dmax, "pos")
    
    surfov  = combined[hemi]
    brain   = add_overlay("overlap", brain, surfov, "Purples", 
                          dmin, dmax, "pos")
    
    save_imageset(brain, oprefix, hemi)
    
montage(oprefix, compilation='box')
montage(oprefix, compilation='horiz')
