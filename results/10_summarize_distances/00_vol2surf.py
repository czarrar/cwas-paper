#!/usr/bin/env python

import os
from os import path as op

basedir  = "/home2/data/Projects/CWAS/nki"
indir    = op.join(basedir, "stability/N104_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08")
outdir   = op.join(indir, "surf_zscores")
measures = ["cv_short", "cv_medium", "consistency"]

if not op.exists(outdir):
    os.mkdir(outdir)

for measure in measures:
    print "\nmeasure: %s" % measure
    
    infile  = "%s/%s_zscore.nii.gz" % (indir, measure)
    outfile = "%s/%s" % (outdir, measure)
    
    cmd = "./x_simple_mni2fs.bash %s %s" % (infile, outfile)
    
    print cmd
    os.system(cmd)
