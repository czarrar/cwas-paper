#!/usr/bin/env python

import os, sys
from os import path as op

import scipy
import nibabel as nb
import numpy as np
from pandas import read_table, read_csv
from patsy import dmatrices, dmatrix

from CPAC.cwas import cwas
from CPAC.cwas.utils import calc_subdists, calc_mdmrs
from CPAC.cwas.subdist import *
from CPAC.cwas.mdmr import mdmr, gen_perms

import mkl
mkl.set_num_threads(8)


####
# Cool Functions
####

def load_subject(filepath, dtype='float64'):
    return nb.load(filepath).get_data().astype(dtype)

def load_subjects(filepaths, dtype='float64'):
    print "Loading Subjects"
    funcs = [ load_subject(fp, dtype) for fp in filepaths ]
    return funcs

def rois2voxels(dat, rois):
    # Unique ROI indices to loop through
    urois       = np.unique(rois)
    urois.sort()
    # Make it into voxel space
    vox_dat = np.zeros_like(rois, dtype=dat.dtype)
    for i,uroi in enumerate(urois):
        vox_dat[rois==uroi] = dat[i]
    # Return
    return vox_dat

def save_rois_image(dat, rois, mask, ref_file, out_file):
    vox_dat = rois2voxels(dat, rois)
    save_image(vox_dat, mask, ref_file, out_file)
    return

def volumize(dat, mask):
    vol_dat = np.zeros_like(mask, dtype=dat.dtype)
    vol_dat[np.where(mask==True)] = dat
    return vol_dat

def save_image(dat, mask, ref_file, out_file):
    vol_dat = volumize(dat, mask)
    ref     = nb.load(ref_file)
    img     = nb.Nifti1Image(vol_dat, header=ref.get_header(), affine=ref.get_affine())
    img.to_filename(out_file)
    return

def calc_subdists_enhanced(subjects_data, voxel_range, dfun=compute_distances):
    nSubjects   = len(subjects_data)
    vox_inds    = range(*voxel_range)
    nVoxels     = len(vox_inds)
    #Number of timepoints may be consistent between subjects
    
    subjects_normed_data = norm_subjects(subjects_data)
    
    # Distance matrices for every voxel
    D = np.zeros((nVoxels, nSubjects, nSubjects))
        
    # For a particular voxel v, its spatial correlation map for every subject
    S = np.zeros((nSubjects, 1, nVoxels))
    
    for i in range(nVoxels):
        S    = ncor_subjects(subjects_normed_data, [vox_inds[i]])
        S0   = np.delete(S[:,0,:], vox_inds[i], 1)    # remove autocorrelations
        S0   = fischers_transform(S0)
        D[i] = dfun(S0)
    
    return D

def compute_distances_pos(S0):
    thresh_S0 = S0[:]
    thresh_S0[S0<0.31] = 0
    dmat = compute_distances(thresh_S0)
    return dmat

def compute_distances_null(S0):
    thresh_S0 = S0[:]
    thresh_S0[S0>0.31] = 0
    thresh_S0[S0<0] = 0
    dmat = compute_distances(thresh_S0)
    return dmat

def compute_distances_neg(S0):
    thresh_S0 = S0[:]
    thresh_S0[S0>0] = 0
    dmat = compute_distances(thresh_S0)
    return dmat

# Basics
base        = "/home2/data/Projects/CWAS"
subdir      = op.join(base, "share/ldopa/subinfo")
list_file   = op.join(subdir, "z_rois_random_k0800.txt")
df_file     = op.join(subdir, "02_demo_with_gcors.csv")
odir        = op.join(base, "ldopa/extra_analyses")

# Regressor Info
regressors  = read_csv(df_file)
dmat        = dmatrix("subjects + conditions + center(meanFD)", regressors)
dmat        = np.asarray(dmat)
cols        = [19]  # this is the conditions/placebo column
strata      = regressors.subjects # this will tell mdmr to only permute within-subject between scans

# Load Mask
mask_file   = op.join(base, "ldopa/rois/mask_for_ldopa_gray_4mm.nii.gz")
mask        = nb.load(mask_file).get_data().astype('bool')
mask_inds   = np.where(mask)

# Load ROI file
roi_file    = op.join(base, "ldopa/rois/rois_random_k0800.nii.gz")
rois        = nb.load(roi_file).get_data().astype('int')[mask_inds]
urois       = np.unique(rois)
urois.sort()

# Load Functionals
func_list   = read_table(list_file, header=None).ix[:,0].tolist()
funcs       = load_subjects(func_list)
nsubs       = len(funcs)
ntpts       = funcs[0].shape[0]
nparcels    = funcs[0].shape[1]

# Everything should get the same permutations
nperms      = 4999
perms       = gen_perms(nperms, nsubs, strata)



# Compute distances
# Compute MDMR
# mdmr here runs in 6 seconds
## convert to z-scores
D           = calc_subdists(funcs, [0,nparcels])
ps, Fs, _,_ = mdmr(D.reshape(nparcels, nsubs**2).T, dmat, cols, perms, strata)
zs          = scipy.stats.norm.isf(ps)

save_rois_image(zs, rois, mask, mask_file, op.join(odir, "10_mdmr_standard.nii.gz"))

our_zs = rois2voxels(zs, rois)
ref_zs = nb.load("/home2/data/Projects/CWAS/ldopa/cwas/rois_random_k0800_only/ldopa_subjects+meanFD.mdmr/cluster_correct_v05_c05/easythresh/zstat_conditions.nii.gz").get_data()[mask_inds]



###
# Positive Values (0.79)
###

D           = calc_subdists_enhanced(funcs, [0,nparcels], compute_distances_pos)
ps, Fs, _,_ = mdmr(D.reshape(nparcels, nsubs**2).T, dmat, cols, perms, strata)
## convert to z-scores and save
zs_pos      = scipy.stats.norm.isf(ps)
zs_pos[np.isinf(zs_pos)] = 0
save_rois_image(zs_pos, rois, mask, mask_file, op.join(odir, "12_mdmr_pos.nii.gz"))



###
# Null Values (0.14)
###

D           = calc_subdists_enhanced(funcs, [0,nparcels], compute_distances_null)
ps, Fs, _,_ = mdmr(D.reshape(nparcels, nsubs**2).T, dmat, cols, perms, strata)
## convert to z-scores and save
zs_null     = scipy.stats.norm.isf(ps)
zs_null[np.isinf(zs_null)] = 0
save_rois_image(zs_null, rois, mask, mask_file, op.join(odir, "12_mdmr_null.nii.gz"))



###
# Negative Values (0.4 correlation)
###

D           = calc_subdists_enhanced(funcs, [0,nparcels], compute_distances_neg)
ps, Fs, _,_ = mdmr(D.reshape(nparcels, nsubs**2).T, dmat, cols, perms, strata)
## convert to z-scores and save
zs_neg     = scipy.stats.norm.isf(ps)
zs_neg[np.isinf(zs_neg)] = 0
save_rois_image(zs_neg, rois, mask, mask_file, op.join(odir, "12_mdmr_neg.nii.gz"))

