#!/usr/bin/env python

# Save images for the LDOPA results on the right-hemisphere

from surfer import Brain, io
from os import path
import numpy as np

mdmr_dir = "/home2/data/Projects/CWAS/ldopa/cwas/rois_random_k3200/age_sex+tr.mdmr"

"""Bring up the visualization"""
brain = Brain("fsaverage_copy", "rh", "iter8_inflated",
              config_opts=dict(background="white"), 
              subjects_dir="/home2/data/PublicProgram/freesurfer")

"""Project the volume file and return as an array"""
mri_file = path.join(mdmr_dir, "mni305_log_fdr_pvals_drug.nii.gz")
reg_file = path.join(mdmr_dir, "mni305_log_fdr_pvals_drug.nii.gz.reg")
surf_data = io.project_volume_data(mri_file, "rh", reg_file)

"""
You can pass this array to the add_overlay method for
a typical activation overlay (with thresholding, etc.)
"""
brain.add_overlay(surf_data, min=1.3, max=2.5, name="ang_corr")


###############################################################################
# save some images
odir = "/home/data/Projects/CWAS/ldopa/viz"
brain.save_imageset(path.join(odir, "zpics_surface_rh"), 
                    ['med', 'lat', 'ros', 'caud'], 'jpg')

brain.close()

