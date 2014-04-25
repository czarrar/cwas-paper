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

strategy    = "compcor"
scans       = ["short", "medium"]
hemis       = ["lh", "rh"]
cbarfile    = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"
study       = "meanGcor"


print "strategy: %s; scans: %s" % (strategy, ",".join(scans))

basedir = "/home2/data/Projects/CWAS/nki/cwas"

# Distance Directory
kstr = "kvoxs_fwhm08_to_kvoxs_fwhm08"
dirname = "%s_%s" % (strategy, kstr)
distdirs = [ path.join(basedir, scan, dirname) for scan in scans ]

# MDMR Directories
mname = "meanGcor_iq+age+sex+meanFD.mdmr"
cname = "cluster_correct_v05_c05"
factor = "meanGcor"

# Input pfile
from glob import glob
mdmrdirs = [ path.join(distdir, mname) for distdir in distdirs ]
#print mdmrdirs
#tmp = [ path.join(mdmrdir, cname, "easythresh", "thresh_zstat_*_%s.nii.gz" % factor) for mdmrdir in mdmrdirs ]
#print tmp
pfiles = [ glob(path.join(mdmrdir, cname, "easythresh", "thresh_zstat_*_%s.nii.gz" % factor))[0] for mdmrdir in mdmrdirs ]
print pfiles

# Intermediate surface files
easydirs = [ path.join(mdmrdir, cname, "easythresh") for mdmrdir in mdmrdirs ]
for i,easydir in enumerate(easydirs):
    surfdir = path.join(easydir, "surfs")
    if not path.exists(surfdir):
        os.mkdir(surfdir)
    cmd = "./x_vol2surf.py %s/zstat_%s_%s.nii.gz %s/thresh_zstat_%s_%s.nii.gz %s/surf_thresh_zstat_%s" % (easydir, scans[i], factor, easydir, scans[i], factor, surfdir, factor)
    print cmd
    os.system(cmd)
sfiles = [ path.join(easydir, "surfs/surf_thresh_zstat_%s" % factor) for easydir in easydirs ]
sfiles0 = {
    "short": { hemi : "%s_%s.nii.gz" % (sfiles[0], hemi) for hemi in hemis }, 
    "medium": { hemi : "%s_%s.nii.gz" % (sfiles[1], hemi) for hemi in hemis }, 
}
all_sfiles = [ sfiles0[scan][hemi] for hemi in hemis for scan in scans ]


# Output prefixes
obase = "/home2/data/Projects/CWAS/figures"
odir = path.join(obase, "fig_04")
if not path.exists(odir): os.mkdir(odir)

###


###
# Get minimum and maximum values across the two scans

def get_range(fname):
    data = io.read_scalar_data(fname)
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

for i,scan in enumerate(scans):
    print scan
    oprefix = path.join(odir, "B_global_easythresh_surface_scan%i" % (i+1))
    
    for hemi in hemis:
        surf_data = io.read_scalar_data(sfiles0[scan][hemi])
        
        brain = fsaverage(hemi)
        brain = add_overlay(study, brain, surf_data, cbar, 
                            dmin, dmax, "pos")
        save_imageset(brain, oprefix, hemi)
    
    montage(oprefix, compilation='box')
    montage(oprefix, compilation='horiz')
    
###

