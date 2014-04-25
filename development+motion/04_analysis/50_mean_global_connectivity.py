#!/usr/bin/env python

"""
This script will take a subject's functional data and generate the mean global 
connectivity.
"""

import nibabel as nib
import numpy as np
from os import path as op

def norm_cols(X):
    """
    Theano expression which centers and normalizes columns of X `||x_i|| = 1`
    """
    Xc = X - X.mean(0)
    return Xc/np.sqrt( (Xc**2.).sum(0) )

def load_data(infile, maskfile):
    # functional image
    img = nib.load(infile)
    data = img.get_data()
    # brain mask
    mask_img = nib.load(maskfile)
    mask = mask_img.get_data()
    # mask functional image
    masked_data = data[mask==1,:]
    return masked_data

def mean_global_corr(ts_data):
    ts_data_n   = norm_cols(ts_data)
    mean_ts     = ts_data_n.mean(axis=1)
    mean_gcor   = mean_ts.dot(ts_data_n).mean()    
    return mean_gcor

# Function for checking (not used)
def _mean_global_corr_slow(ts_data):
    return np.corrcoef(ts_data.T).mean()

maskfile = "/home2/data/Projects/CWAS/development+motion/rois/mask_gray_4mm.nii.gz"

subdir = "../subinfo"
strategy = "compcor"

mean_gcors = []

fpath = op.join(subdir, "02_funcpaths_4mm_fwhm08.txt")
f = open(fpath, 'r')
infiles = [ l.strip().strip('""') for l in f.readlines() ]
f.close()

for infile in infiles:
    print "...%s" % infile
    masked_data = load_data(infile, maskfile)
    mean_gcor   = mean_global_corr(masked_data.T)
    mean_gcors.append(mean_gcor)

mgs = np.array(mean_gcors).T
np.savetxt(op.join(subdir, "mean_gcors_4mm_fwhm08.txt"), mgs, fmt="%.5f")
