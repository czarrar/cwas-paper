#!/home2/data/PublicProgram/epd-7.2-2-rh5-x86_64/bin/python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
import numpy as np
import nibabel as nib
from newsurf import *

dirnames    = lambda paths: [ op.dirname(path) for path in paths ]
rjoins      = lambda paths,add_path: [ op.join(path, add_path) for path in paths ]
ljoins      = lambda add_path,paths: [ op.join(path, add_path) for path in paths ]

# General Variables
base     = "/home2/data/Projects/CWAS"
cbarfile = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"
hemis = ["lh", "rh"]

# Input Paths
factor      = "FSIQ"
study       = "nki"
scan        = "short"
prefix      = op.join(base, study, "cwas", scan)
suffix      = "cluster_correct_v05_c05/easythresh"
ks          = [25, 50, 100, 200, 400, 800, 1600, 3200, 6400]
subdist_subpaths = { ("only_k%04i" % k) : ("compcor_only_rois_random_k%04i" % k) for k in ks }
subdist_subpaths["voxelwise"] = "compcor_kvoxs_fwhm08_to_kvoxs_fwhm08"
mdmr_subpaths = { k : op.join(v, "iq_age+sex+meanFD.mdmr") for k,v in subdist_subpaths.iteritems() }
easy_subpaths = { k : op.join(v, suffix) for k,v in mdmr_subpaths.iteritems() }
easy_paths = { k : op.join(prefix, v) for k,v in easy_subpaths.iteritems() }

# Output Path
outdir   = op.join(base, "figures/sfig_roi_comparison")
if not op.exists(outdir): os.mkdir(outdir)

###
# To the surface!

for k,easydir in easy_paths.iteritems():
    cmd = "./x_vol2surf.py %s %s" % (easydir, factor)
    print cmd
    os.system(cmd)

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

# Gets list of files
sfiles = [ path.join(easydir, "surf_thresh_zstat_%s" % factor) for k,easydir in easy_paths.iteritems() ]
all_sfiles = [] 
for sfile in sfiles:
    for hemi in hemis:
        all_sfiles.append("%s_%s.nii.gz" % (sfile, hemi))

print 'getting range'
ranges = np.array([ get_range(sfile) for sfile in all_sfiles ])
dmin = ranges[ranges.nonzero()].min()
dmax = ranges[ranges.nonzero()].max()
print 'min=%.4f; max=%.4f' % (dmin,dmax)

###

###
# Viz

# Color bar
cbar = load_colorbar(cbarfile)

for k,easydir in easy_paths.iteritems():
    print k
    oprefix = path.join(outdir, "C_%s_%s_%s_easythresh_surface" % ("iq", scan, k))
    
    for hemi in hemis:
        surf_file = "%s/surf_thresh_zstat_%s_%s.nii.gz" % (easydir, factor, hemi)
        surf_data = io.read_scalar_data(surf_file)
        
        brain = fsaverage(hemi)
        brain = add_overlay(k, brain, surf_data, cbar, 
                            dmin, dmax, "pos")
        save_imageset(brain, oprefix, hemi)

    montage(oprefix, compilation='box')
    montage(oprefix, compilation='horiz_lh')
    montage(oprefix, compilation='horiz_rh')
        

###
