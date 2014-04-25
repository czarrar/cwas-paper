#!/home2/data/PublicProgram/epd-7.2-2-rh5-x86_64/bin/python

"""
This script will plot IQ CWAS (scans 1 and 2), Neurosynth (Intelligence, Reasoning, and WM), and the Overlap.
"""

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
import numpy as np
from surfer import io
from os import path as op
from newsurf import *


###
# Setup (General)
###

base = "/home2/data/Projects/CWAS"
odir = op.join(base, "figures/sfig_neurosynth")

# paths to cwas
sdir = "compcor_kvoxs_fwhm08_to_kvoxs_fwhm08"
mdir = "iq_age+sex+meanFD.mdmr"
edir = "cluster_correct_v05_c05/easythresh"
#edir = "cluster_correct_v05_c05"
easydirs = {
    "short":    op.join(base, "nki/cwas/short", sdir, mdir, edir), 
    "medium":   op.join(base, "nki/cwas/medium", sdir, mdir, edir)
}


###
# Setup (Scan)
###

scans = ["short", "medium"]

# paths to cwas
all_surf_files = {}
all_sfiles = []

for scan in scans:
    easydir = easydirs[scan]
    all_surf_files[scan] = {
        "lh": op.join(easydir, "surfs/surf_thresh_zstat_FSIQ_lh.nii.gz"), 
        "rh": op.join(easydir, "surfs/surf_thresh_zstat_FSIQ_rh.nii.gz")
    }
    all_sfiles.extend(all_surf_files[scan].values())


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

print 'getting range'
ranges = np.array([ get_range(sfile) for sfile in all_sfiles ])
dmin = ranges.min()
dmax = ranges.max()
print 'min=%.4f; max=%.4f' % (dmin,dmax)


###
# Neurosynth
###

def run(cmd):
    print(cmd)
    os.system(cmd)

prefix              = op.join(odir, "surf_neurosynth")
ns_combined_dir     = op.join(base, "neurosynth/neurosynth/intelligence_reasoning_wm")
cmd = "./x_vol2surf.py %s/_pAgF_z.nii.gz %s/_pAgF_z_FDR_0.05.nii.gz %s" % (ns_combined_dir, ns_combined_dir, prefix)
#run(cmd)
ns_combined         = { hemi : io.read_scalar_data("%s_%s.nii.gz" % (prefix, hemi)) for hemi in ["lh", "rh"] }
all_ns              = ns_combined.values()

print 'getting range'
dmin2 = np.array([ ns[ns.nonzero()].min() for ns in all_ns ]).min()
dmax2 = np.array([ ns[ns.nonzero()].max() for ns in all_ns ]).max()
print 'min=%.4f; max=%.4f' % (dmin2,dmax2)


###
# Overlap
###

scans_and_ns = {}
for hemi in ["lh", "rh"]:
    # 1. Combine IQ CWAS Scan 1 and 2
    short   = io.read_scalar_data(all_surf_files["short"][hemi])
    medium  = io.read_scalar_data(all_surf_files["medium"][hemi])
    combine = (short > 0) | (medium > 0)
    
    # 2. Get the overlap of neurosynth with the combined results
    overlap = combine & (ns_combined[hemi]>0)
    scans_and_ns[hemi] = overlap * 1



###
# Hemisphere
###

# Each Scan
for i,scan in enumerate(scans):
    surf_files  = all_surf_files[scan]
    oprefix     = op.join(odir, "A_surface_cwas%i_and_neurosynth" % i)
    
    for hemi in ["lh","rh"]:
        cwas    = io.read_scalar_data(surf_files[hemi])
        nsynth  = ns_combined[hemi]
        
        overlap = cwas * nsynth
        overlap = (overlap>0)*1
        cbar    = load_colorbar(np.array(([[255,255,0,255]])))
        dmin3   = overlap[overlap.nonzero()].min()
        dmax3   = overlap.max()
        
        brain   = fsaverage(hemi)
        brain   = add_overlay("cwas", brain, cwas, "Blues", 
                              dmin, dmax, "pos")
        brain   = add_overlay("neurosynth", brain, nsynth, "Purples", 
                              dmin2, dmax2, "pos")
        brain   = add_overlay("overlap", brain, overlap, cbar, 
                              dmin3, dmax3, "pos")
        
        save_imageset(brain, oprefix, hemi)

    montage(oprefix, compilation='box')
    montage(oprefix, compilation='horiz')

# Overlap
oprefix     = op.join(odir, "B_surface_cwas_combined_and_neurosynth")
for hemi in ["lh","rh"]:
    overlap = scans_and_ns[hemi]
    
    cbar    = load_colorbar(np.array(([[255,255,0,255]])))
    dmin3   = overlap[overlap.nonzero()].min()
    dmax3   = overlap.max()
    
    brain   = fsaverage(hemi)
    brain   = add_overlay("overlap", brain, overlap, cbar, 
                          dmin3, dmax3, "pos")
    save_imageset(brain, oprefix, hemi)
    
montage(oprefix, compilation='box')
montage(oprefix, compilation='horiz')
