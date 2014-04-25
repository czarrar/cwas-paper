#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path as op
import numpy as np
import nibabel as nib
from pandas import read_csv
from newsurf import *

from rpy2 import robjects
from rpy2.robjects.packages import importr

# Plot the following ROIs across scans
#         maxima     significant not-significant          minima 
#              5              28              53              64 

# 

base     = "/home/data/Projects/CWAS/nki/sca"
scans    = ["short", "medium", "long"]
strategy = "compcor"
rois     = [5,28,53,64]

maskfile = "/home/data/Projects/CWAS/nki/rois/mask_gray_2mm.nii.gz"
mask     = nib.load(maskfile).get_data().astype('bool')
inds     = np.where(mask)
nvoxs    = mask.sum()

outdir   = "/home2/data/Projects/CWAS/figures/fig_06"

roi_df   = read_csv("/home/data/Projects/CWAS/nki/sca/seeds/rois_all_info.csv")

# Select ROIs
#lh_roi_df = roi_df[roi_df.x < 0]
#roi_types = np.unique(roi_df.label)
#roi_inds  = dict.fromkeys(roi_types)
#for rtype in roi_types:
#    inds = lh_roi_df.ix[lh_roi_df.label == rtype,0].tolist()
#    np.random.shuffle(inds)
#    roi_inds[rtype] = inds[0]
roi_inds = {'maxima': 14, 'minima': 68, 'not-significant': 45, 'significant': 29}

for scan in scans:
    for rtype,roi in roi_inds.iteritems():
        print "%s: #%i" % (rtype, roi)
    
        # Try with one ROI and scan
        sinkdir     = op.join(base, "%s_%s_sink" % (scan, strategy))
        roidir      = op.join(sinkdir, "roi_n%02i" % roi)
        pos_zstat   = op.join(roidir, "stats/threshold", "thresh_zstat1.nii.gz")
        neg_zstat   = op.join(roidir, "stats/threshold", "thresh_zstat2.nii.gz")

        # 1. Vol => Surf
        pos_files, pos_surf = vol_to_surf(pos_zstat)
        neg_files, neg_surf = vol_to_surf(neg_zstat)
        
        remove_surfs(pos_files)
        remove_surfs(neg_files)
        
        # 2. Threshold...combine min and max
        pmin, pmax, psign = auto_minmax(pos_zstat)
        nmin, nmax, nsign = auto_minmax(neg_zstat)
        bmin = 1.96; bmax = max(pmax, nmax); bsign = 'pos'

        # 3. Coordinates for this ROI
        coords = roi_df.ix[roi-1,["x","y","z"]].tolist()

        # 4. Viz
        hemi = 'lh'
        brain = fsaverage(hemi)
        brain = add_overlay("pos-iq", brain, pos_surf[hemi], "Reds", bmin, bmax, bsign)
        brain = add_overlay("neg-iq", brain, neg_surf[hemi], "Blues", bmin, bmax, bsign)
        brain.add_foci(coords, map_surface="white", color="green", name="roi_n%02i" % roi)

        # 5. Save
        outprefix = op.join(outdir, "C_%s_%s_roi%02i_pysurfer" % (scan, rtype, roi))
        save_imageset(brain, outprefix, hemi)

        montage(outprefix, compilation='horiz_lh')
        montage(outprefix, compilation='vert_lh')


colorspace = importr('colorspace')
cols = np.array(robjects.r('rbind(col2rgb(rainbow_hcl(4, c=100, l=65, start=15)), rep(255, 4))'))
cols = cols.T/255

for hemi in ["lh", "rh"]:
    print "hemi: %s" % hemi
    brain = fsaverage(hemi)
    for i,rtype in enumerate(["maxima", "significant", "not-significant", "minima"]):
        coords = roi_df.ix[roi_df.label == rtype, ["x", "y", "z"]]
        brain.add_foci(coords, map_surface="white", color=cols[i,:], name="maxima")
    outprefix = op.join(outdir, "A_peaks_pysurfer")
    save_imageset(brain, outprefix, hemi)
montage(outprefix, compilation='horiz')
