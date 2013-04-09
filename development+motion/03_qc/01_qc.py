#!/usr/bin/env python

# NO NEED FOR QC SINCE USING DATA AS IS!

###
# Setup
###

print "Setup"

from os import path
from pandas import *
from progressbar import ProgressBar, Percentage, Bar, ETA, Counter

import os
import nibabel as nib

import numpy as np
from numpy import abs, diff, max, mean, pi, sqrt, std, sum
from scipy import stats

from glob import glob
from pandas import *

def ravel_index(x, dims):
    """Given xyz coordinates & dimensions of array, returns the vector index"""
    i = 0
    for dim, j in zip(dims, x):
        i *= dim
        i += j
    return i

def custom_corrcoef(X, Y=None):
    """Each of the columns in X will be correlated with each of the columns in 
    Y. Each column represents a variable, with the rows containing the observations."""
    if Y is None:
        Y = X
    
    if X.shape[0] != Y.shape[0]:
        raise Exception("X and Y must have the same number of rows.")
    
    X = X.astype(float)
    Y = Y.astype(float)
    
    X -= X.mean(axis=0)[np.newaxis,...]
    Y -= Y.mean(axis=0)
    
    xx = np.sum(X**2, axis=0)
    yy = np.sum(Y**2, axis=0)
    
    r = np.dot(X.T, Y)/np.sqrt(np.multiply.outer(xx,yy))
    
    return r


###
# Get data frame and paths
###

# Data Frame
fname = "/home2/data/Projects/CWAS/share/development+motion/subinfo/01_subject_info.csv"
details = read_csv(fname, index_col=0)
# np.unique(details['id']).index

# Files
## base
basedir = "/home2/data/PreProc/POWER_2012/sym_links/pipeline_0/"
deriv_compcor = path.join(basedir, "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98")
deriv_regular = path.join(basedir, "linear1.wm1.global1.motion1.csf1_CSF_0.98_GM_0.7_WM_0.98")
## files
details['anat_outdir'] = [
    path.join(deriv_compcor, "%s_" % sid, "scan") for sid in details['id']
]
details['func_outdir'] = [
    path.join(deriv_compcor, "%s_" % sid, "scan_rest") for sid in details['id']
]

# Check that main output file exists (then should be all good)
bad_ids = []
for i,row in details.T.iteritems():
    fname = path.join(row['func_outdir'],  
                'func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz')
    if not path.exists(fname):
        print 'Missing path for %s' % row['id']
        bad_ids.append(i)
    elif not path.exists(path.realpath(fname)):
        print 'Missing real path for %s' % row['id']
        bad_ids.append(i)
for i,row in details.T.iteritems():
    fname = path.join(row['anat_outdir'],  
                'anat/mni_normalized_anatomical.nii.gz')
    if not path.exists(fname):
        print 'Missing path for %s' % row['id']
        bad_ids.append(i)
    elif not path.exists(path.realpath(fname)):
        print 'Missing real path for %s' % row['id']
        bad_ids.append(i)


###
# Motion Related Functions
###

rms = lambda x: sqrt(mean(x**2))
euclidean_distance = lambda x: sqrt(sum(x**2))
rotation_deg_to_mm = lambda x: 2*pi*50*(x/360)  # based on Power et al.

details['mean_FD'] = np.zeros(len(details))
details['max_FD'] = np.zeros(len(details))
details['mean_relative_motion'] = np.zeros(len(details))
details['max_relative_motion'] = np.zeros(len(details))
details['num_movements'] = np.zeros(len(details), dtype=np.int)

widgets = ['Progress: ', Percentage(), ' ', Bar(), ' ', Counter(), '/%i' % len(details), ' ', ETA()]


###
# Get motion info
###

print "\nGetting motion stuff"

pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.T.iteritems():
    pb.update(i)
    # mean framewise displacement
    fd = np.loadtxt("%s/parameters/frame_wise_displacement.1D" % row['func_outdir'])
    details['mean_FD'][i] = fd.mean()
    details['max_FD'][i] = fd.max()
    # get relative motion
    fname = path.join(row['func_outdir'], 'parameters/movement_parameters.1D')
    motion_params = np.loadtxt(fname)
    motion_params[:,0:3] = np.apply_along_axis(rotation_deg_to_mm, 0, motion_params[:,0:3])
    rel_motion_params = np.apply_along_axis(diff, 1, motion_params)
    # only look at translations for relative motion
    rel_motion = np.apply_along_axis(euclidean_distance, 1, rel_motion_params[:,3:6]) 
    # save mean, max, and # of movements > 1mm
    details['mean_relative_motion'][i] = mean(rel_motion)
    details['max_relative_motion'][i] = max(rel_motion)
    details['num_movements'][i] = sum(rel_motion>1)
pb.finish()

motion_df = details[["id", "mean_FD"]]
motion_df.to_csv("01_mean_FD.csv")

df = details[["id", "cohort", "sex", "age", "time.points", "tr", "mean_FD"]]
df.to_csv("../subinfo/02_details.csv")


###
# Check coverage via brain masks
###

print "\nChecking coverage in standard space"

print "...loading standard brain mask as the reference"
resolution      = 3
ref_mask_fname  = os.path.join(os.getenv('FSLDIR'), 'data/standard', 
                    "MNI152_T1_%imm_brain_mask_dil.nii.gz" % resolution)
ref_img         = nib.load(ref_mask_fname)
aff             = ref_img.get_affine()
hdr             = ref_img.get_header()
ref_mask        = ref_img.get_data()
voxs_to_use     = ref_mask == 1
ref_nvoxs       = ref_mask.sum()

print "...creating matrices to hold the overlap across masks"
overlap_mask    = np.zeros((ref_mask.sum()))

print "...gathering masks"
pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.T.iteritems():
    pb.update(i)
    fname   = path.join(row['func_outdir'], "func", 
                "functional_brain_mask_to_standard.nii.gz")
    img     = nib.load(fname)
    data    = img.get_data()
    overlap_mask   += data[voxs_to_use]
pb.finish()

mask = (overlap_mask == len(details)) * 1
mask_img                = ref_mask.astype(np.float32)
mask_img[voxs_to_use]   = mask
mask_img                = nib.Nifti1Image(mask_img, aff, hdr)
mask_img.set_data_dtype(np.float32)
mask_img.to_filename('../rois/overlap_mask.nii.gz')

