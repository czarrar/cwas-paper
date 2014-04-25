#!/usr/bin/env python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path
from surfwrap import Brain, io, SurfWrap
import numpy as np
import nibabel as nib


###
# Setup

strategy = "compcor"
scans = ["short", "medium"]

print "strategy: %s; scans: %s" % (strategy, ",".join(scans))

basedir = "/home2/data/Projects/CWAS/nki/cwas"

# Distance Directory
kstr = "kvoxs_fwhm08_to_kvoxs_fwhm08"
dirname = "%s_%s" % (strategy, kstr)
distdirs = [ path.join(basedir, scan, dirname) for scan in scans ]

# MDMR
mname = "iq_age+sex+meanFD.mdmr"
cname = "cluster_correct_v05_c05"
factor = "FSIQ"

# Input pfile
mdmrdirs = [ path.join(distdir, mname) for distdir in distdirs ]
pfiles = [ path.join(mdmrdir, cname, "clust_logp_%s.nii.gz" % factor) for mdmrdir in mdmrdirs ]

# Output prefixes
obase = "/home2/data/Projects/CWAS/figures"
odir = path.join(obase, "fig_03")
if not path.exists(odir): os.mkdir(odir)

###


###
# Get scan overlays

# Scan 1
i = 0
print pfiles[i]
sw1 = SurfWrap()
sw1.set_overlay("overlap", pfiles[i], "red-yellow")
scan1_lh = io.read_scalar_data(sw1.overlay_surf['lh'])
scan1_rh = io.read_scalar_data(sw1.overlay_surf['rh'])

# Scan 2
i = 1
print pfiles[i]
sw2 = SurfWrap()
sw2.set_overlay("overlap", pfiles[i], "red-yellow")
scan2_lh = io.read_scalar_data(sw2.overlay_surf['lh'])
scan2_rh = io.read_scalar_data(sw2.overlay_surf['rh'])

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

print 'getting range'
ranges = np.array([ get_range(pfile) for pfile in pfiles ])
dmin = ranges.min()
dmax = ranges.max()
print 'min=%.4f; max=%.4f' % (dmin,dmax)

###


###
# Create overlap

# Scan 1
scan1_lh[scan1_lh<=dmin] = 0
scan1_rh[scan1_rh<=dmin] = 0
scan1_lh[scan1_lh>dmin] = 1
scan1_rh[scan1_rh>dmin] = 1

# Scan 2
scan2_lh[scan2_lh<=dmin] = 0
scan2_rh[scan2_rh<=dmin] = 0
scan2_lh[scan2_lh>dmin] = 2
scan2_rh[scan2_rh>dmin] = 2

# Overlap
overlap_lh = scan1_lh[:] * scan2_lh[:]
overlap_rh = scan1_rh[:] * scan2_rh[:]

###

###
# Plot overlap

sw0 = SurfWrap()
sw0.set_underlay()
sw0.set_options()
sw0.min = 1; sw0.max = 2; sw0.sign = "pos"
oprefix = path.join(odir, "D_perms_surface_overlap")
sw0.set_output(oprefix)

scan1_surfs     = {"lh": scan1_lh, "rh": scan1_rh}
scan2_surfs     = {"lh": scan2_lh, "rh": scan2_rh}
overlap_surfs   = {"lh": overlap_lh, "rh": overlap_rh}

for hemi in sw0.hemis:
    print "visualize %s" % hemi
    
    # Bring up the beauty (the underlay)
    brain = Brain(sw0.subject_id, hemi, sw0.surf, \
                  config_opts=sw0.config_opts, \
                  subjects_dir=sw0.subjects_dir)
    
    # Scan 1
    surf_data = scan1_surfs[hemi]
    if (sum(abs(surf_data)) > 0):
        # Overlay another hopeful beauty (functional overlay)
        brain.add_overlay(surf_data, name="scan1", sign=sw0.sign)
    
        # Update colorbar
        tmp = brain.overlays["scan1"]
        lut = tmp.pos_bar.lut.table.to_array()
        lut[:,0:3] = [27,158,119]
        tmp.pos_bar.lut.table = lut
        
        # Refresh
        brain.show_view("lat")
        brain.hide_colorbar()
    
    # Scan 2
    surf_data = scan2_surfs[hemi]
    if (sum(abs(surf_data)) > 0):
        # Overlay another hopeful beauty (functional overlay)
        brain.add_overlay(surf_data, name="scan2", sign=sw0.sign)
    
        # Update colorbar
        tmp = brain.overlays["scan2"]
        lut = tmp.pos_bar.lut.table.to_array()
        lut[:,0:3] = [231,41,138]
        tmp.pos_bar.lut.table = lut
        
        # Refresh
        brain.show_view("lat")
        brain.hide_colorbar()
    
    # Overlap
    surf_data = overlap_surfs[hemi]
    if (sum(abs(surf_data)) > 0):
        # Overlay another hopeful beauty (functional overlay)
        brain.add_overlay(surf_data, name="overlap", sign=sw0.sign)
    
        # Update colorbar
        tmp = brain.overlays["overlap"]
        lut = tmp.pos_bar.lut.table.to_array()
        lut[:,0:3] = [230,171,2]
        tmp.pos_bar.lut.table = lut
    
        # Refresh
        brain.show_view("lat")
        brain.hide_colorbar()
    
    # Save the beauts
    brain.save_imageset("%s_%s" % (sw0.outprefix, hemi), sw0.views, 
                        'jpg', colorbar=None)
    
    # End a great journey, till another life
    brain.close()

sw0.cropify()
sw0.montage("box")
sw0.montage("stick")



####
## Setup
#
## 3dcalc -a /home2/data/Projects/CWAS/nki/cwas/short/compcor_kvoxs_smoothed_to_kvoxs_smoothed/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/clust_logp_FSIQ.nii.gz -b /home2/data/Projects/CWAS/nki/cwas/medium/compcor_kvoxs_smoothed_to_kvoxs_smoothed/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/clust_logp_FSIQ.nii.gz -expr 'step(a)+(2*step(b))' -prefix /home2/data/Projects/CWAS/figures/fig_03/C_overlap.nii.gz
#
#basedir = "/home2/data/Projects/CWAS"
#
#figdir = path.join(basedir, "figures/fig_03")
#pfile = path.join(figdir, "C_overlap.nii.gz")
#
## Output prefixes
#odir = path.join(basedir, "figures", "fig_03")
#if not path.exists(odir): os.mkdir(odir)
#
####
#
#class SurfWrapOverlap(SurfWrap):
#    
#    
#
####
## Surface Viz
#
#print pfile
#oprefix = path.join(odir, "C_overlap")
#sw = SurfWrap(name="overlap", infile=pfile, cbar="discrete-cb2-3", 
#              outprefix=oprefix, interp="nearest")
#sw.run(compilation="box")
#sw.montage(compilation="stick")
#
####
