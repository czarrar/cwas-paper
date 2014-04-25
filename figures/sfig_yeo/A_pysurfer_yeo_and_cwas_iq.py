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
odir = path.join(obase, "fig_03")
if not path.exists(odir): os.mkdir(odir)

###


###
# Get scan overlays

# Scan 1
print "scan1"
scan1_lh = io.read_scalar_data(surf_files["scan1"][0])
scan1_rh = io.read_scalar_data(surf_files["scan1"][1])

# Scan 2
print "scan2"
scan2_lh = io.read_scalar_data(surf_files["scan2"][0])
scan2_rh = io.read_scalar_data(surf_files["scan2"][1])

###


###
# Create overlap

overlap_lh = (scan1_lh[:]>0) * (scan2_lh[:]>0)
overlap_rh = (scan1_rh[:]>0) * (scan2_rh[:]>0)

surf_data  = {"lh": overlap_lh, "rh": overlap_rh}

###





###
# Setup

hemis = ["lh", "rh"]

# Input
basedir = "/home2/data/PublicProgram/freesurfer/fsaverage_copy/label"
network_files = { hemi : op.join(basedir, "%s.Yeo2011_7Networks_N1000.annot" % hemi) for hemi in hemis }
ba_files = { hemi : op.join(basedir, "%s.PALS_B12_Brodmann.annot" % hemi) for hemi in hemis }

# Output
obase = "/home2/data/Projects/CWAS/figures"
odir = path.join(obase, "sfig_yeo")
if not path.exists(odir): os.mkdir(odir)
oprefix = path.join(odir, "A_surface_yeo_and_iqcwas")

###


###
# Get Yeo parcellations

labels = ["visual", "somatomotor", "dorsal attention", "ventral attention", 
          "limbic", "fronto-parietal", "default"]
networks = { hemi : io.read_annot(file) for hemi,file in network_files.iteritems() }

bas = { hemi : io.read_annot(file) for hemi,file in ba_files.iteritems() }

###


###
# Plot overlap

for hemi in hemis:
    brain = fsaverage(hemi)
    
    brain.add_annotation(network_files[hemi], borders=False, alpha=0.333)
    
    # BELOW IS IF I WANT TO DO BORDERS AND ALPHA OVERLAY
    #cmat = network[1][:,:4]
    #cbar = load_colorbar(cmat)
    #cbar[:,3] = 255/3.
    #brain = add_overlay("yeo", brain, network[0],cbar, 0, 7, "pos")
    
    cbar = load_colorbar(np.array([[255,0,0,255]]))
    brain = add_overlay(study, brain, surf_data[hemi], cbar, 
                        1, 2, "pos")
    
    save_imageset(brain, oprefix, hemi)

montage(oprefix, compilation='box')
montage(oprefix, compilation='horiz')
montage(oprefix, compilation='horiz_lh')
montage(oprefix, compilation='horiz_rh')

