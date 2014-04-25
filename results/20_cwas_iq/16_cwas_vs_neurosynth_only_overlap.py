#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path as op
from os import path
import numpy as np
import nibabel as nib
from newsurf import *


###
# Setup

fsdir = "/home2/data/PublicProgram/freesurfer"

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
obase = "/home2/data/Projects/CWAS/results"
odir = path.join(obase, "20_cwas_iq", "16_cwas_vs_neurosynth_only")
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
# Create overlap

overlap_lh = (scan1_lh[:]>0) * (scan2_lh[:]>0)
overlap_rh = (scan1_rh[:]>0) * (scan2_rh[:]>0)
overlap = {"lh": overlap_lh, "rh": overlap_rh}

###


###
# Get Neurosynth

prefix      = "/home2/data/Projects/CWAS/results/20_cwas_iq/12_iq_surface/30_neurosynth_iq_surf_thresh"
neurosynth  = { hemi : io.read_scalar_data("%s_%s.nii.gz" % (prefix, hemi)) for hemi in ["lh", "rh"] }

# 'Accent' or 'Blues' or 'BrBG' or 'BuGn' or 'BuPu' or 'Dark2' or 'GnBu' or 'Greens' or 'Greys' or 'OrRd' or 'Oranges' or 'PRGn' or 'Paired' or 'Pastel1' or 'Pastel2' or 'PiYG' or 'PuBu' or 'PuBuGn' or 'PuOr' or 'PuRd' or 'Purples' or 'RdBu' or 'RdGy' or 'RdPu' or 'RdYlBu' or 'RdYlGn' or 'Reds' or 'Set1' or 'Set2' or 'Set3' or 'Spectral' or 'YlGn' or 'YlGnBu' or 'YlOrBr' or 'YlOrRd' or 'autumn' or 'binary' or 'black-white' or 'blue-red' or 'bone' or 'cool' or 'copper' or 'file' or 'flag' or 'gist_earth' or 'gist_gray' or 'gist_heat' or 'gist_ncar' or 'gist_rainbow' or 'gist_stern' or 'gist_yarg' or 'gray' or 'hot' or 'hsv' or 'jet' or 'pink' or 'prism' or 'spectral' or 'spring' or 'summer' or 'winter'

###
# Run

measures = {"scan1": scan1, "scan2": scan2, "overlap": overlap}

for measure,surf_data in measures.iteritems():
    for hemi in hemis:
        print "hemi: %s" % hemi
        
        # Bring up the visualization
        brain = Brain("fsaverage_copy", hemi, "inflated", subjects_dir=fsdir)

        # Bring up the overlay
        #print "...adding CWAS" # RED
        #brain.add_overlay(surf_data[hemi]*11, max=11, name="cwas")
        #brain.overlays["cwas"].pos_bar.lut_mode = "Set1"
        #brain.overlays["cwas"].pos_bar.visible  = False
        
        #print "...adding neurosynth" # BLUE
        #brain.add_overlay(neurosynth[hemi]*10, max=11, name="neurosynth")
        #brain.overlays["neurosynth"].pos_bar.lut_mode = "Set1"
        #brain.overlays["neurosynth"].pos_bar.visible  = False
        
        print "...adding overlap" # GREEN
        conjunct = (surf_data[hemi]>0) * (neurosynth[hemi]>0)
        brain.add_overlay(conjunct*9, max=11, name="overlap")
        brain.overlays["overlap"].pos_bar.lut_mode = "Set1"
        brain.overlays["overlap"].pos_bar.visible  = False
        
        # Anatomical borders
        print "...annotating"
        brain.add_annotation("aparcDKT40JT")
        # Take pics
        print "...saving"
        brain.save_montage("%s/%s_overlap_aparc_%s.png" % (outdir, measure, hemi))
        
    print "join the hemispheres together"

    for parcel in ["aparc"]:
        print "...%s" % parcel
    
        prefix  = "%s/%s_overlap_%s" % (outdir, measure, parcel)
    
        cmd     = "pngappend %s_lh.png - %s_rh.png %s.png" % (prefix, prefix, prefix)
        print cmd
        os.system(cmd)
    
        print "...removing pieces"
        for hemi in hemis:
            os.remove("%s_%s.png" % (prefix, hemi))
    

