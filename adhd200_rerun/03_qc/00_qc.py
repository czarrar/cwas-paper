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

from glob import glob

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

def large_outliers(x, approach="median", deviation=2):
    if approach == "median":
        interquartile_range = deviation * (x.quantile(0.75) - x.quantile(0.25))
        limit = x.median() + interquartile_range
        return x > limit
    elif approach == "mean":
        limit = x.mean() + deviation * x.std()
        return x > limit

def small_outliers(x, approach="median", deviation=2):
    if approach == "median":
        interquartile_range = deviation * (x.quantile(0.75) - x.quantile(0.25))
        limit = x.median() - interquartile_range
        return x < limit
    elif approach == "mean":
        limit = x.mean() - deviation * x.std()
        return x < limit

# Motion Related Functions
rms = lambda x: sqrt(mean(x**2))
euclidean_distance = lambda x: sqrt(sum(x**2))
rotation_deg_to_mm = lambda x: 2*pi*50*(x/360)  # based on Power et al.

widgets = ['Progress: ', Percentage(), ' ', Bar(), ' ', Counter(), '/%i' % len(details), ' ', ETA()]



###
# Setup
###

roi_dir = "/home2/data/Projects/CWAS/adhd200_rerun/rois"
scriptdir = "/home2/data/Projects/CWAS/share/adhd200_rerun"
subinfo_dir = path.join(scriptdir, "subinfo")

fname = path.join(subinfo_dir, "10_raw_df.csv")
details = read_csv(fname, index_col=0)
orig_details = details
details.index = range(details.shape[0])

ref_details = read_csv("../adhd200/subinfo/03_subjects_qc.csv")
ref_details = ref_details[ref_details.site=='NYU']



###
# File paths
###

# Generate data frame based off of filepaths
preprocdir = "/home2/data/PreProc/ADHD200/sym_links/pipeline_HackettCity"
pipelines = [
    "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98", 
    "linear1.wm1.global1.motion1.csf1_CSF_0.98_GM_0.7_WM_0.98"
]
funcdirs = glob(path.join(preprocdir, pipelines[1], "*_session_1", "scan_rest_?_rest"))
anatdirs = [ path.join(path.dirname(fdir), "scan") for fdir in funcdirs ]
ids = [ path.basename(path.dirname(fdir)).replace("_session_1", "") for fdir in funcdirs ]
runs = [ int(path.basename(fdir).replace("scan_rest_", "").replace("_rest", "")) for fdir in funcdirs ]
details = DataFrame({"subject": ids, "run": runs, "anatdir": anatdirs, "funcdir": funcdirs}, 
                        columns=["subject", "run", "anatdir", "funcdir"])


###
# Get motion info
###

print "\nGetting motion stuff"

details['mean_FD'] = np.zeros(len(details))
details['max_FD'] = np.zeros(len(details))
details['mean_relative_motion'] = np.zeros(len(details))
details['max_relative_motion'] = np.zeros(len(details))
details['num_movements'] = np.zeros(len(details), dtype=np.int)

pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.iterrows():
    pb.update(i+1)
    # mean framewise displacement
    fd = np.loadtxt("%s/parameters/frame_wise_displacement.1D" % row['funcdir'])
    details['mean_FD'][i] = fd.mean()
    details['max_FD'][i] = fd.max()
    # get relative motion
    fname = '%s/parameters/movement_parameters.1D' % row['funcdir']
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

motion_df = details[["subject", "run", "mean_FD"]]
motion_df.to_csv(path.join(subinfo_dir, "qc-1_meanFD.csv"))

qc_values = details[["subject", "run", "mean_FD", "max_relative_motion", "num_movements"]]
qc_summary = details[["subject", "run"]]



###
# Check motion
###

print "\nChecking motion"
print "...identifying subjects with mean FD outside two times the interquartile range"

bad_elems = larger_outliers(details.mean_FD)
qc_summary["bad_motion"] = bad_elems*1



###
# Check coverage via brain masks
###

print "\nChecking coverage in standard space"

print "...loading standard brain mask as the reference"
resolution      = 2
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
for i,row in details.iterrows():
    pb.update(i+1)
    fname   = path.join(row['funcdir'], "func", 
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
mask_img.to_filename('%s/qc-1_mask_percent_overlap.nii.gz' % roi_dir)



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
    missing_voxs = (subj - ninety_percent_overlap) < 0
    nmissing = missing_voxs.sum()
    return nmissing
subjs_nmissing = Series(np.apply_along_axis(fun, 0, all_masks))
bad_subs1 = large_outliers(subjs_nmissing)
pb.finish()

mask_percent_overlap    = (all_masks[:,~bad_subs1].sum(axis=1)/sum(~bad_subs1))*100
mask_img                = ref_mask.astype(np.float32)
mask_img[voxs_to_use]   = mask_percent_overlap
mask_img                = nib.Nifti1Image(mask_img, aff, hdr)
mask_img.set_data_dtype(np.float32)
mask_img.to_filename('%s/qc-2_mask_percent_overlap.nii.gz' % roi_dir)

qc_values["func_overlap_with_90"] = subjs_nmissing
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
for i,row in details.iterrows():
    pb.update(i+1)
    fname = path.join(row['funcdir'], "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz")
    img   = nib.load(fname)
    data  = img.get_data()
    tmp   = data[voxs_to_use,:]
    snr   = (tmp.std(axis=1)/tmp.mean(axis=1)) * 100
    snr[np.isnan(snr)] = 0
    snr           = np.abs(snr)
    all_snr[:,i]  = snr
    grp_snr      += snr
    all_mean_snrs[i] = snr[all_masks[:,i]==1].mean()
grp_snr /= len(details)
pb.finish()

nz_inds = all_mean_snrs!=0

qc_values["func_snr"] = all_mean_snrs*0
qc_values.func_snr[nz_inds] = all_mean_snrs[nz_inds]

qc_summary["bad_snr"] = 1.0
qc_summary.bad_snr[nz_inds] = small_outliers(qc_values["func_snr"][nz_inds])*1

print "...computing correlations with mean and saving"
cors = custom_corrcoef(grp_snr, all_snr)
qc_values["func_snr_cor_grp_snr"] = 0.0
zcors = stats.zscore(np.arctanh(cors[nz_inds]))
qc_values["func_snr_cor_grp_snr"][nz_inds] = zcors

print '...save all the snrs'
snr_shape               = tuple(list(ref_img.shape) + [all_masks.shape[1]])
snr_img                 = np.zeros(snr_shape, np.float32)
snr_img[voxs_to_use,:]  = all_snr
snr_img                 = nib.Nifti1Image(snr_img, aff, hdr)
snr_img.set_data_dtype(np.float32)
snr_img.to_filename('%s/qc-3_all_subjs_snr.nii.gz' % roi_dir)

print '...save the group snr'
snr_shape               = ref_img.shape
snr_img                 = np.zeros(snr_shape, np.float32)
snr_img[voxs_to_use]    = grp_snr
snr_img                 = nib.Nifti1Image(snr_img, aff, hdr)
snr_img.set_data_dtype(np.float32)
snr_img.to_filename('%s/qc-3_grp_snr.nii.gz' % roi_dir)



####
## fALFF
####
#
#print "\nGathering fALFF for each subject and comparing it to the group mean"
#
#print "...creating matrices"
#nvoxs   = ref_mask.sum()
#all_mean_falff = np.zeros((len(details)))
#all_falff = np.zeros((nvoxs, len(details)))
#grp_falff = np.zeros((nvoxs))
#
#print "...gathering images and mean"
#pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
#for i,row in details.T.iteritems():
#    pb.update(i+1)
#    fname = path.join(row['func_outdir'], "alff/hp_0.01/lp_0.1/falff_Z_to_standard.nii.gz")
#    if not path.exists(fname):
#        fname = path.join(row['func_outdir'], "alff/hp_0.009/lp_0.1/falff_Z_to_standard.nii.gz")
#    img   = nib.load(fname)
#    data  = img.get_data()
#    tmp   = data[voxs_to_use]
#    all_falff[:,i] = tmp
#    grp_falff     += tmp
#    all_mean_falff[i] = tmp[all_masks[:,i]==1].mean()
#grp_falff /= len(details)
#pb.finish()
#
#qc_values["falff_zcor"] = stats.zscore(all_mean_falff)
#
#print "...computing correlations with mean and saving"
#cors = custom_corrcoef(grp_falff, all_falff)
#qc_values["falff_mean_zcor"] = 0.0
#zcors = stats.zscore(np.arctanh(cors[all_mean_falff!=0]))
#qc_values["falff_mean_zcor"][all_mean_falff!=0] = zcors
#
#
####
## Degree Centrality
####
#
#print "\nGathering degree centrality for each subject and comparing it to the group mean"
#
#print "...creating matrices"
#nvoxs   = ref_mask.sum()
#all_mean_degree = np.zeros((len(details)))
#all_degree = np.zeros((nvoxs, len(details)))
#grp_degree = np.zeros((nvoxs))
#
#print "...gathering images and mean"
#pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
#for i,row in details.T.iteritems():
#    pb.update(i+1)
#    fname = path.join(row['func_outdir'], "centrality/mask_MNI152_T1_GREY_3mm_50pc/bandpass_freqs_0.01.0.1/degree_centrality_weighted_maths.nii.gz")
#    if not path.exists(fname):
#        fname = path.join(row['func_outdir'], "centrality/mask_MaskOf85Percent_3mm_GM/bandpass_freqs_0.01.0.1/degree_centrality_weighted_maths.nii.gz")
#    img   = nib.load(fname)
#    data  = img.get_data()
#    tmp   = data[voxs_to_use]
#    all_degree[:,i] = tmp
#    grp_degree     += tmp
#    all_mean_degree[i] = tmp[all_masks[:,i]==1].mean()
#grp_degree /= len(details)
#pb.finish()
#
#qc_values["degree_zcor"] = stats.zscore(all_mean_degree)
#
#print "...computing correlations with mean and saving"
#cors = custom_corrcoef(grp_degree, all_degree)
#qc_values["degree_mean_zcor"] = 0.0
#zcors = stats.zscore(np.arctanh(cors[all_mean_degree!=0]))
#qc_values["degree_mean_zcor"][all_mean_degree!=0] = zcors
#
#
####
## REHO
####
#
#print "\nGathering REHO for each subject and comparing it to the group mean"
#
#print "...creating matrices"
#nvoxs   = ref_mask.sum()
#all_mean_reho = np.zeros((len(details)))
#all_reho = np.zeros((nvoxs, len(details)))
#grp_reho = np.zeros((nvoxs))
#
#print "...gathering images and mean"
#pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
#for i,row in details.T.iteritems():
#    pb.update(i+1)
#    fname = path.join(row['func_outdir'], "reho/bandpass_freqs_0.01.0.1/reho_Z_to_standard.nii.gz")
#    img   = nib.load(fname)
#    data  = img.get_data()
#    tmp   = data[voxs_to_use]
#    all_reho[:,i] = tmp
#    grp_reho     += tmp
#    all_mean_reho[i] = tmp[all_masks[:,i]==1].mean()
#grp_reho /= len(details)
#pb.finish()
#
#qc_values["reho_zcor"] = stats.zscore(all_mean_reho)
#
#print "...computing correlations with mean and saving"
#cors = custom_corrcoef(grp_reho, all_reho)
#qc_values["reho_mean_zcor"] = 0.0
#zcors = stats.zscore(np.arctanh(cors[all_mean_reho!=0]))
#qc_values["reho_mean_zcor"][all_mean_reho!=0] = zcors



###
# Compile Functional Measures
###

#qc_summary["bad_preprocessing"]     = (all_mean_snrs==0)*1
#qc_summary["bad_summary_measures"]  = ((qc_values["falff_mean_zcor"]<-2) & \
#                                        (qc_values["degree_mean_zcor"]<-2) & \
#                                        (qc_values["reho_mean_zcor"]<-2))*1

qc_summary["bad_scan"] = np.zeros(len(qc_summary))
qc_summary.bad_scan = ((qc_summary.bad_motion + qc_summary.bad_coverage +  
                        qc_summary.bad_snr) > 0)*1



###
# Collapse across scans
###

# Record stuff for posterity
ntotal    = len(details.subject.unique())
nincluded = len(details[qc_summary.bad_scan == 0].subject.unique())
nexcluded = ntotal - nincluded

# Keep only 1 scan per participant
def choose_by_mean_FD(rows):
    # 1. finds run with smallest mean FD
    if len(rows) == 1:
        i = 0
    else:
        i = rows['mean_FD'].argmin()
    ind = rows.index[i]
    # 2. save original index
    rows['orig_index'] = ind
    # 3. save number of good scans
    rows['ngoodscans'] = len(rows)
    # 4. return one best (least motion) scan
    return rows.xs(ind)

filtered                = details[qc_summary.bad_scan == 0]
filtered['orig_index']  = -1
filtered['ngoodscans']  = 0
final_df = filtered.groupby('subject').agg(choose_by_mean_FD)

# Subject were lost, add back
final_df['subject'] = final_df.index
new_column_order    = [final_df.columns[-1]] + final_df.columns[0:-1].tolist()
final_df            = final_df.ix[:, new_column_order]
final_df.index      = range(len(final_df))

# Test if subjects are the same
final_df.subject == Index(sorted(filtered.subject.unique()))


###
# Merge phenotypic information
###

# Use df for ease
df = final_df

# Phenotypic Keys
site_key = ["Peking", "Brown", "KKI", "Neuroimage", "NYU", "OHSU", "UPitt", "WashU"]
gender_key = ["Female", "Male"]
diagnosis_key = ["TDC", "ADHD-C", "ADHD-HI", "ADHD-I"]

# Gather gender, age, handedness, diagnosis, and iq
orig_details.ix[Index(final_df.subject),:]
inds = Int64Index([ int(x) for x in final_df.subject])
phenos = orig_details.ix[inds,["Gender", "Age", "Handedness", "DX", "Full4 IQ"]]
phenos.columns = ["sex", "age", "handedness", "diagnosis", "iq"]

# Check if phenos and final_df match
[ int(x) for x in df.subject ] == phenos.index

# For phenos. Remove index and add subject
phenos['subject']   = phenos.index
new_column_order    = [phenos.columns[-1]] + phenos.columns[0:-1].tolist()
phenos              = phenos.ix[:, new_column_order]
phenos.index        = range(len(phenos))

# Add each columns to final_df
for col in phenos.columns[1:]:
    df[col] = phenos[col]

# Remove the one subject without gender information
df          = df[~df.sex.isnull()]
df.index    = range(len(df))


###
# Formate phenotypic information
###

df.sex          = [ gender_key[int(g)] for g in df.sex ]
df.diagnosis    = [ diagnosis_key[int(g)] for g in df.diagnosis ]


###
# Gather mask
###

# masks for subjects/scans passing QC
inds = [ (details.index == oi).nonzero()[0][0] for oi in df.orig_index ]
filt_masks = all_masks[:,inds]

# save all the included masks
mask_shape               = tuple(list(ref_img.shape) + [filt_masks.shape[1]])
mask_img                 = np.zeros(mask_shape, np.float32)
mask_img[voxs_to_use,:]  = filt_masks
mask_img                 = nib.Nifti1Image(mask_img, aff, hdr)
mask_img.set_data_dtype(np.float32)
mask_img.to_filename('%s/qc-4_all_masks_subs_to_use.nii.gz' % roi_dir)

# save the combined/overlap brain mask across to be used subjects
mask_overlap             = filt_masks.mean(axis=1)
mask_img                 = np.zeros(ref_img.shape, np.float32)
mask_img[voxs_to_use,:]  = (mask_overlap==1)*1
mask_img                 = nib.Nifti1Image(mask_img, aff, hdr)
mask_img.set_data_dtype(np.float32)
mask_img.to_filename('%s/mask_overlap_%imm.nii.gz' % (roi_dir, resolution))


###
# We're done! Save our slavish work
###

# Save the summaries
qc_values.to_csv(path.join(subinfo_dir, "qc-2_values.csv"), index=False)
qc_summary.to_csv(path.join(subinfo_dir, "qc-2_summary.csv"), index=False)

# Copy only needed stuff
new_col_stuff = ["subject", "run", "diagnosis", "sex", "age", "handedness", "iq", "mean_FD", "funcdir", "orig_index"]
save_df = df[new_col_stuff]
save_df.to_csv(path.join(subinfo_dir, "20_subjects_qc.csv"), index=False)


