#!/home2/data/PublicProgram/epd-7.2-2-rh5-x86_64/bin/python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path as op
path = op
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
hemis = ["lh", "rh"]
cbarfile = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"

# Input Paths
study       = "development+motion"
prefix      = op.join(base, study, "cwas")
cname       = "cluster_correct_v05_c05"
suffix      = "cluster_correct_v05_c05/easythresh/thresh_zstat_mean_FD.nii.gz"
mdmr_subpaths = {
    "compcor_age+motion": "compcor_kvoxs_smoothed/age+motion_sex+tr.mdmr", 
    "global_age+motion": "global_kvoxs_smoothed/age+motion_sex+tr.mdmr", 
    "compcor_age+motion+gcor": "compcor_kvoxs_smoothed/age+motion_sex+tr+meanGcor.mdmr"
}
mdmrdirs    = { k : op.join(prefix, v) for k,v in mdmr_subpaths.iteritems() }
logp_paths  = { k : op.join(prefix, v, suffix) for k,v in mdmr_subpaths.iteritems() }
names       = mdmrdirs.keys()

# Output Path
outdir   = op.join(base, "figures/sfig_motion")
if not op.exists(outdir): os.mkdir(outdir)

# Intermediate surface files
easydirs = { k : path.join(mdmrdir, cname, "easythresh") for k,mdmrdir in mdmrdirs.iteritems() }
for k,easydir in easydirs.iteritems():
    print easydir
    surfdir = path.join(easydir, "surfs")
    if not path.exists(surfdir):
        os.mkdir(surfdir)
    cmd = "./x_vol2surf.py %s/zstat_mean_FD.nii.gz %s/thresh_zstat_mean_FD.nii.gz %s/surf_thresh_zstat_mean_FD" % (easydir, easydir,  surfdir)
    print cmd
    os.system(cmd)
sfiles = [ path.join(easydir, "surfs/surf_thresh_zstat_mean_FD") for k,easydir in easydirs.iteritems() ]
all_sfiles = []
for sfile in sfiles:
    for hemi in hemis:
        all_sfiles.append("%s_%s.nii.gz" % (sfile, hemi))

# Output prefixes
odir = outdir

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

for i,sfile in enumerate(sfiles):
    print sfile
    name = names[i]
    oprefix = path.join(odir, "A_%s_pysurfer" % name)
    
    for hemi in hemis:
        surf_data = io.read_scalar_data("%s_%s.nii.gz" % (sfile, hemi))
        
        brain = fsaverage(hemi)
        brain = add_overlay(study, brain, surf_data, cbar, 
                            min_use, max_use, "pos")
        save_imageset(brain, oprefix, hemi)
    
    montage(oprefix, compilation='box')
    montage(oprefix, compilation='horiz')
    montage(oprefix, compilation='horiz_lh')
