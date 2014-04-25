#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
from surfwrap import SurfWrap
import numpy as np
import nibabel as nib


###
# Setup

strategy = "compcor"
scans = ["short", "medium"]


print "strategy: %s; scans: %s" % (strategy, ",".join(scans))

basedir = "/home2/data/Projects/CWAS/nki/cwas"

# Distance Directory
kstr = "kvoxs_fwhm08_to_kvoxs_fwhm08"
dirname = "%s_%s" % (strategy, kstr)
distdirs = [ path.join(basedir, scan, dirname) for scan in scans ]

# MDMR Directories
mname = "meanGcor_iq+age+sex+meanFD.mdmr"
cname = "cluster_correct_v05_c05"
factor = "meanGcor"

# Input pfile
from glob import glob
mdmrdirs = [ path.join(distdir, mname) for distdir in distdirs ]
pfiles = [ glob(path.join(mdmrdir, cname, "easythresh", "thresh_fstat_%s.nii.gz" % factor))[0] for mdmrdir in mdmrdirs ]
print pfiles

# Output prefixes
obase = "/home2/data/Projects/CWAS/figures"
odir = path.join(obase, "fig_04")
if not path.exists(odir): os.mkdir(odir)

###


###
# Get minimum and maximum values across the two scans

def get_range(fname):
    img = nib.load(fname)
    data = img.get_data()
    data_max = data.max()
    if data_max == 0:
        data_min = data_max
    else:
        data_min = data[data.nonzero()].min()
    return [data_min, data_max]

print 'getting range'
ranges = np.array([ get_range(pfile) for pfile in pfiles ])
dmin = ranges.min()
dmax = ranges.max()
print 'min=%.4f; max=%.4f' % (dmin,dmax)

###


###
# Surface Viz

for i,pfile in enumerate(pfiles):
    print pfile
    oprefix = path.join(odir, "C4_fstats_global_easythresh_surface_scan%i" % (i+1))
    sw = SurfWrap(name=factor, infile=pfile, cbar="red-yellow", 
                  outprefix=oprefix)
    sw.min = dmin; sw.max = dmax
    sw.run(compilation="box")
    sw.montage(compilation="stick")

###
