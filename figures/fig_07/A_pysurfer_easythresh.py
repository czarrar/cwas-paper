#!/home2/data/PublicProgram/epd-7.2-2-rh5-x86_64/bin/python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path as op
from os import path
import numpy as np
import nibabel as nib
from pandas import read_csv
from newsurf import *

from rpy2 import robjects
from rpy2.robjects.packages import importr

# Plots each of the applicability CWAS results
# ldopa, development+motion, adhd200_rerun

# General Variables
studies  = ["development+motion", "adhd200_rerun", "ldopa"]
base     = "/home2/data/Projects/CWAS"
cbarfile = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"
hemis    = ["lh","rh"]

# Input Paths
interm      = "cwas/compcor_kvoxs_smoothed"
clterm      = "cluster_correct_v05_c05/easythresh"
mdmr_paths  = [
    op.join(base, "development+motion", interm, "age+motion_sex+tr.mdmr"), 
    op.join(base, "adhd200_rerun", interm, "adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr"), 
    op.join(base, "ldopa", interm, "ldopa_subjects+meanFD.mdmr")
]
easy_paths = [
    op.join(mdmr_paths[0], clterm), 
    op.join(mdmr_paths[1], clterm), 
    op.join(mdmr_paths[2], clterm), 
]

# Input file suffix
suffix_names = [ "age", "diagnosis", "conditions" ]

# Output Path
outdir   = op.join(base, "figures/fig_07")
if not op.exists(outdir): os.mkdir(outdir)

# Threshold...combine min and max
tmin = []; tmax = []
for i,study in enumerate(studies):
    logp_path  = "%s/thresh_zstat_%s.nii.gz" % (easy_paths[i], suffix_names[i])
    lmin, lmax, _ = auto_minmax(logp_path)
    tmin.append(lmin); tmax.append(lmax)
min_use  = np.min(tmin)
max_use  = np.max(tmax)
sign_use = "pos" 
print "min: %.5f" % min_use
print "max: %.5f" % max_use

# Color bar
cbar = load_colorbar(cbarfile)

for i,study in enumerate(studies):    
    # Generate the surface image
    ## base directory
    surfdir = path.join(easy_paths[i], "surfs")
    if not path.exists(surfdir):
        os.mkdir(surfdir)
    ## create it
    cmd = "./x_vol2surf.py %s/zstat_%s.nii.gz %s/thresh_zstat_%s.nii.gz %s/surf_thresh_zstat_%s" % (easy_paths[i], suffix_names[i], easy_paths[i], suffix_names[i], surfdir, suffix_names[i])
    print cmd
    os.system(cmd)
    ## collate them
    logp_files = { hemi : path.join(surfdir, "surf_thresh_zstat_%s_%s.nii.gz" % (suffix_names[i], hemi)) for hemi in hemis }
    ## read them
    logp_surfs = { hemi : io.read_scalar_data(logp_files[hemi]) for hemi in hemis }
    
    # Viz
    for hemi in hemis:
        brain = fsaverage(hemi)
        # Viz
        brain = add_overlay(study, brain, logp_surfs[hemi], cbar, 
                            min_use, max_use, sign_use)
        # Save
        outprefix = op.join(outdir, "A_%s_pysurfer" % study)
        save_imageset(brain, outprefix, hemi)
    
    # Montage
    montage(outprefix, compilation='box')
    montage(outprefix, compilation='horiz')
