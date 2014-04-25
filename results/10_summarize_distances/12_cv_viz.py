#!/usr/bin/env python

import os
from os import path as op
from surfer import Brain, io

###
# PATHS
###

fsdir = "/home2/data/PublicProgram/freesurfer"

basedir = "/home2/data/Projects/CWAS"
voldir  = op.join(basedir, "nki/stability/N104_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08")
indir   = op.join(voldir, "surf_zscores")

resdir  = op.join(basedir, "results/10_summarize_distances")
outdir  = op.join(resdir, "12_cv_viz")
if not op.exists(outdir):
    os.mkdir(outdir)


###
# DETAILS
###

measures = ["cv_short", "cv_medium"]
hemis    = ["lh", "rh"]


###
# LOOP
###

for measure in measures:
    print "\nmeasure: %s" % measure
    
    #for hemi in hemis:
    #    print "hemi: %s" % hemi
    #    
    #    # Bring up the visualization
    #    brain = Brain("fsaverage_copy", hemi, "inflated", subjects_dir=fsdir)
    #
    #    # Path to overlay
    #    overlay_file = "%s/%s_%s.mgh" % (indir, measure, hemi)
    #    
    #    # Bring up the overlay
    #    print "...adding overlay"
    #    brain.add_overlay(overlay_file, min=2)
    #    
    #    # Anatomical borders
    #    print "...annotating"
    #    brain.add_annotation("aparc")
    #    # Take pics
    #    print "...saving"
    #    brain.save_montage("%s/%s_aparc_%s.png" % (outdir, measure, hemi))
    #
    #    # Network borders
    #    print "...annotating"
    #    brain.add_annotation("Yeo2011_7Networks_N1000")
    #    # Take pics
    #    print "...saving"
    #    brain.save_montage("%s/%s_yeo_%s.png" % (outdir, measure, hemi))
    
    print "join the hemispheres together"
    
    for parcel in ["aparc", "yeo"]:
        print "...%s" % parcel
        
        prefix  = "%s/%s_%s" % (outdir, measure, parcel)
        
        cmd     = "pngappend %s_lh.png - %s_rh.png %s.png" % (prefix, prefix, prefix)
        print cmd
        os.system(cmd)
        
        print "...removing pieces"
        for hemi in hemis:
            os.remove("%s_%s.png" % (prefix, hemi))
        
    