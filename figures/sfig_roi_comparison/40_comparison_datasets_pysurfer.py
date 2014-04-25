#!/home2/data/PublicProgram/epd-7.2-2-rh5-x86_64/bin/python

# Here we are visualizing the 800 parcellation results for all of the datasets
# although only using IQ scan 1 for ease.

# 1. Get the paths
# 2. Render onto the surface
# 3. Get the min and max
# 4. Show and save

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
import numpy as np
import nibabel as nib
from newsurf import *


###
# Setup

hemis = ["lh", "rh"]
cbarfile = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"

studies = ["development", "adhd", "ldopa", "iq"]
factors = {
    "development": "age", 
    "adhd": "diagnosis", 
    "ldopa": "conditions", 
    "iq": "FSIQ"
}
nstudies = len(studies)

base = "/home2/data/Projects/CWAS"
odir = path.join(base, "figures/sfig_roi_comparison")

# Path to voxelwise data
vox_easy = {
    "development": "development+motion/cwas/compcor_kvoxs_smoothed/age+motion_sex+tr.mdmr/cluster_correct_v05_c05/easythresh", 
    "adhd": "adhd200_rerun/cwas/compcor_kvoxs_fwhm08/adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr/cluster_correct_v05_c05/easythresh", 
    "ldopa": "ldopa/cwas/compcor_kvoxs_smoothed/ldopa_subjects+meanFD.mdmr/cluster_correct_v05_c05/easythresh", 
    "iq": "nki/cwas/short/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh"
}
vox_easy = { k : path.join(base, v) for k,v in vox_easy.iteritems() }

# Path to parcellation data
roi_easy = {
    "development":  "development+motion/cwas/rois_random_k0800_only/age+motion_sex+tr.mdmr/cluster_correct_v05_c05/easythresh", 
    "adhd":  "adhd200_rerun/cwas/compcor_rois_random_k0800_only/adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr/cluster_correct_v05_c05/easythresh", 
    "ldopa":  "ldopa/cwas/rois_random_k0800_only/ldopa_subjects+meanFD.mdmr/cluster_correct_v05_c05/easythresh", 
    "iq":  "nki/cwas/short/compcor_only_rois_random_k0800/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh"
}
roi_easy = { k : path.join(base, v) for k,v in roi_easy.iteritems() }

###


###
# To the surface!

for k,easydir in vox_easy.iteritems():
    cmd = "./x_vol2surf.py %s %s" % (easydir, factors[k])
    print cmd
    os.system(cmd)

for k,easydir in roi_easy.iteritems():
    cmd = "./x_vol2surf.py %s %s" % (easydir, factors[k])
    print cmd
    os.system(cmd)

###


###
# Get minimum and maximum values across the two scans
def get_range(fname):
    img = nib.load(fname)
    data = img.get_data()
    data_max = data.max()
    if data_max == 0:
        data_min = data_max
    else:
        data_min = data[data.nonzero()].min()
    return [data_min, data_max]

# Gets list of files
vox_sfiles = [ path.join(easydir, "surf_thresh_zstat_%s" % factors[k]) for k,easydir in vox_easy.iteritems() ]
roi_sfiles = [ path.join(easydir, "surf_thresh_zstat_%s" % factors[k]) for k,easydir in roi_easy.iteritems() ]
all_sfiles = [] 
for sfile in (vox_sfiles + roi_sfiles):
    for hemi in hemis:
        all_sfiles.append("%s_%s.nii.gz" % (sfile, hemi))

print 'getting range'
ranges = np.array([ get_range(sfile) for sfile in all_sfiles ])
dmin = ranges[ranges.nonzero()].min()
dmax = ranges[ranges.nonzero()].max()
print 'min=%.4f; max=%.4f' % (dmin,dmax)

###



###
# Viz

# Color bar
cbar = load_colorbar(cbarfile)

easy_dicts = {
    "voxels": vox_easy, 
    "parcels": roi_easy
}

for name,easydict in easy_dicts.iteritems():
    print name
    for k,easydir in easydict.iteritems():
        print k
        if k != 'ldopa':
            continue
        oprefix = path.join(odir, "D_%s_%s_easythresh_surface" % (name, k))
        
        for hemi in hemis:
            surf_file = "%s/surf_thresh_zstat_%s_%s.nii.gz" % (easydir, factors[k], hemi)
            surf_data = io.read_scalar_data(surf_file)
            
            brain = fsaverage(hemi)
            brain = add_overlay(k, brain, surf_data, cbar, 
                                dmin, dmax, "pos")
            save_imageset(brain, oprefix, hemi)
    
        montage(oprefix, compilation='box')
        montage(oprefix, compilation='horiz_lh')
        montage(oprefix, compilation='horiz_rh')
        

###

