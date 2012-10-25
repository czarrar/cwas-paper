
# a

# for site names check if any overlap with indi names

# what should i do with multiple runs?
# do we need the 3rd column with datasets?

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

fname = "/home2/data/Projects/CWAS/share/preprocessing/subinfo/01_paths.csv"
details = read_csv(fname, index_col=0)
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
# Get motion info
###

print "Getting motion stuff"

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
    rel_motion = np.apply_along_axis(euclidean_distance, 1, rel_motion_params[:,3:6]) # only look at translations for relative motion
    # save mean, max, and # of movements > 1mm
    details['mean_relative_motion'][i] = mean(rel_motion)
    details['max_relative_motion'][i] = max(rel_motion)
    details['num_movements'][i] = sum(rel_motion>1)
pb.finish()

motion_df = details[["orig_id", "site", "id", "func_run", "mean_FD"]]
motion_df.save("01_mean_FD.csv")

qc_values = details[["site", "id", "func_run", "max_relative_motion", "num_movements"]]
qc_summary = details[["site", "id", "func_run"]]

###
# Check motion
###

print "Checking motion"
print "...identifying subjects with relative motion >1.5mm or 10+ time-points with >1mm of relative motion"

bad_elems = (details['max_relative_motion']>1.5) & \
                ((details['max_relative_motion']>1) & (details['num_movements']>10))
qc_summary["bad_motion"] = bad_elems*1


###
# Check coverage via brain masks
###

print "Checking coverage in standard space"

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
mask_img.to_filename('02_mask_percent_overlap.nii.gz')


###
# Determine subjects to exclude based on coverage
###

print "Determing subjects to exclude based on brain masks"

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
qc_values["func_overlap_with_std"] = all_means.mean(axis=0)

print "...getting subjects that have signal in particular voxels"
# Compile some voxels that must be present in all subjects
## Part 1
### coordinates
needed_coordinates = [
    [24,38,27], # sub-cortical
    [30,33,46], # motor
    [30,56,22], # fronto-medial
    [30,13,23],  # visual
]
### convert 3D coordinates to 1D vector index
needed_inds = [
    (voxs_to_use.ravel().nonzero() == np.array(ravel_index(x, ref_img.shape))).ravel().nonzero()[0][0]
    for x in needed_coordinates
]
bad_subs2 = ~all_masks[needed_inds,:].all(axis=0)
## Part 2
### coordinates
needed_coordinates = [
    [30,61,23], # fronto-medial
    [24,10,25], # visual
    [33,10,25], # visual
    [37,33,48], # motor
    [24,32,48], # motor
    [14,39,42], # lateral something
    [47,36,42], # lateral something
    [35,19,43], # precuneus
    [24,19,43]  # precuneus
]
### convert 3D coordinates to 1D vector index
needed_inds = [
    (voxs_to_use.ravel().nonzero() == np.array(ravel_index(x, ref_img.shape))).ravel().nonzero()[0][0]
    for x in needed_coordinates
]
bad_subs3 = ~all_masks[needed_inds,:].all(axis=0)
## Part 3
### coordinates
needed_coordinates = [
    [24,30,49], 
    [27,29,48], 
    [27,15,37], 
    [27,50,44], 
    [46,54,25], 
    [45,54,27], 
    [30,39,23], 
    [37,14,23], 
    [23,14,23], 
    [23,62,29], 
    [29,40,24], 
    [18,41,19], 
    [42,41,19], 
]
### convert 3D coordinates to 1D vector index
needed_inds = [
    (voxs_to_use.ravel().nonzero() == np.array(ravel_index(x, ref_img.shape))).ravel().nonzero()[0][0]
    for x in needed_coordinates
]
bad_subs4 = ~all_masks[needed_inds,:].all(axis=0)

print "...combining all the subjects with subpar coverage"
bad_coverage_subs = bad_subs1 | bad_subs2 | bad_subs3 | bad_subs4
qc_summary["bad_coverage"] = bad_coverage_subs*1
print "...total of %i / %i" % (len(details[bad_coverage_subs].id.unique()), len(details.id.unique()))

print "...getting and saving voxels with scans not present in n subjects"
mask_nscans             = all_masks[:,~bad_coverage_subs].sum(axis=1)
mask_img                = ref_mask.astype(np.float64)
mask_img[voxs_to_use]   = sum(~bad_coverage_subs) - mask_nscans
mask_img                = nib.Nifti1Image(mask_img, aff, hdr)
mask_img.set_data_dtype(np.float64)
mask_img.to_filename('02_mask_nbadscans.nii.gz')

print "...saving mask"
mask_img                = ref_mask.astype(np.float64)
mask_img[voxs_to_use]   = mask_nscans == sum(~bad_coverage_subs)
mask_img                = nib.Nifti1Image(mask_img, aff, hdr)
mask_img.set_data_dtype(np.float64)
mask_img.to_filename('02_mask_group.nii.gz')


###
# Check movement/registration via comparison btw func and average
###

print "Comparing each subject's functional to average"

print "...reading in standard brain"
standard = os.path.join(os.getenv('FSLDIR'), 'data/standard/MNI152_T1_%imm_brain.nii.gz' % resolution)
std_img = nib.load(standard)
std = std_img.get_data()[voxs_to_use]

print "...creating matrices"
all_means   = np.zeros((ref_mask.sum(), len(details)))
grp_mean    = np.zeros((ref_mask.sum()))

print "...gathering images and calculating mean"
pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.T.iteritems():
    pb.update(i+1)
    fname = path.join(row['func_outdir'], "func/mean_functional_in_mni.nii.gz")
    img = nib.load(fname)
    data = img.get_data()
    all_means[:,i] = data[voxs_to_use]
    grp_mean += data[voxs_to_use]
grp_mean /= len(details)
pb.finish()

print "...computing correlations with mean and saving"
cors = custom_corrcoef(grp_mean, all_means)
zcors = stats.zscore(np.arctanh(cors))
qc_values["func_mean_zcor"] = zcors
# subdetails = details[zcors<-2]
# subdetails['mean_cor'] = cors[zcors<-2]
# subdetails['mean_zcor'] = zcors[zcors<-2]
# subdetails.to_csv("03_correlations_with_mean_func.csv")
## zcors<-2 all have huge signal increase in the front of the brain, what to do about this?

print "...computing correlations with std brain and saving"
cors = custom_corrcoef(std[std!=0], all_means[std!=0,:])
zcors = stats.zscore(np.arctanh(cors))
qc_values["func_std_zcor"] = zcors
# subdetails = details[zcors<-2]
# subdetails['mean_cor'] = cors[zcors<-2]
# subdetails['mean_zcor'] = zcors[zcors<-2]
# subdetails.to_csv("03_correlations_with_std_func.csv")


###
# Check movement/registration via comparison btw anat and average
###

print "Comparing each subject's anatomical to the average"

print "...creating matrices"
nvoxs = ref_mask[voxs_to_use].sum()
all_means   = np.zeros((nvoxs, len(details)))
grp_mean    = np.zeros((nvoxs))

print "...gathering images and calculating mean"
pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.T.iteritems():
    pb.update(i+1)
    fname = path.join(row['anat_outdir'], "anat/mni_normalized_anatomical.nii.gz")
    img = nib.load(fname)
    data = img.get_data()
    tmp = data[voxs_to_use]
    all_means[:,i] = tmp
    grp_mean += tmp
grp_mean /= len(details)
pb.finish()

print "...computing correlations with mean and saving"
cors = custom_corrcoef(grp_mean, all_means)
zcors = stats.zscore(np.arctanh(cors))
qc_values["anat_mean_zcor"] = zcors
# subdetails = details.copy()
# subdetails['mean_cor'] = cors
# subdetails['mean_zcor'] = zcors
# subdetails.to_csv("04_correlations_with_mean_anat.csv")
## zcors<-2 all have huge signal increase in the front of the brain, what to do about this?

print "...getting percent non-zero voxels and saving"
percent_nonzero = np.apply_along_axis(lambda x: mean(x!=0), 0, all_means)
percent_nonzero = percent_nonzero * 100
z_percent_nonzero = stats.zscore(percent_nonzero)
qc_values["anat_percent_voxs"] = z_percent_nonzero
# subdetails = details.copy()
# subdetails['percent_nonzero'] = percent_nonzero
# subdetails['z_percent_nonzero'] = z_percent_nonzero
# subdetails.to_csv("04_correlations_with_mean_anat.csv")

print "...creating matrices"
nvoxs = ref_mask[voxs_to_use][std!=0].sum()
all_means   = np.zeros((nvoxs, len(details)))
grp_mean    = np.zeros((nvoxs))

print "...gathering images"
pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
for i,row in details.T.iteritems():
    pb.update(i+1)
    fname = path.join(row['anat_outdir'], "anat/mni_normalized_anatomical.nii.gz")
    img = nib.load(fname)
    data = img.get_data()
    all_means[:,i] = data[voxs_to_use][std!=0]
pb.finish()

print "...computing correlations with std brain and saving"
std_touse = std[std!=0]
cors = custom_corrcoef(std_touse, all_means)
zcors = stats.zscore(np.arctanh(cors))
qc_values["anat_std_zcor"] = zcors
# subdetails = details.copy()
# subdetails['mean_cor'] = cors
# subdetails['mean_zcor'] = zcors
# subdetails.to_csv("04_correlations_with_std_anat.csv")

qc_summary["bad_anat"] = ((qc_values["anat_mean_zcor"]<-2) | \
                            (qc_values["anat_percent_voxs"]<-2) | \
                            (qc_values["anat_std_zcor"]<-2))*1




###
# Calculate SNR
### 

print "Calculating SNR for each subject and comparing it to the group mean"

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
    snr   = tmp.std(axis=1)/tmp.mean(axis=1)
    snr[np.isnan(snr)] = 0
    all_snr[:,i]  = snr
    all_mean_snrs = (snr[all_masks[:,i]==1]).mean()
    grp_snr      += snr
grp_snr /= len(details)
pb.finish()

print "...computing correlations with mean and saving"
cors = custom_corrcoef(grp_snr, all_snr)
zcors = stats.zscore(np.arctanh(cors))
subdetails = details.copy()
subdetails['mean_snr']  = all_mean_snrs
subdetails['mean_cor']  = cors
subdetails['mean_zcor'] = zcors
subdetails.to_csv("05_snr_correlations_with_mean.csv")

