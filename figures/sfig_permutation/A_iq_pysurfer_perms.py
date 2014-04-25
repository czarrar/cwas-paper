#!/home2/data/PublicProgram/epd-7.2-2-rh5-x86_64/bin/python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
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

# MDMR Directories
mname  = "iq_age+sex+meanFD.mdmr"
cname  = "cluster_correct_v05_c05"
factor = "FSIQ"

# Input pfile
mdmrdirs = [ path.join(distdir, mname) for distdir in distdirs ]
pfiles   = [ path.join(mdmrdir, cname, "clust_logp_%s.nii.gz" % factor) for mdmrdir in mdmrdirs ]

# Intermediate surface files
easydirs = [ path.join(mdmrdir, cname) for mdmrdir in mdmrdirs ]
for i,easydir in enumerate(easydirs):
    surfdir = path.join(easydir, "surfs")
    if not path.exists(surfdir):
        os.mkdir(surfdir)
    cmd = "./x_vol2surf.py %s/logp_%s.nii.gz %s/clust_logp_%s.nii.gz %s/surf_clust_logp_%s" % (easydir, factor, easydir, factor, surfdir, factor)
    print cmd
    os.system(cmd)
sfiles = [ path.join(easydir, "surfs/surf_clust_logp_%s" % factor) for easydir in easydirs ]
all_sfiles = [] 
for sfile in sfiles:
    for hemi in hemis:
        all_sfiles.append("%s_%s.nii.gz" % (sfile, hemi))

# Output prefixes
obase = "/home2/data/Projects/CWAS/figures"
odir = path.join(obase, "sfig_permutations")
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
    oprefix = path.join(odir, "A_iq_scan%i_surface_perms" % (i+1))
    
    for hemi in hemis:
        surf_data = io.read_scalar_data("%s_%s.nii.gz" % (sfile, hemi))
        
        brain = fsaverage(hemi)
        brain = add_overlay(study, brain, surf_data, cbar, 
                            dmin, dmax, "pos")
        save_imageset(brain, oprefix, hemi)
    
    montage(oprefix, compilation='box')
    montage(oprefix, compilation='horiz')
    
###
