#!/usr/bin/env python

# NOTE: color scale manually set to -3.1 to 3.1

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path as op
path = op
import numpy as np
import nibabel as nib
from newsurf import *


###
# Setup

strategy = "compcor"
scans = ["short", "medium"]
hemis = ["lh", "rh"]

study = "iq"



print "strategy: %s; scans: %s" % (strategy, ",".join(scans))

basedir = "/home2/data/Projects/CWAS/nki/cwas"

# Distance Directory
kstr = "kvoxs_fwhm08_to_kvoxs_fwhm08"
dirname = "%s_%s" % (strategy, kstr)
distdirs = [ path.join(basedir, scan, dirname) for scan in scans ]

# MDMR
mname = "iq_age+sex+meanFD.mdmr"
cname = "cluster_correct_v05_c05"
factor = "FSIQ"

# Input pfile

# Sfiles
mdmrdirs = [ path.join(distdir, mname) for distdir in distdirs ]
easydirs = [ path.join(mdmrdir, cname, "easythresh") for mdmrdir in mdmrdirs ]
sfiles  = [ path.join(easydir, "surfs/surf_thresh_zstat_%s" % factor) for easydir in easydirs ]
surf_files = {"scan1": ["%s_lh.nii.gz" % sfiles[0], "%s_rh.nii.gz" % sfiles[0]], 
              "scan2": ["%s_lh.nii.gz" % sfiles[1], "%s_rh.nii.gz" % sfiles[1]]}

# Output prefixes
obase = "/home2/data/Projects/CWAS/figures"
odir = path.join(obase, "fig_02")
if not path.exists(odir): os.mkdir(odir)
outdir = odir

###

###
# Get scan overlays

# Scan 1
print "scan1"
scan1_lh = (io.read_scalar_data(surf_files["scan1"][0])>0)*1
scan1_rh = (io.read_scalar_data(surf_files["scan1"][1])>0)*1
scan1 = {"lh": scan1_lh, "rh": scan1_rh}

# Scan 2
print "scan2"
scan2_lh = (io.read_scalar_data(surf_files["scan2"][0])>0)*1
scan2_rh = (io.read_scalar_data(surf_files["scan2"][1])>0)*1
scan2 = {"lh": scan2_lh, "rh": scan2_rh}

###


###
# Get Neurosynth

resdir      = "/home2/data/Projects/CWAS/results"
prefix      = op.join(resdir, "20_cwas_iq/12_iq_surface/30_neurosynth_iq_surf_thresh")
neurosynth  = { hemi : io.read_scalar_data("%s_%s.nii.gz" % (prefix, hemi)) for hemi in ["lh", "rh"] }

###


###
# Create (scan1 + scan2) * neurosynth

combined_lh = (scan1["lh"][:]+scan2["lh"][:]) * ((neurosynth["lh"][:]>0)*1)
combined_rh = (scan1["rh"][:]+scan2["rh"][:]) * ((neurosynth["rh"][:]>0)*1)
combined_lh = (combined_lh[:]>0)*1
combined_rh = (combined_rh[:]>0)*1
combined = {"lh": combined_lh, "rh": combined_rh}

###


###
# Surface Viz

measures = {"scan1": scan1, "scan2": scan2}

for scan,surf_data in measures.iteritems():
    print scan
    for hemi in hemis:
        print "hemi: %s" % hemi
        
        # Create overlap
        overlap = surf_data[hemi] * ((neurosynth[hemi][:]>0)*1)
        
        # Anatomical
        brain = fsaverage(hemi)
        
        # Color bars
        cbar_scan    = np.zeros((256,4))
        cbar_scan[:] = [217,11,0,255]
        
        cbar_neurosynth = np.zeros((256,4))
        cbar_neurosynth[:] = [0,61,204,255]
        
        cbar_overlap = np.zeros((256,4))
        cbar_overlap[:] = [85,142,40,255]
        
        # Viz Scan 1
        brain = add_overlay("scan", brain, surf_data[hemi], cbar_scan, 
                            1, 1, "pos")
        
        # Viz Neurosynth
        brain = add_overlay("neurosynth", brain, neurosynth[hemi], cbar_neurosynth, 
                            1, 1, "pos")
        
        # Viz Overlap
        brain = add_overlay("overlap", brain, overlap, cbar_overlap, 
                            1, 1, "pos")
        
        # Save
        outprefix = op.join(odir, "x_%s_n_neurosynth_surf" % scan)
        save_imageset(brain, outprefix, hemi)

    # Montage
    montage(outprefix, compilation='box')
    montage(outprefix, compilation='horiz')

###

###
# Combined Only

print "combined"
for hemi in hemis:
    print "hemi: %s" % hemi
        
    # Anatomical
    brain = fsaverage(hemi)
    
    # Color bars
    cbar    = np.zeros((256,4))
    cbar[:] = [85,142,40,255]
    
    # Viz
    brain = add_overlay("scan", brain, combined[hemi], cbar, 
                        1, 1, "pos")
    
    # Save
    outprefix = op.join(odir, "x_combined_overlap_surf")
    save_imageset(brain, outprefix, hemi)

# Montage
montage(outprefix, compilation='box')
montage(outprefix, compilation='horiz')

###
