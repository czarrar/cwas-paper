#!/usr/bin/env python

import os, sys
from os import path as op

import nibabel as nb
import numpy as np
from pandas import read_table, read_csv
from patsy import dmatrices, dmatrix

from CPAC.cwas import cwas
from CPAC.cwas.subdist import fischers_transform, compute_distances
from CPAC.cwas.mdmr import mdmr

import mkl
mkl.set_num_threads(8)


####
# Cool Functions
####

def get_nsubjects(func_list):
    func_files = read_table(func_list, header=None).ix[:,0].tolist()
    return len(func_files)

def get_sca_files(func_list, roi):
    """
    Given a file with the list of functional paths, this will generate the 
    paths to the smoothed correlation maps for a given ROI.
    """

    dirnames    = lambda paths: [ op.dirname(path) for path in paths ]
    joins       = lambda paths,add_path: [ op.join(path, add_path) for path in paths ]

    func_files  = read_table(func_list, header=None).ix[:,0].tolist()
    sca_dirs    = joins(dirnames(func_files), "sca/fwhm_08")
    sca_files   = joins(sca_dirs, "smoothed_zscore_peaks100_2mm.nii_roi_n%02i.nii.gz" % roi)

    if not op.exists(sca_files[0]): raise Exception("SCA files doesn't exist")
    
    return sca_files

def roi_sca_maps(roi, func_list, mask_inds, dtype='float64'):
    """
    This loads the sca files for the given ROI and does a Fischer Z-Transform.
    """
    sca_files = get_sca_files(func_list, roi)
    # we subtract by 1e-12 to handle any 1s
    sca_maps  = [ nb.load(sca_file).get_data().astype(dtype)[mask_inds] - 1e-12
                        for sca_file in sca_files ]
    sca_maps  = np.array(sca_maps)
    return sca_maps

def roi_distance_matrix(sca_maps):
    """
    Computes the distances between SCA maps using one minus the pearson correlation.
    """
    return compute_distances(sca_maps)

def distances_for_rois(rois, func_list, mask_inds, dtype='float64'):
    """
    For each ROI, it calculates the distances between each pair of participant's SCA maps.
    The output is a nsubjects^2 by nrois matrix. This means that the distance matrix for
    each ROI is flattened into a vector that represents each column of the output.
    """
    nrois = len(rois); nsubjects = get_nsubjects(func_list)
    Ds = np.zeros((nsubjects**2, nrois))
    for i,roi in enumerate(rois):
        print "roi #%i" % roi
        print "...sca maps"
        sca_maps = roi_sca_maps(roi, func_list, mask_inds, dtype)
        print "...distance matrices"
        Ds[:,i] = roi_distance_matrix(sca_maps).reshape(nsubjects**2)
    return Ds

def mdmr_for_rois(rois, func_list, mask_inds, regressors, cols_of_interest, nperms=14999):
    print "Computing Distances"
    Ds = distances_for_rois(rois, func_list, mask_inds)
    
    print "Computing MDMR"
    p_set, F_set, F_perms, _ = mdmr(Ds, regressors, cols_of_interest, nperms)
    
    return (p_set, F_set, F_perms)
    

####
# Basic Settings
####

# Basics
base        = "/home2/data/Projects/CWAS"
subdir      = op.join(base, "share/nki/subinfo")
strategy    = "compcor"
scans       = ["short", "medium", "long"]
setxs       = {
    "short": "40_Set1_N104", 
    "medium": "40_Set1_N104", 
    "long": "40_Set2_N92"
}

# Functions
def get_func_list(scan):
    setx        = setxs[scan]
    setdir      = op.join(subdir, setx)
    func_list   = op.join(setdir, "%s_%s_funcpaths.txt" % (scan, strategy))
    return func_list

def get_regressors(scan):
    setx            = setxs[scan]
    setdir          = op.join(subdir, setx)
    regressor_file  = op.join(setdir, "subject_info_with_iq_and_gcors.csv")
    regressor       = read_csv(regressor_file)
    return regressor

# Load mask
mask_file = op.join(base, "nki/rois/mask_gray_2mm.nii.gz")
mask = nb.load(mask_file).get_data().astype('bool')
mask_inds = np.where(mask)


###
# Scan 1
###

si = 0  # test with scan 1

func_list   = get_func_list(scans[si])
regressors  = get_regressors(scans[si])

d = dmatrix("center(FSIQ) + center(Age) + Sex + center(%s_meanFD)" % scans[si], regressors)
cols_of_interest = [2]

ps1, fs1, fperms1 = mdmr_for_rois(range(1,101), func_list, mask_inds, np.asarray(d), cols_of_interest)


###
# Scan 2
###

si = 1

func_list   = get_func_list(scans[si])
regressors  = get_regressors(scans[si])

d = dmatrix("center(FSIQ) + center(Age) + Sex + center(%s_meanFD)" % scans[si], regressors)
cols_of_interest = [2]

ps2, fs2, fperms2 = mdmr_for_rois(range(1,101), func_list, mask_inds, np.asarray(d), cols_of_interest)


###
# Scan 3
###

si = 2

func_list   = get_func_list(scans[si])
regressors  = get_regressors(scans[si])

d = dmatrix("center(FSIQ) + center(Age) + Sex + center(%s_meanFD)" % scans[si], regressors)
cols_of_interest = [2]

ps3, fs3, fperms3 = mdmr_for_rois(range(1,101), func_list, mask_inds, np.asarray(d), cols_of_interest)


###
# Scan 1 - VIQ and PIQ
###

si = 0  # test with scan 1

func_list   = get_func_list(scans[si])
regressors  = get_regressors(scans[si])

d = dmatrix("center(VIQ) + center(PIQ) + center(Age) + Sex + center(%s_meanFD)" % scans[si], regressors)
cols_of_interest = [2,3]

z_ps1, z_fs1, z_fperms1 = mdmr_for_rois(range(1,101), func_list, mask_inds, np.asarray(d), cols_of_interest)
