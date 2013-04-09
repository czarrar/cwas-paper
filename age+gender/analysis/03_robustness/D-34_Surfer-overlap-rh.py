#!/usr/bin/env python

# Save images for the LDOPA results on the left-hemisphere

from surfer import Brain, io
from os import path
import numpy as np

overlap_dir = "/home2/data/Projects/CWAS/age+gender/03_robustness/cwas/overlap"

## AGE

"""Bring up the visualization"""
brain = Brain("fsaverage_copy", "rh", "iter8_inflated",
              config_opts=dict(background="white"), 
              subjects_dir="/home2/data/PublicProgram/freesurfer")

"""Project the volume file and return as an array"""
cwas_file = path.join(overlap_dir, "surf_rh_fdr_logp_age_thr2.nii.gz")

"""
You can pass this array to the add_overlay method for
a typical activation overlay (with thresholding, etc.)
"""
brain.add_overlay(cwas_file, min=1, max=3, name="tmp1")

# Update color bar

## get overlay and color bar
tmp1 = brain.overlays["tmp1"]
lut = tmp1.pos_bar.lut.table.to_array()

## update color scheme
single = [251, 154, 143]
overlap = [227, 26, 28]
lut[0:85,0:3] = single
lut[85:170,0:3] = single
lut[170:256,0:3] = overlap
tmp1.pos_bar.lut.table = lut

## refresh view
brain.show_view("lat")
brain.hide_colorbar()

"""Save Pictures"""
odir = "/home/data/Projects/CWAS/age+gender/03_robustness/viz_cwas/pysurfer"
brain.save_imageset(path.join(odir, "zpics_overlap_age_surface_rh"), 
                    ['med', 'lat', 'ros', 'caud'], 'jpg')

brain.close()


## SEX

"""Bring up the visualization"""
brain = Brain("fsaverage_copy", "rh", "iter8_inflated",
              config_opts=dict(background="white"), 
              subjects_dir="/home2/data/PublicProgram/freesurfer")

"""Project the volume file and return as an array"""
cwas_file = path.join(overlap_dir, "surf_rh_fdr_logp_sex_thr2.nii.gz")

"""
You can pass this array to the add_overlay method for
a typical activation overlay (with thresholding, etc.)
"""
brain.add_overlay(cwas_file, min=1, max=3, name="tmp1")

# Update color bar

## get overlay and color bar
tmp1 = brain.overlays["tmp1"]
lut = tmp1.pos_bar.lut.table.to_array()

## update color scheme
single = [251, 154, 143]
overlap = [227, 26, 28]
lut[0:85,0:3] = single
lut[85:170,0:3] = single
lut[170:256,0:3] = overlap
tmp1.pos_bar.lut.table = lut

## refresh view
brain.show_view("lat")
brain.hide_colorbar()

"""Save Pictures"""
odir = "/home/data/Projects/CWAS/age+gender/03_robustness/viz_cwas/pysurfer"
brain.save_imageset(path.join(odir, "zpics_overlap_sex_surface_rh"), 
                    ['med', 'lat', 'ros', 'caud'], 'jpg')

brain.close()

