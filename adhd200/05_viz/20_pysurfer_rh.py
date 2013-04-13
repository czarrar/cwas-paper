#!/usr/bin/env python

# Save images for the LDOPA results on the left-hemisphere

from surfer import Brain, io
from os import path
import numpy as np
import nibabel as nib

cols = np.loadtxt("z_red_yellow.txt")   # Load color table

## Just age

print "just age"

mdmr_dir = "/home2/data/Projects/CWAS/development+motion/cwas/rois_random_k3200/age_sex+tr.mdmr"
factor = "age"

"""Bring up the visualization"""
brain = Brain("fsaverage_copy", "rh", "iter8_inflated",
              config_opts=dict(background="white"), 
              subjects_dir="/home2/data/PublicProgram/freesurfer")

"""Get the volume => surface file"""
cwas_file = path.join(mdmr_dir, "surf_rh_clust_logp_%s.nii.gz" % factor)


"""Project the volume file and return as an array"""
orig_file = path.join(mdmr_dir, "clust_logp_%s.nii.gz" % factor)

"""Load the output data and get maximum value"""
img = nib.load(orig_file)
data = img.get_data()
data_max = data.max()
if data_max == 0:
    data_min = 0
else:
    data_min = data[data.nonzero()].min()

"""
You can pass this array to the add_overlay method for
a typical activation overlay (with thresholding, etc.)
"""
brain.add_overlay(cwas_file, min=data_min, max=data_max, name="%s_rh" % factor)

## get overlay and color bar
tmp1 = brain.overlays["%s_rh" % factor]
lut = tmp1.pos_bar.lut.table.to_array()

## update color scheme
lut[:,0:3] = cols
tmp1.pos_bar.lut.table = lut

## refresh view
brain.show_view("lat")
brain.hide_colorbar()

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
factor = "age"

"""Bring up the visualization"""
brain = Brain("fsaverage_copy", "rh", "iter8_inflated",
              config_opts=dict(background="white"), 
              subjects_dir="/home2/data/PublicProgram/freesurfer")

"""Get the volume => surface file"""
cwas_file = path.join(mdmr_dir, "surf_rh_clust_logp_%s.nii.gz" % factor)


"""Project the volume file and return as an array"""
orig_file = path.join(mdmr_dir, "clust_logp_%s.nii.gz" % factor)

"""Load the output data and get maximum value"""
img = nib.load(orig_file)
data = img.get_data()
data_max = data.max()
if data_max == 0:
    data_min = 0
else:
    data_min = data[data.nonzero()].min()

"""
You can pass this array to the add_overlay method for
a typical activation overlay (with thresholding, etc.)
"""
brain.add_overlay(cwas_file, min=data_min, max=data_max, name="%s_rh" % factor)

## get overlay and color bar
tmp1 = brain.overlays["%s_rh" % factor]
lut = tmp1.pos_bar.lut.table.to_array()

## update color scheme
lut[:,0:3] = cols
tmp1.pos_bar.lut.table = lut

## refresh view
brain.show_view("lat")
brain.hide_colorbar()

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
factor = "mean_FD"

"""Bring up the visualization"""
brain = Brain("fsaverage_copy", "rh", "iter8_inflated",
              config_opts=dict(background="white"), 
              subjects_dir="/home2/data/PublicProgram/freesurfer")

"""Get the volume => surface file"""
cwas_file = path.join(mdmr_dir, "surf_rh_clust_logp_%s.nii.gz" % factor)

"""Project the volume file and return as an array"""
orig_file = path.join(mdmr_dir, "clust_logp_%s.nii.gz" % factor)

"""Load the output data and get maximum value"""
img = nib.load(orig_file)
data = img.get_data()
data_max = data.max()
if data_max == 0:
    data_min = 0
else:
    data_min = data[data.nonzero()].min()

"""
You can pass this array to the add_overlay method for
a typical activation overlay (with thresholding, etc.)
"""
brain.add_overlay(cwas_file, min=data_min, max=data_max, name="%s_rh" % factor)

## get overlay and color bar
tmp1 = brain.overlays["%s_rh" % factor]
lut = tmp1.pos_bar.lut.table.to_array()

## update color scheme
lut[:,0:3] = cols
tmp1.pos_bar.lut.table = lut

## refresh view
brain.show_view("lat")
brain.hide_colorbar()

"""
Save some images
"""
odir = "/home/data/Projects/CWAS/development+motion/viz"
brain.save_imageset(path.join(odir, "zpics_surface_%s_rh" % "motion_with_age"), 
                    ['med', 'lat', 'ros', 'caud'], 'jpg')

brain.close()
