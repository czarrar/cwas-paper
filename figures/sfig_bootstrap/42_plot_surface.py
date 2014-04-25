#!/home2/data/PublicProgram/epd-7.2-2-rh5-x86_64/bin/python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
#from surfwrap import SurfWrap
import numpy as np
import nibabel as nib
from newsurf import *


###
# Setup

hemis = ["lh", "rh"]
cbarfile = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"

basedir = "/home2/data/Projects/CWAS/nki/bootstrap"

# Files
from glob import glob
sfiles = glob(path.join(basedir, "sample*_log_pvals.nii.gz"))

# Intermediate surface files
surfdir = path.join(basedir, "surfs")
if not path.exists(surfdir):
    os.mkdir(surfdir)

for i,sfile in enumerate(sfiles):
    # Threshold
    tfile = path.join(basedir, "thresh_" + path.basename(sfile))
    cmd = "fslmaths %s -thr 1.3 %s" % (sfile, tfile)
    print cmd
    os.system(cmd)
    
    # Surface
    cmd = "./x_vol2surf.py %s %s %s/surf_thresh_zstat_%s" % (sfile, tfile, surfdir, (i+1))
    print cmd
    os.system(cmd)

# I know silly sfile name before will be unused
sfiles = [ path.join(surfdir, "surf_thresh_zstat_%s" % (i+1)) for i,sfile in enumerate(sfiles) ]
all_sfiles = [] 
for sfile in sfiles:
    for hemi in hemis:
        all_sfiles.append("%s_%s.nii.gz" % (sfile, hemi))

# Output prefixes
obase = "/home2/data/Projects/CWAS/figures"
odir = path.join(obase, "sfig_bootstrap")
if not path.exists(odir): os.mkdir(odir)

###


###
# Get minimum and maximum values across the two scans
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


###
# Surface Viz

# Color bar
cbar = load_colorbar(cbarfile)

for i,sfile in enumerate(sfiles):
    print sfile
    oprefix = path.join(odir, "A_surface_%i" % (i+1))
    
    for hemi in hemis:
        surf_data = io.read_scalar_data("%s_%s.nii.gz" % (sfile, hemi))
        
        brain = fsaverage(hemi)
        brain = add_overlay(str(i+1), brain, surf_data, cbar, 
                            dmin, dmax, "pos")
        save_imageset(brain, oprefix, hemi)
    
    montage(oprefix, compilation='box')
    montage(oprefix, compilation='horiz')
    
###
