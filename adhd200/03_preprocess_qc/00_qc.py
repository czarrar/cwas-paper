#!/usr/bin/env python

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
# Setup
###

scriptdir = "/home2/data/Projects/CWAS/share/adhd200"
fname = path.join(scriptdir, "subinfo/02_subject_info_all.csv")
details = read_csv(fname, index_col=0)
details = details[details.site=='NYU']
details.index = range(details.shape[0])
# np.unique(details['id']).index

# Motion Related Functions
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
# File paths
###

# Create file paths
preprocdir = "/home2/data/PreProc/ADHD200/sym_links/pipeline_0"
pipelines = [
    "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98", 
    "linear1.wm1.global1.motion1.csf1_CSF_0.98_GM_0.7_WM_0.98"
]
suffix = "scan_rest"

funcdirs = [ path.join(preprocdir, pipelines[1], "%07i_" % scan, suffix) for scan in details['ScanDir.ID'] ]
details['func_outdir'] = funcdirs

subs_HackettCity = np.array([ not path.exists(fd) for fd in funcdirs ])
preprocdir_HackettCity = path.join(path.dirname(preprocdir), "pipeline_HackettCity")
funcdirs_HackettCity = [ path.join(preprocdir_HackettCity, pipelines[1], "%07i" % scan, suffix) 
                            for scan in details['ScanDir.ID'][subs_HackettCity] ]
details['func_outdir'][subs_HackettCity] = funcdirs_HackettCity



###
# Get motion info
###

print "\nGetting motion stuff"

pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.T.iteritems():
    pb.update(i+1)
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

motion_df = details[["id", "site", "rest.run", "mean_FD"]]
motion_df.to_csv("01_mean_FD.csv")

qc_values = details[["site", "id", "rest.run", "max_relative_motion", "num_movements"]]
qc_summary = details[["site", "id", "rest.run"]]



###
# Check motion
###

print "\nChecking motion"
print "...identifying subjects with relative motion >1.5mm or 10+ time-points with >1mm of relative motion"

bad_elems = (details['max_relative_motion']>1.5) & \
                ((details['max_relative_motion']>1) & (details['num_movements']>10))
qc_summary["bad_motion"] = bad_elems*1



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

print "...creating matrices to hold all subject masks and the overlap across masks"
all_masks       = np.zeros((ref_mask.sum(), len(details)))
overlap_mask    = np.zeros((ref_mask.sum()))

print "...gathering masks"
pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.T.iteritems():
    pb.update(i+1)
    fname   = path.join(row['func_outdir'], "func", 
                "functional_brain_mask_to_standard.nii.gz")
    img     = nib.load(fname)
    data    = img.get_data()
    all_masks[:,i]  = data[voxs_to_use]
    overlap_mask   += data[voxs_to_use]
pb.finish()

mask_percent_overlap    = (overlap_mask/len(details))*100
mask_img                = ref_mask.astype(np.float32)
mask_img[voxs_to_use]   = mask_percent_overlap
mask_img                = nib.Nifti1Image(mask_img, aff, hdr)
mask_img.set_data_dtype(np.float32)
mask_img.to_filename('../rois/mask_percent_overlap.nii.gz')


###
# Determine subjects to exclude based on coverage
###

print "\nDeterming subjects to exclude based on brain masks"

print "...getting each subject's overlap with overlap mask >90% (exclude subjects with <90% overlap)"
# get relative to 90% of subjects
ninety_percent_overlap = mask_percent_overlap > 90
nvoxs = float(ninety_percent_overlap.sum())
pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
def fun(subj): 
    pb.update(pb.currval+1); 
    subj_nvoxs = np.all([subj, ninety_percent_overlap], axis=0).sum()
    return (subj_nvoxs/nvoxs)*100
subjs_percent_overlap = np.apply_along_axis(fun, 0, all_masks)
bad_subs1 = subjs_percent_overlap < 90
pb.finish()

qc_values["func_overlap_with_90"] = subjs_percent_overlap
qc_values["func_overlap_with_std"] = all_masks.mean(axis=0)

qc_summary["bad_coverage"] = bad_subs1*1


###
# Calculate SNR
### 

print "\nCalculating SNR for each subject and comparing it to the group mean"

print "...creating matrices"
nvoxs   = ref_mask.sum()
all_mean_snrs = np.zeros((len(details)))
all_snr = np.zeros((nvoxs, len(details)))
grp_snr = np.zeros((nvoxs))

print "...gathering images and calculating SNR + mean SNR"
pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.T.iteritems():
    pb.update(i+1)
    fname = path.join(row['func_outdir'], "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz")
    img   = nib.load(fname)
    data  = img.get_data()
    tmp   = data[voxs_to_use,:]
    tmp   = stats.zscore(tmp, axis=1) + 100
    snr   = (tmp.std(axis=1)/tmp.mean(axis=1)) * 100
    snr[np.isnan(snr)] = 0
    all_snr[:,i]  = snr
    grp_snr      += snr
    all_mean_snrs[i] = snr[all_masks[:,i]==1].mean()
grp_snr /= len(details)
pb.finish()

qc_values["func_snr_raw"] = all_mean_snrs
qc_values["func_snr_zcor"] = stats.zscore(all_mean_snrs)
qc_summary["bad_snr"] = (qc_values["func_snr_zcor"]<-2)*1

print "...computing correlations with mean and saving"
cors = custom_corrcoef(grp_snr, all_snr)
qc_values["func_snr_mean_zcor"] = 0.0
zcors = stats.zscore(np.arctanh(cors[all_mean_snrs!=0]))
qc_values["func_snr_mean_zcor"][all_mean_snrs!=0] = zcors


###
# fALFF
###

print "\nGathering fALFF for each subject and comparing it to the group mean"

print "...creating matrices"
nvoxs   = ref_mask.sum()
all_mean_falff = np.zeros((len(details)))
all_falff = np.zeros((nvoxs, len(details)))
grp_falff = np.zeros((nvoxs))

print "...gathering images and mean"
pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.T.iteritems():
    pb.update(i+1)
    fname = path.join(row['func_outdir'], "alff/hp_0.01/lp_0.1/falff_Z_to_standard.nii.gz")
    if not path.exists(fname):
        fname = path.join(row['func_outdir'], "alff/hp_0.009/lp_0.1/falff_Z_to_standard.nii.gz")
    img   = nib.load(fname)
    data  = img.get_data()
    tmp   = data[voxs_to_use]
    all_falff[:,i] = tmp
    grp_falff     += tmp
    all_mean_falff[i] = tmp[all_masks[:,i]==1].mean()
grp_falff /= len(details)
pb.finish()

qc_values["falff_zcor"] = stats.zscore(all_mean_falff)

print "...computing correlations with mean and saving"
cors = custom_corrcoef(grp_falff, all_falff)
qc_values["falff_mean_zcor"] = 0.0
zcors = stats.zscore(np.arctanh(cors[all_mean_falff!=0]))
qc_values["falff_mean_zcor"][all_mean_falff!=0] = zcors


###
# Degree Centrality
###

print "\nGathering degree centrality for each subject and comparing it to the group mean"

print "...creating matrices"
nvoxs   = ref_mask.sum()
all_mean_degree = np.zeros((len(details)))
all_degree = np.zeros((nvoxs, len(details)))
grp_degree = np.zeros((nvoxs))

print "...gathering images and mean"
pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.T.iteritems():
    pb.update(i+1)
    fname = path.join(row['func_outdir'], "centrality/mask_MNI152_T1_GREY_3mm_50pc/bandpass_freqs_0.01.0.1/degree_centrality_weighted_maths.nii.gz")
    if not path.exists(fname):
        fname = path.join(row['func_outdir'], "centrality/mask_MaskOf85Percent_3mm_GM/bandpass_freqs_0.01.0.1/degree_centrality_weighted_maths.nii.gz")
    img   = nib.load(fname)
    data  = img.get_data()
    tmp   = data[voxs_to_use]
    all_degree[:,i] = tmp
    grp_degree     += tmp
    all_mean_degree[i] = tmp[all_masks[:,i]==1].mean()
grp_degree /= len(details)
pb.finish()

qc_values["degree_zcor"] = stats.zscore(all_mean_degree)

print "...computing correlations with mean and saving"
cors = custom_corrcoef(grp_degree, all_degree)
qc_values["degree_mean_zcor"] = 0.0
zcors = stats.zscore(np.arctanh(cors[all_mean_degree!=0]))
qc_values["degree_mean_zcor"][all_mean_degree!=0] = zcors


###
# REHO
###

print "\nGathering REHO for each subject and comparing it to the group mean"

print "...creating matrices"
nvoxs   = ref_mask.sum()
all_mean_reho = np.zeros((len(details)))
all_reho = np.zeros((nvoxs, len(details)))
grp_reho = np.zeros((nvoxs))

print "...gathering images and mean"
pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.T.iteritems():
    pb.update(i+1)
    fname = path.join(row['func_outdir'], "reho/bandpass_freqs_0.01.0.1/reho_Z_to_standard.nii.gz")
    img   = nib.load(fname)
    data  = img.get_data()
    tmp   = data[voxs_to_use]
    all_reho[:,i] = tmp
    grp_reho     += tmp
    all_mean_reho[i] = tmp[all_masks[:,i]==1].mean()
grp_reho /= len(details)
pb.finish()

qc_values["reho_zcor"] = stats.zscore(all_mean_reho)

print "...computing correlations with mean and saving"
cors = custom_corrcoef(grp_reho, all_reho)
qc_values["reho_mean_zcor"] = 0.0
zcors = stats.zscore(np.arctanh(cors[all_mean_reho!=0]))
qc_values["reho_mean_zcor"][all_mean_reho!=0] = zcors



###
# Compile Functional Measures
###

#qc_summary["bad_preprocessing"]     = (all_mean_snrs==0)*1
qc_summary["bad_summary_measures"]  = ((qc_values["falff_mean_zcor"]<-2) & \
                                        (qc_values["degree_mean_zcor"]<-2) & \
                                        (qc_values["reho_mean_zcor"]<-2))*1

qc_summary["bad_sub"] = np.zeros(len(qc_summary))
qc_summary.bad_sub = ((qc_summary.bad_motion + qc_summary.bad_coverage + qc_summary.bad_summary_measures) > 0)*1
qc_summary.bad_sub[qc_summary.id==5164727] = 1


###
# We're done! Save our slavish work
###

# Save the summaries
qc_values.to_csv("qc_values.csv", index=False)
qc_summary.to_csv("qc_summary.csv", index=False)

# Copy only needed stuff
df = details[["id", "site", "rest.run", "group", "gender", "age", "iq", "func_outdir", "mean_FD", "mean_relative_motion"]]
df = df[qc_summary.bad_sub !=1]
df.to_csv(path.join(scriptdir, "subinfo/03_subjects_qc.csv"), index=False)

