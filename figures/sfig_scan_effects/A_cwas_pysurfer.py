#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
from surfwrap import SurfWrap


strategy = "compcor"
scan = "_scan_effects"

print "strategy: %s; scan: %s" % (strategy, scan)


basedir = "/home2/data/Projects/CWAS/nki/cwas"
mname = "scan_subject+meanFD.mdmr"
cname = "cluster_correct_v05_c05"
factor = "scan"

ks = {
    #"roi2roi": [25, 50, 100, 200, 400, 800, 1600, 3200, 6400], 
    #"roi2vox": [25, 50, 100, 200, 400, 800, 1600, 3200, 6400], 
    #"roi2vox": [3200], 
    "vox2vox": ["kvoxs_smoothed_to_kvoxs_smoothed"]
}

for name,kset in ks.iteritems():
    print name
    for k in kset:
        print k
        # Distance Directory    
        if name == "vox2vox":
            dirname = "%s_%s" % (strategy, k)
        elif name == "roi2vox":
            dirname = "%s_rois_random_k%04i" % (strategy, k)
        elif name == "roi2roi":
            dirname = "%s_only_rois_random_k%04i" % (strategy, k)
        else:
            raise Exception("whoops")
        distdir = path.join(basedir, scan, dirname)
        
        # Input pfile
        mdmrdir = path.join(distdir, mname)
        pfile = path.join(mdmrdir, cname, "clust_logp_%s.nii.gz" % factor)
        
        # Output oprefix
        odir = path.join(mdmrdir, cname, "images")
        if not path.exists(odir): os.mkdir(odir)
        oprefix = path.join(odir, path.basename(pfile).replace(".nii.gz", ""))
        
        # Surface Viz
        sw = SurfWrap(name=factor, infile=pfile, cbar="red-yellow", 
                      outprefix=oprefix)
        sw.run(compilation="box")
        sw.montage(compilation="stick")
        
        # import pysurfer
        # pysurfer = reload(pysurfer)
        # SurfWrap = pysurfer.SurfWrap

    


