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

# Motion Related Functions
rms = lambda x: sqrt(mean(x**2))
euclidean_distance = lambda x: sqrt(sum(x**2))
rotation_deg_to_mm = lambda x: 2*pi*50*(x/360)  # based on Power et al.
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



###
# Start
###

preproc = "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98"

basedir = "/home2/data/Projects/NKI_ROCKLAND_CPAC_test/Sink/sym_links"
os.chdir(basedir)

subinfo_dir = "/home2/data/Projects/CWAS/share/nki/subinfo"
roi_dir = "/home2/data/Projects/CWAS/nki/rois"

# Read in phenotypic data
fname = path.join(subinfo_dir, "20_raw_coins_ids.csv")
details = read_csv(fname)

# Remove two subjects with incomplete data
inds = (details.Id != "M10921498") & (details.Id != "M10944344")
details = details[inds]

# Find subject paths
# note: need to consolidate two different preprocessing batches
#       each with different IDs
preproc1 = path.join(basedir, "pipeline_OakhurstCity", preproc)     # Coins
preproc2 = path.join(basedir, "pipeline_CheboyganCity", preproc)    # INDI
# preproc1 is the default base path
# if not there, then set preproc2 as base path
subdirs = []
release = []
for Id in details.Id:
    search = glob("%s/%s*_session_1" % (preproc1, Id))
    if len(search) == 0:
        search = glob("%s/%s_session_1" % (preproc2, Id.replace("M109", "01")))
        release.append(2)
    else:
        release.append(1)
        
    if len(search) == 0:
        print 'id %s not found' % Id
        subdirs.append(None)
    elif len(search) > 1:
        print 'more then one folder found for id %s' % Id
        subdirs.append(None)
    else:
        subdir = search[0].replace(basedir + "/", "")
        subdirs.append(subdir)
# add
details['subdir'] = subdirs
details['release'] = release
details.index = range(len(details))

# Create anatomical data frame
anat = details[['Id', 'release']]
anat['dir'] = details.subdir + "/scan/anat"
anat['exists'] = [ path.exists(adir) for adir in anat['dir'] ]  # should all be there!

# Create the functional data frames (short and medium are multi-band)
## short
func_short = details[['Id', 'release']]
func_short['dir'] = details.subdir
func_short['dir'][func_short.release == 1] += "/scan_RfMRI_mx_645_rest_RPI"
func_short['dir'][func_short.release == 2] += "/scan_RfMRI_mx_645_rest"
## medium
func_medium = details[['Id', 'release']]
func_medium['dir'] = details.subdir
func_medium['dir'][func_medium.release == 1] += "/scan_RfMRI_mx_1400_rest_RPI"
func_medium['dir'][func_medium.release == 2] += "/scan_RfMRI_mx_1400_rest"
## long
func_long = details[['Id', 'release']]
func_long['dir'] = details.subdir
func_long['dir'][func_long.release == 1] += "/scan_RfMRI_std_2500_rest_RPI"
func_long['dir'][func_long.release == 2] += "/scan_RfMRI_std_2500_rest"
## combine
funcs = [func_short, func_medium, func_long]
## check which paths exist
for func in funcs:
    func['exists'] = [ path.exists(fdir) for fdir in func['dir'] ]

# Remove subjects with absolutely no rest data
inds = func_short.exists | func_medium.exists | func_long.exists
details = details[inds]
anat = anat[inds]
func_short = func_short[inds]
func_medium = func_medium[inds]
func_long = func_long[inds]

# Redo indices and combine
details.index = range(len(details))
anat.index = range(len(anat))
func_short.index = range(len(func_short))
func_medium.index = range(len(func_medium))
func_long.index = range(len(func_long))
funcs = [func_short, func_medium, func_long]

# To dispay progress bar and stuff
widgets = ['Progress: ', Percentage(), ' ', Bar(), ' ', Counter(), '/%i' % len(details), ' ', ETA()]



###
# Get motion info
###

print "\nGetting motion stuff"

for func in funcs:
    # new columns
    func['mean_FD'] = np.zeros(len(func))
    func['max_FD'] = np.zeros(len(func))
    func['mean_relative_motion'] = np.zeros(len(func))
    func['max_relative_motion'] = np.zeros(len(func))
    func['num_movements'] = np.zeros(len(func), dtype=np.int)
    
    # do it
    pb = ProgressBar(widgets=widgets, maxval=len(func)).start()
    for i,row in func[func.exists].iterrows():
        pb.update(i+1)
        # mean framewise displacement
        fd = np.loadtxt("%s/parameters/frame_wise_displacement.1D" % row['dir'])
        func['mean_FD'][i] = fd.mean()
        func['max_FD'][i] = fd.max()
        # get relative motion
        fname = '%s/parameters/movement_parameters.1D' % row['dir']
        motion_params = np.loadtxt(fname)
        motion_params[:,0:3] = np.apply_along_axis(rotation_deg_to_mm, 0, motion_params[:,0:3])
        rel_motion_params = np.apply_along_axis(diff, 1, motion_params)
        # only look at translations for relative motion
        rel_motion = np.apply_along_axis(euclidean_distance, 1, rel_motion_params[:,3:6]) 
        # save mean, max, and # of movements > 1mm
        func['mean_relative_motion'][i] = mean(rel_motion)
        func['max_relative_motion'][i] = max(rel_motion)
        func['num_movements'][i] = sum(rel_motion>1)
    pb.finish()

# Save motion info
names = ["short", "medium", "long"]
for i in range(3):
    func = funcs[i]; name = names[i]
    motion_df = func[["Id", "release", "dir", "exists", "mean_FD", "max_relative_motion"]]
    motion_df.to_csv("%s/qc-1_meanFD_func_%s.csv" % (subinfo_dir, name))

# QC table with 1 or 0 for good or bad
qc_summaries = [ func[["Id", "release", "exists"]] for func in funcs ]


###
# Check motion
###

print "\nChecking motion"
print "...identifying subjects with mean FD outside two times the interquartile range"

bad_elems = [ large_outliers(func[func.exists].mean_FD) for func in funcs ]
for i in range(3):
    qc_summaries[i]["bad_motion"][funcs[i].exists] = bad_elems[i]*1



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

nsubs = len(details)

print "...looping through functionals"
list_all_masks = []
list_overlap_masks = []
for func in funcs:
    print "\t...creating matrices to hold all subject masks & overlap across masks"
    all_masks       = np.zeros((ref_nvoxs, func.exists.sum()))
    overlap_mask    = np.zeros((ref_nvoxs))
    
    print "\t...gathering brain masks"
    j = 0
    pb = ProgressBar(widgets=widgets, maxval=nsubs).start()
    for i,row in func[func.exists].iterrows():
        pb.update(i+1)
        fname   = path.join(row['dir'], "func", 
                    "functional_brain_mask_to_standard.nii.gz")
        img     = nib.load(fname)
        data    = img.get_data()
        all_masks[:,j]  = data[voxs_to_use]
        overlap_mask   += data[voxs_to_use]
        j += 1
    
    print "\t...storing in list"
    list_all_masks.append(all_masks)
    list_overlap_masks.append(overlap_mask)
    pb.finish()

percent_overlap_masks = []
for i,overlap_mask in enumerate(list_overlap_masks):
    name = names[i]
    print name
    mask_percent_overlap    = (overlap_mask/len(details))*100
    percent_overlap_masks.append(mask_percent_overlap)
    mask_img                = ref_mask.astype(np.float32)
    mask_img[voxs_to_use]   = mask_percent_overlap
    mask_img                = nib.Nifti1Image(mask_img, aff, hdr)
    mask_img.set_data_dtype(np.float32)
    ofile = path.join(roi_dir, 
                "qc-1_%s_percent_overlap_%imm.nii.gz" % (name, resolution))
    mask_img.to_filename(ofile)

for i,all_masks in enumerate(list_all_masks):
    name = names[i]
    print name
    new_shape = tuple(list(ref_img.shape) + [all_masks.shape[1]])
    all_img = np.zeros(new_shape, dtype=np.float32)
    all_img[voxs_to_use,:] = all_masks
    new_hdr = hdr.copy()
    new_hdr.set_data_shape(new_shape)
    new_hdr.set_xyzt_units('mm', 1)
    all_img = nib.Nifti1Image(all_img, aff, new_hdr)
    all_img.set_data_dtype(np.float32)
    ofile = path.join(roi_dir, "qc-1_%s_all_masks_%imm.nii.gz" % (name, resolution))
    all_img.to_filename(ofile)


###
# Determine subjects to exclude based on coverage
###

print "\nDeterming subjects to exclude based on brain masks"

for i,mask_percent_overlap in enumerate(percent_overlap_masks):
    name = names[i]
    all_masks = list_all_masks[i]
    
    # get relative to 90% of subjects
    print "...getting each subject's overlap with overlap mask >90%"
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
    
    print "...getting subjects that have signal in particular voxels"
    # Compile some voxels that must be present in all subjects
    ## coordinates
    needed_coordinates = [
        [45,76,56], 
        [45,85,53]
    
    ]
    ## convert 3D coordinates to 1D vector index
    needed_inds = [
        (voxs_to_use.ravel().nonzero() == np.array(ravel_index(x,  ref_img.shape))).ravel().nonzero()[0][0]
        for x in needed_coordinates
    ]
    bad_subs2 = ~all_masks[needed_inds,:].all(axis=0)
    
    print '...saving summary info'
    bad_subs = bad_subs1 | bad_subs2
    funcs[i]['coverage_missing'] = 0.0
    funcs[i]['coverage_missing'][funcs[i].exists] = subjs_nmissing
    qc_summaries[i]["bad_coverage"] = 0
    qc_summaries[i]["bad_coverage"][funcs[i].exists] = bad_subs*1
    
    print '...saving mask for bad scans'
    mask_nscans             = all_masks[:,bad_subs].sum(axis=1)
    mask_img                = ref_mask.astype(np.float32)
    mask_img[voxs_to_use]   = mask_nscans
    mask_img                = nib.Nifti1Image(mask_img, aff, hdr)
    mask_img.set_data_dtype(np.float32)
    mask_img.to_filename(path.join(roi_dir, "qc-2_%s_mask_nbadscans.nii.gz" % name))
    
    print '...saving mask for good scans'
    mask_nscans             = all_masks[:,~bad_subs].sum(axis=1)
    mask_img                = ref_mask.astype(np.float32)
    mask_img[voxs_to_use]   = mask_nscans == sum(~bad_subs)
    mask_img                = nib.Nifti1Image(mask_img, aff, hdr)
    mask_img.set_data_dtype(np.float32)
    mask_img.to_filename(path.join(roi_dir, 'qc-2_%s_mask_group.nii.gz' % name))



###
# Check movement/registration via comparison btw anat and average
###

print "\nComparing each subject's anatomical to the average"

print "...creating matrices"
nvoxs = ref_mask[voxs_to_use].sum()
all_means   = np.zeros((nvoxs, len(details)))
grp_mean    = np.zeros((nvoxs))

print "...gathering images and calculating mean"
pb = ProgressBar(widgets=widgets, maxval=len(anat)).start()
for i,row in anat.iterrows():
    pb.update(i+1)
    fname = path.join(basedir, row['dir'], "mni_normalized_anatomical.nii.gz")
    img = nib.load(fname)
    data = img.get_data()
    tmp = data[voxs_to_use]
    all_means[:,i] = tmp
    grp_mean += tmp
grp_mean /= len(anat)
pb.finish()

print "...computing correlations with mean and saving"
cors = Series(custom_corrcoef(grp_mean, all_means))
anat["mean_cor"] = cors
bad_anat1 = large_outliers(cors)

print "...getting percent non-zero voxels and saving"
percent_nonzero = np.apply_along_axis(lambda x: mean(x!=0), 0, all_means)
percent_nonzero = percent_nonzero * 100
anat["percent_voxs"] = Series(percent_nonzero)
bad_anat2 = large_outliers(Series(percent_nonzero))

for i in range(len(qc_summaries)):
    qc_summaries[i]["bad_anat"] = (bad_anat1|bad_anat2)*1



###
# Calculate SNR
### 

print "\nCalculating SNR for each subject and comparing it to the group mean"

print "...creating matrices"
nvoxs   = ref_mask.sum()
#all_snr = np.zeros((nvoxs, len(func[func.exists])))
#grp_snr = np.zeros((nvoxs))

print "...gathering images and calculating SNR + mean SNR"
list_mean_snrs = []
for func in funcs:
    print "func"
    mean_snrs = np.zeros((len(func[func.exists])))
    j = 0
    pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
    for i,row in func[func.exists].iterrows():
        pb.update(i+1)
        fname = path.join(basedir, row['dir'], "func/bandpass_freqs_0.009.0.1/functional_mni.nii.gz")
        img   = nib.load(fname)
        data  = img.get_data()
        fname = path.join(basedir, row['dir'], "func/functional_brain_mask_to_standard.nii.gz")
        img   = nib.load(fname)
        mask  = img.get_data()
        tmp   = data[mask==1,:]
        snr   = (tmp.std(axis=1)/tmp.mean(axis=1)) * 100
        snr[np.isnan(snr)] = 0
        mean_snrs[j] = snr.mean()
        j += 1
    #grp_snr /= len(func[func.exists])
    pb.finish()
    list_mean_snrs.append(mean_snrs)

for i,func in enumerate(funcs):
    mean_snrs = list_mean_snrs[i]
    # save snr values
    func["snr"] = 0.0
    func.snr[func.exists] = mean_snrs
    # get outlier scans
    nz_inds = mean_snrs!=0
    bad_subs = np.repeat(True, len(mean_snrs))
    bad_subs[nz_inds] = small_outliers(Series(mean_snrs[nz_inds]))
    # save bad ones
    qc_summaries[i]["bad_snr"] = 0
    qc_summaries[i]["bad_snr"][func.exists] = bad_subs*1



# ###
# # fALFF
# ###
# 
# print "\nGathering fALFF for each subject and comparing it to the group mean"
# 
# print "...creating matrices"
# nvoxs   = ref_mask.sum()
# all_mean_falff = np.zeros((func.exists.sum()))
# all_falff = np.zeros((nvoxs, func.exists.sum()))
# grp_falff = np.zeros((nvoxs))
# 
# print "...gathering images and mean"
# all_masks = list_all_masks[h]
# j = 0
# pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
# for i,row in func[func.exists].iterrows():
#     pb.update(i+1)
#     fname = path.join(basedir, row['dir'], "alff/hp_0.009/lp_0.1/falff_Z_to_standard.nii.gz")
#     img   = nib.load(fname)
#     data  = img.get_data()
#     tmp   = data[voxs_to_use]
#     all_falff[:,j] = tmp
#     grp_falff     += tmp
#     all_mean_falff[i] = tmp[all_masks[:,j]==1].mean()
#     j += 1
# grp_falff /= func.exists.sum()
# pb.finish()
# 
# qc_values["falff_zcor"] = stats.zscore(all_mean_falff)
# 
# print "...computing correlations with mean and saving"
# cors = custom_corrcoef(grp_falff, all_falff)
# qc_values["falff_mean_zcor"] = 0.0
# zcors = stats.zscore(np.arctanh(cors[all_mean_falff!=0]))
# qc_values["falff_mean_zcor"][all_mean_falff!=0] = zcors
# 
# 
# ###
# # Degree Centrality
# ###
# 
# print "\nGathering degree centrality for each subject and comparing it to the group mean"
# 
# print "...creating matrices"
# nvoxs   = ref_mask.sum()
# all_mean_degree = np.zeros((func.exists.sum()))
# all_degree = np.zeros((nvoxs, func.exists.sum()))
# grp_degree = np.zeros((nvoxs))
# 
# print "...gathering images and mean"
# all_masks = list_all_masks[h]
# j = 0
# pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
# for i,row in func[func.exists].iterrows():
#     pb.update(i+1)
#     fname = path.join(basedir, row['dir'], "centrality/mask_MNI152_T1_GREY_3mm_50pc/bandpass_freqs_0.01.0.1/degree_centrality_weighted_maths.nii.gz")
#     img   = nib.load(fname)
#     data  = img.get_data()
#     tmp   = data[voxs_to_use]
#     all_degree[:,i] = tmp
#     grp_degree     += tmp
#     all_mean_degree[i] = tmp[all_masks[:,j]==1].mean()
#     j += 1
# grp_degree /= func.exists.sum()
# pb.finish()
# 
# qc_values["degree_zcor"] = stats.zscore(all_mean_degree)
# 
# print "...computing correlations with mean and saving"
# cors = custom_corrcoef(grp_degree, all_degree)
# qc_values["degree_mean_zcor"] = 0.0
# zcors = stats.zscore(np.arctanh(cors[all_mean_degree!=0]))
# qc_values["degree_mean_zcor"][all_mean_degree!=0] = zcors
# 
# 
# ###
# # REHO
# ###
# 
# print "\nGathering REHO for each subject and comparing it to the group mean"
# 
# print "...creating matrices"
# nvoxs   = ref_mask.sum()
# all_mean_reho = np.zeros((func.exists.sum()))
# all_reho = np.zeros((nvoxs, func.exists.sum()))
# grp_reho = np.zeros((nvoxs))
# 
# print "...gathering images and mean"
# all_masks = list_all_masks[i]
# j = 0
# pb = ProgressBar(widgets=widgets, maxval=len(details)).start()
# for i,row in func[func.exists].iteritems():
#     pb.update(i+1)
#     fname = path.join(row['func_outdir'], "reho/bandpass_freqs_0.01.0.1/reho_Z_to_standard.nii.gz")
#     img   = nib.load(fname)
#     data  = img.get_data()
#     tmp   = data[voxs_to_use]
#     all_reho[:,i] = tmp
#     grp_reho     += tmp
#     all_mean_reho[i] = tmp[all_masks[:,i]==1].mean()
#     j += 1
# grp_reho /= len(details)
# pb.finish()
# 
# qc_values["reho_zcor"] = stats.zscore(all_mean_reho)
# 
# print "...computing correlations with mean and saving"
# cors = custom_corrcoef(grp_reho, all_reho)
# qc_values["reho_mean_zcor"] = 0.0
# zcors = stats.zscore(np.arctanh(cors[all_mean_reho!=0]))
# qc_values["reho_mean_zcor"][all_mean_reho!=0] = zcors



###
# Compile Functional Measures
###
for qc_summary in qc_summaries:
    qc_summary["bad_scan"] = np.zeros(len(qc_summary))
    qc_summary.bad_scan = ((qc_summary.bad_motion + 
                            qc_summary.bad_coverage +  
                            qc_summary.bad_snr) > 0)*1

qc_bad_scans = qc_summaries[0][["Id"]]
for i,qc_summary in enumerate(qc_summaries):
    qc_bad_scans[names[i]] = qc_summary.bad_scan
qc_bad_scans["all"] = qc_bad_scans.ix[:,1:].sum(axis=1)

qc_usable_scans = qc_summaries[0][["Id"]]
qc_usable_scans["nscans"] = 0
for i,qc_summary in enumerate(qc_summaries):
    qc_usable_scans.nscans += qc_summary.exists*1
    good = 1 - ((qc_summary.bad_scan + ~qc_summary.exists)>0)*1
    qc_usable_scans[names[i]] = good
qc_usable_scans["all"] = qc_usable_scans.ix[:,2:].sum(axis=1)

# Save usable scan and phenotypic info together
tmp = merge(details, qc_usable_scans, on='Id')
tmp.to_csv(path.join(subinfo_dir, "qc-2_usable_scans.csv"), index=False)

# Save full func information
for i,func in enumerate(funcs):
    outfile = path.join(subinfo_dir, "qc-3_func_%s.csv" % names[i])
    func.to_csv(outfile, index=False)

# Save full qc summaries
for i,qc_summary in enumerate(qc_summaries):
    outfile = path.join(subinfo_dir, "qc-4_summary_%s.csv" % names[i])
    qc_summary.to_csv(outfile, index=False)
    


###
# Combine data frames
###

details["orig_index"] = details.index

phenos = details[["Id", "Age", "Sex", "Handedness", "orig_index"]]

# Remove subject with no sex data
phenos = phenos[~phenos.Sex.isnull()]
phenos.index = range(len(phenos))

# Add in usable scan information
df = merge(phenos, qc_usable_scans, on="Id")

# Add in functional scan info
for i,func in enumerate(funcs):
    name = names[i]
    tmp = func[["Id", "dir", "mean_FD"]]
    tmp.dir[~func.exists] = np.nan
    tmp.columns = ["Id", "%s_dir" % name, "%s_meanFD" % name]
    df = merge(df, tmp, on="Id")

# Save
df.to_csv(path.join(subinfo_dir, "30_phenos+qc+paths.csv"))



