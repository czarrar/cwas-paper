#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
from surfwrap import SurfWrap

obase = "/home2/data/Projects/CWAS/adhd200_rerun/cwas"
comparisons = ["adhdc_vs_adhdi", "tdc_vs_adhdc", "tdc_vs_adhdi"]

# GLOBAL!
preproc = "global"
for comparison in comparisons:
    print "group comparison: %s" % comparison
    
    # Input pfile
    distdir = path.join(obase, "%s_rois_random_k3200" % preproc)
    mdmrdir = path.join(distdir, "%s_gender+age+iq+mean_FD.mdmr" % comparison)
    pfile = path.join(mdmrdir, "log_pvals_%s.nii.gz" % comparison)
    
    # Output oprefix
    odir = path.join(mdmrdir, "images")
    if not path.exists(odir): os.mkdir(odir)
    oprefix = path.join(odir, path.basename(pfile).replace(".nii.gz", ""))
    
    # Surface Viz
    sw = SurfWrap(name=comparison, infile=pfile, cbar="red-yellow", outprefix=oprefix)
    sw.min = 1.3
    sw.run()
    
    # import pysurfer
    # pysurfer = reload(pysurfer)
    # SurfWrap = pysurfer.SurfWrap

