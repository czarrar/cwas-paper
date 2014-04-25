#!/usr/bin/env python

import os
from os import path as op
import scipy, scipy.stats

# Basics
base        = "/home2/data/Projects/CWAS"
idir        = op.join(base, "ldopa/extra_analyses")
odir        = op.join(idir, "easythresh")
if not op.exists(odir):
    os.mkdir(odir)

# Images
mask_file   = op.join(base, "ldopa/rois/mask_for_ldopa_gray_4mm.nii.gz")
bg_file     = op.join(base, "ldopa/rois/standard_4mm.nii.gz")

# Settings
zthr        = scipy.stats.norm.isf(0.05)
cthr        = 0.05
factors     = ["standards", "pos", "null", "neg"]

# Change Directory
curdir = os.getcwd()
os.chdir(odir)

for factor in factors:
    print "FACTOR: %s" % factor
    zstat_file = op.join(idir, "10_mdmr_%s.nii.gz" % factor)
    cmd = "easythresh %s %s %.4f %.4f %s zstat_%s --mm" % (zstat_file, mask_file, zthr, cthr, bg_file, factor)
    print cmd
    os.system(cmd)
