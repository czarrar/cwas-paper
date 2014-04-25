#!/home2/data/PublicProgram/epd-7.2-2-rh5-x86_64/bin/python

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path as op
from surfwrap import Brain, io, SurfWrap, vol_to_surf
import numpy as np
import nibabel as nib


# 1. Transform each of the MDMR and GLM maps into surface space
# 2. Take the top 5, 10, & 15% to create new values.
# 3. Plot these new values but only on the left hemisphere

###
# Colors

print "colors"

import rpy2.robjects as robjects
from rpy2.robjects.numpy2ri import numpy2ri
from rpy2.robjects.packages import importr
robjects.conversion.py2ri = numpy2ri

brewer = importr("RColorBrewer")

# red, orange, yellow (top 15%, 10%, 5%)
cols = np.array(robjects.r('col2rgb(brewer.pal(8, "Set1")[c(1,5,6)])'))
std_lut            = np.zeros((256,4))
std_lut[:85,:3]    = cols[:,0].tolist()
std_lut[85:170,:3] = cols[:,1].tolist()
std_lut[170:,:3]   = cols[:,2].tolist()
std_lut[:,3]       = 255

# custom made (based on other online venn diagrams)
over_lut            = np.zeros((256,4))
#over_lut[:85,:3]    = [255,39,18]
over_lut[:85,:3]    = [254,73,64]
over_lut[85:170,:3] = [255,255,51]
over_lut[170:,:3]   = [85,142,40]
over_lut[:,3]       = 255

## venn diagram from google (overlap is not clear)
#over_lut[:85,:3]    = [127,198,89]
#over_lut[85:170,:3] = [253,153,85]
#over_lut[170:,:3]   = [127,164,51]
#
## other venn diagram from google (overlap is not clear)
#over_lut[:85,:3]    = [255,99,85]
#over_lut[85:170,:3] = [99,197,222]
#over_lut[170:,:3]   = [99,146,165]

# some site
#cols = np.array(robjects.r('col2rgb(brewer.pal(10, "Set3")[c(4,5,3)])'))
#over_lut            = np.zeros((256,4))
#over_lut[:85,:3]    = [236,0,140]
#over_lut[85:170,:3] = [6,174,239]
#over_lut[170:,:3]   = [46,49,146]
#over_lut[:,3]       = 255

## some site (i like but too military looking)
#over_lut[:85,:3]    = [255,192,66]
#over_lut[85:170,:3] = [37,63,97]
#over_lut[170:,:3]   = [78,99,40]


###


###
# Setup

print "setup"

strategy = "compcor"
scans = ["short", "medium"]
print "strategy: %s; scans: %s" % (strategy, ",".join(scans))

kstr = "kvoxs_fwhm08_to_kvoxs_fwhm08"
dirname = "%s_%s" % (strategy, kstr)

base    = "/home2/data/Projects/CWAS/nki"


## CWAS

cwasbase = op.join(base, "cwas")

# Distance Directory
distdirs = [ op.join(cwasbase, scan, dirname) for scan in scans ]

# MDMR
mname = "iq_age+sex+meanFD+meanGcor.mdmr"
#cname = "cluster_correct_v05_c05"
factor = "FSIQ"

# Input pfile
mdmrdirs = [ op.join(distdir, mname) for distdir in distdirs ]
pfiles = [ op.join(mdmrdir, "zstats_%s.nii.gz" % factor) for mdmrdir in mdmrdirs ]


## GLM

glmbase = op.join(base, "glm")

glmdirs = [ op.join(glmbase, "old_%s_%s" % (scan, dirname)) for scan in scans ]
gfiles  = [ op.join(gdir, "summary", "uwt_iq.nii.gz") for gdir in glmdirs ]

## Output

obase = "/home2/data/Projects/CWAS/figures"
figdir = op.join(obase, "fig_05")
if not op.exists(figdir): os.mkdir(figdir)
surfdir = op.join(figdir, "surfaces")
if not op.exists(surfdir): os.mkdir(surfdir)


###


###
# Read in data

for i in range(2):
    
    print "scan: %s" % scans[i]
    
    print "read data"

    cwas_info = vol_to_surf(pfiles[i], hemis=["lh", "rh"])
    lh_cwas   = io.read_scalar_data(cwas_info["lh"])
    rh_cwas   = io.read_scalar_data(cwas_info["rh"])
    
    glm_info  = vol_to_surf(gfiles[i], hemis=["lh", "rh"])
    lh_glm    = io.read_scalar_data(glm_info["lh"])
    rh_glm    = io.read_scalar_data(glm_info["rh"])
    
    ###
    
    
    ###
    # Remap with top percentiles
    
    print "percentiles"

    # Top 5%, 10%, & 15%

    percs = [85, 90, 95]

    cwas_perc = np.percentile(lh_cwas, percs)
    lh_cwas_perc = np.zeros_like(lh_cwas)
    for p in cwas_perc:
        lh_cwas_perc += (lh_cwas > p) * 1
    rh_cwas_perc = np.zeros_like(rh_cwas)
    for p in cwas_perc:
        rh_cwas_perc += (rh_cwas > p) * 1

    glm_perc  = np.percentile(lh_glm, percs)
    lh_glm_perc = np.zeros_like(lh_glm)
    for p in glm_perc:
        lh_glm_perc += (lh_glm > p) * 1
    rh_glm_perc = np.zeros_like(rh_glm)
    for p in glm_perc:
        rh_glm_perc += (rh_glm > p) * 1


    # Overlap top 15% between mdmr and glm
    lh_overlap = (lh_cwas_perc>0)*1 + (lh_glm_perc>0)*2
    rh_overlap = (rh_cwas_perc>0)*1 + (rh_glm_perc>0)*2

    ###


    ###
    # Plot top percentiles

    print "plot percentiles"

    sw0 = SurfWrap(hemis=['lh'])
    sw0.set_underlay()
    sw0.set_options()
    sw0.min = 1; sw0.max = 3; sw0.sign = "pos"
    oprefix = op.join(figdir, "B_surface_percentiles")
    sw0.set_output(oprefix)

    cwas_perc_surfs = {"lh": lh_cwas_perc}
    glm_perc_surfs  = {"lh": lh_glm_perc}
    overlap_surfs   = {"lh": lh_overlap}

    for hemi in sw0.hemis:
        print "visualize %s" % hemi
    
        ## MDMR
        #oprefix = op.join(figdir, "B_%s_percentiles_mdmr" % scans[i])
        #sw0.set_output(oprefix)
        #
        #brain = Brain(sw0.subject_id, hemi, sw0.surf, \
        #              config_opts=sw0.config_opts, \
        #              subjects_dir=sw0.subjects_dir)
        #
        #surf_data = cwas_perc_surfs[hemi]
        #if (sum(abs(surf_data)) > 0):
        #    # Overlay another hopeful beauty (functional overlay)
        #    brain.add_overlay(surf_data, min=sw0.min, max=sw0.max, name="mdmr", 
        #                      sign=sw0.sign)
        #
        #    # Update colorbar
        #    tmp = brain.overlays["mdmr"]
        #    tmp.pos_bar.lut.table = std_lut
        #
        #    # Refresh
        #    brain.show_view("lat")
        #    brain.hide_colorbar()
        #
        #brain.save_imageset("%s_%s" % (sw0.outprefix, hemi), sw0.views, 
        #                    'jpg', colorbar=None)
        #brain.close()
        #
        #sw0.cropify()
        #sw0.montage("uni_lh")
        #
        #
        ## GLM
        #oprefix = op.join(figdir, "B_%s_percentiles_glm" % scans[i])
        #sw0.set_output(oprefix)
        #
        #brain = Brain(sw0.subject_id, hemi, sw0.surf, \
        #              config_opts=sw0.config_opts, \
        #              subjects_dir=sw0.subjects_dir)
        #
        #surf_data = glm_perc_surfs[hemi]
        #if (sum(abs(surf_data)) > 0):
        #    # Overlay another hopeful beauty (functional overlay)
        #    brain.add_overlay(surf_data, min=sw0.min, max=sw0.max, name="glm", 
        #                      sign=sw0.sign)
        #
        #    # Update colorbar
        #    tmp = brain.overlays["glm"]
        #    tmp.pos_bar.lut.table = std_lut
        #
        #    # Refresh
        #    brain.show_view("lat")
        #    brain.hide_colorbar()
        #
        #brain.save_imageset("%s_%s" % (sw0.outprefix, hemi), sw0.views, 
        #                    'jpg', colorbar=None)
        #brain.close()
        #
        #sw0.cropify()
        #sw0.montage("uni_lh")
    
    
    print "plot overlap"

    sw0 = SurfWrap(hemis=['lh', 'rh'])
    sw0.set_underlay()
    sw0.set_options()
    sw0.min = 1; sw0.max = 3; sw0.sign = "pos"
    oprefix = oprefix = op.join(figdir, "ztest_%s_percentiles_overlap" % scans[i])
    sw0.set_output(oprefix)

    cwas_perc_surfs = {"lh": lh_cwas_perc, "rh": rh_cwas_perc}
    glm_perc_surfs  = {"lh": lh_glm_perc, "rh": rh_glm_perc}
    overlap_surfs   = {"lh": lh_overlap, "rh": rh_overlap}

    for hemi in sw0.hemis:
        print "visualize %s" % hemi
        
        # Overlap    
        brain = Brain(sw0.subject_id, hemi, sw0.surf, \
                      config_opts=sw0.config_opts, \
                      subjects_dir=sw0.subjects_dir)
    
        surf_data = overlap_surfs[hemi]
        if (sum(abs(surf_data)) > 0):
            # Overlay another hopeful beauty (functional overlay)
            brain.add_overlay(surf_data, min=sw0.min, max=sw0.max, name="glm", 
                              sign=sw0.sign)
    
            # Update colorbar
            tmp = brain.overlays["glm"]
            tmp.pos_bar.lut.table = over_lut
        
            # Refresh
            brain.show_view("lat")
            brain.hide_colorbar()
            
            #import code
            #code.interact(local=locals())
        
        brain.save_imageset("%s_%s" % (sw0.outprefix, hemi), sw0.views, 
                            'jpg', colorbar=None)
        brain.close()
    
    sw0.cropify()
    sw0.montage("box")
    sw0.montage("stick")



