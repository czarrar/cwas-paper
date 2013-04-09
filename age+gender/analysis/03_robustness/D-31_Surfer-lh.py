#!/usr/bin/env python

# Save images for the LDOPA results on the left-hemisphere

from surfer import Brain, io
from os import path
import numpy as np

cols = np.loadtxt("z_red_yellow.txt")   # Load color table

samples = ["discovery", "replication"]
factors = ["age", "sex"]
max_zvals = [3.5, 3.25]

basedir = "/home2/data/Projects/CWAS/age+gender/03_robustness/cwas"
odir = "/home/data/Projects/CWAS/age+gender/03_robustness/viz_cwas/pysurfer"

for sample in samples:
    
    print "Sample: %s" % sample
    
    for i,factor in enumerate(factors):
        
        print "...factor: %s" % factor
    
        mdmr_dir = path.join(basedir, "%s_rois_random_k3200/age+gender_15k.mdmr" % sample)
    
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
        brain.add_overlay(cwas_file, min=2, max=max_zvals[i], name="%s_lh" % factor)

        ## get overlay and color bar
        tmp1 = brain.overlays["%s_lh" % factor]
        lut = tmp1.pos_bar.lut.table.to_array()

        ## update color scheme
        lut[:,0:3] = cols
        tmp1.pos_bar.lut.table = lut

        ## refresh view
        brain.show_view("lat")
        brain.hide_colorbar()

        """Save Pictures"""
        brain.save_imageset(path.join(odir, "zpics_%s_%s_surface_lh" % (sample, factor)), 
                            ['med', 'lat', 'ros', 'caud'], 'jpg')

        brain.close()

