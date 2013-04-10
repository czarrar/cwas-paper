#!/usr/bin/env python

# Save images for the LDOPA results on the left-hemisphere

from surfer import Brain, io
from os import path
import numpy as np

cols = np.loadtxt("z_red_yellow.txt")   # Load color table

mdmr_dir = "/home2/data/Projects/CWAS/ldopa/cwas/rois_random_k3200/ldopa_subjects+meanFD.mdmr"
factor = "drug"

"""Bring up the visualization"""
brain = Brain("fsaverage_copy", "lh", "iter8_inflated",
              config_opts=dict(background="white"), 
              subjects_dir="/home2/data/PublicProgram/freesurfer")

"""Get the volume => surface file"""
cwas_file = path.join(mdmr_dir, "surf_lh_fdr_logp_%s.nii.gz" % factor)

"""
You can pass this array to the add_overlay method for
a typical activation overlay (with thresholding, etc.)
"""
brain.add_overlay(cwas_file, min=1.3, max=2.2, name="%s_lh" % factor)

## get overlay and color bar
tmp1 = brain.overlays["%s_lh" % factor]
lut = tmp1.pos_bar.lut.table.to_array()

## update color scheme
lut[:,0:3] = cols
tmp1.pos_bar.lut.table = lut

## refresh view
brain.show_view("lat")
brain.hide_colorbar()

"""
Save images
"""
odir = "/home/data/Projects/CWAS/ldopa/viz"
brain.save_imageset(path.join(odir, "zpics_surface_lh"), 
                    ['med', 'lat', 'ros', 'caud'], 'jpg')
brain.close()

