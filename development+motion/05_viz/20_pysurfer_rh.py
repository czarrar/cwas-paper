#!/usr/bin/env python

# Save images for the LDOPA results on the left-hemisphere

from surfer import Brain, io
from os import path
import numpy as np
import nibabel as nib


## Just age

print "just age"

mdmr_dir = "/home2/data/Projects/CWAS/development+motion/cwas/rois_random_k3200/age_sex+tr.mdmr"

"""Bring up the visualization"""
brain = Brain("fsaverage", "rh", "inflated",
              config_opts=dict(background="white"))

"""Project the volume file and return as an array"""
mri_file = path.join(mdmr_dir, "mni305_log_fdr_pvals_age.nii.gz")
reg_file = path.join(mdmr_dir, "mni305_log_fdr_pvals_age.nii.gz.reg")
surf_data = io.project_volume_data(mri_file, "rh", reg_file)

"""Load the output data and get maximum value"""
img = nib.load(mri_file)
data = img.get_data()
data_max = data.max()
if data_max == 0:
    data_min = 0
else:
    data_min = 1.3

"""
You can pass this array to the add_overlay method for
a typical activation overlay (with thresholding, etc.)
"""
brain.add_overlay(surf_data, min=data_min, max=data_max, name="ang_corr")

"""
Save some images
"""
odir = "/home/data/Projects/CWAS/development+motion/viz"
brain.save_imageset(path.join(odir, "zpics_surface_%s_rh" % "only_age"), 
                    ['med', 'lat', 'ros', 'caud'], 'jpg')

brain.close()


## Age with motion as covariate

print "age with motion"

mdmr_dir = "/home2/data/Projects/CWAS/development+motion/cwas/rois_random_k3200/age+motion_sex+tr.mdmr"

"""Bring up the visualization"""
brain = Brain("fsaverage", "rh", "inflated",
              config_opts=dict(background="white"))

"""Project the volume file and return as an array"""
mri_file = path.join(mdmr_dir, "mni305_log_fdr_pvals_age.nii.gz")
reg_file = path.join(mdmr_dir, "mni305_log_fdr_pvals_age.nii.gz.reg")
surf_data = io.project_volume_data(mri_file, "rh", reg_file)

"""Load the output data and get maximum value"""
img = nib.load(mri_file)
data = img.get_data()
data_max = data.max()
if data_max == 0:
    data_min = 0
else:
    data_min = 1.3

"""
You can pass this array to the add_overlay method for
a typical activation overlay (with thresholding, etc.)
"""
brain.add_overlay(surf_data, min=data_min, max=data_max, name="ang_corr")

"""
Save some images
"""
odir = "/home/data/Projects/CWAS/development+motion/viz"
brain.save_imageset(path.join(odir, "zpics_surface_%s_rh" % "age_with_motion"), 
                    ['med', 'lat', 'ros', 'caud'], 'jpg')

brain.close()


## Motion with age as covariate

print "motion with age"

mdmr_dir = "/home2/data/Projects/CWAS/development+motion/cwas/rois_random_k3200/age+motion_sex+tr.mdmr"

"""Bring up the visualization"""
brain = Brain("fsaverage", "rh", "inflated",
              config_opts=dict(background="white"))

"""Project the volume file and return as an array"""
mri_file = path.join(mdmr_dir, "mni305_log_fdr_pvals_mean_FD.nii.gz")
reg_file = path.join(mdmr_dir, "mni305_log_fdr_pvals_mean_FD.nii.gz.reg")
surf_data = io.project_volume_data(mri_file, "rh", reg_file)

"""Load the output data and get maximum value"""
img = nib.load(mri_file)
data = img.get_data()
data_max = data.max()
if data_max == 0:
    data_min = 0
else:
    data_min = 1.3

"""
You can pass this array to the add_overlay method for
a typical activation overlay (with thresholding, etc.)
"""
brain.add_overlay(surf_data, min=data_min, max=data_max, name="ang_corr")

"""
Save some images
"""
odir = "/home/data/Projects/CWAS/development+motion/viz"
brain.save_imageset(path.join(odir, "zpics_surface_%s_rh" % "motion_with_age"), 
                    ['med', 'lat', 'ros', 'caud'], 'jpg')

brain.close()
