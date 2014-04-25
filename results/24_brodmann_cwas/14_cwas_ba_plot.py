#!/usr/bin/env python

"""

"""

import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
import numpy as np
from surfer import io
from os import path as op
from pandas import read_csv, DataFrame
from newsurf import *


###
# Setup (General)
###

base = "/home2/data/Projects/CWAS"
odir = op.join(base, "results/24_brodmann_cwas")

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
# Setup (BA)
###

# get the brodmann areas in the meta-analysis
ref         = read_csv(op.join(base, "results/24_brodmann_cwas/BA_fig5.csv"))
ref_labels  = ref.ix[:,0].tolist()

# paths to ba maps
ba_files = {
    "lh": "/home2/data/PublicProgram/freesurfer/fsaverage_copy/label/lh.PALS_B12_Brodmann.annot", 
    "rh": "/home2/data/PublicProgram/freesurfer/fsaverage_copy/label/rh.PALS_B12_Brodmann.annot"
}


###
# Setup (Scan)
###

scan = "short"

# paths to cwas
easydir = easydirs[scan]
surf_files = {
    "lh": op.join(easydir, "surfs/surf_thresh_zstat_FSIQ_lh.nii.gz"), 
    "rh": op.join(easydir, "surfs/surf_thresh_zstat_FSIQ_rh.nii.gz")
}
#surf_files = {
#    "lh": op.join(easydir, "surfs/surf_clust_logp_FSIQ_lh.nii.gz"), 
#    "rh": op.join(easydir, "surfs/surf_clust_logp_FSIQ_rh.nii.gz")
#}
all_sfiles = surf_files.values()


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


###
# Neurosynth
###

def run(cmd):
    print(cmd)
    os.system(cmd)

prefix      = "/home2/data/Projects/CWAS/results/20_cwas_iq/12_iq_surface/30_neurosynth_iq_surf_thresh"
neurosynth  = { hemi : io.read_scalar_data("%s_%s.nii.gz" % (prefix, hemi)) for hemi in ["lh", "rh"] }
all_ns      = neurosynth.values()

prefix      = op.join(odir, "surfs", "surf_ns_intelligence_all")
ns_orig_dir = op.join(base, "neurosynth/neurosynth/intelligence_001")
cmd         = "./x_vol2surf.py %s/_pAgF_z.nii.gz %s/_pAgF_z_FDR_0.05.nii.gz %s" % (ns_orig_dir, ns_orig_dir, prefix)
run(cmd)
ns_orig     = { hemi : io.read_scalar_data("%s_%s.nii.gz" % (prefix, hemi)) for hemi in ["lh", "rh"] }
all_ns      = ns_orig.values()

prefix      = "surf_ns_intelligence_fmri"
ns_fmri_dir = op.join(base, "neurosynth/neurosynth/intelligence_very_relevant_fmri")
cmd         = "./x_vol2surf.py %s/_pAgF_z.nii.gz %s/_pAgF_z_FDR_0.05.nii.gz %s" % (ns_fmri_dir, ns_fmri_dir, prefix)
run(cmd)
ns_fmri     = { hemi : io.read_scalar_data("%s_%s.nii.gz" % (prefix, hemi)) for hemi in ["lh", "rh"] }
all_ns      = ns_fmri.values()

# WORKING MEMORY
prefix      = "surf_ns_wm"
ns_wm_dir   = op.join(base, "neurosynth/neurosynth/wm")
cmd         = "./x_vol2surf.py %s/_pAgF_z.nii.gz %s/_pAgF_z_FDR_0.05.nii.gz %s" % (ns_wm_dir, ns_wm_dir, prefix)
run(cmd)
ns_wm       = { hemi : io.read_scalar_data("%s_%s.nii.gz" % (prefix, hemi)) for hemi in ["lh", "rh"] }
all_ns      = ns_wm.values()

# Reasoning
prefix      = "surf_ns_reasoning"
ns_reasoning_dir   = op.join(base, "neurosynth/neurosynth/reasoning")
cmd         = "./x_vol2surf.py %s/_pAgF_z.nii.gz %s/_pAgF_z_FDR_0.05.nii.gz %s" % (ns_reasoning_dir, ns_reasoning_dir, prefix)
run(cmd)
ns_reasoning       = { hemi : io.read_scalar_data("%s_%s.nii.gz" % (prefix, hemi)) for hemi in ["lh", "rh"] }
all_ns      = ns_reasoning.values()

# WM/Reasoning/Intelligence
prefix      = "surf_ns_intelligence_reasoning_wm"
ns_combined_dir   = op.join(base, "neurosynth/neurosynth/intelligence_reasoning_wm")
cmd         = "./x_vol2surf.py %s/_pAgF_z.nii.gz %s/_pAgF_z_FDR_0.05.nii.gz %s" % (ns_combined_dir, ns_combined_dir, prefix)
run(cmd)
ns_combined       = { hemi : io.read_scalar_data("%s_%s.nii.gz" % (prefix, hemi)) for hemi in ["lh", "rh"] }
all_ns      = ns_combined.values()


print 'getting range'
dmin2 = np.array([ ns[ns.nonzero()].min() for ns in all_ns ]).min()
dmax2 = np.array([ ns[ns.nonzero()].max() for ns in all_ns ]).max()
print 'min=%.4f; max=%.4f' % (dmin2,dmax2)


###
# Hemisphere
###

hemi    = "lh"

ba      = io.read_annot(ba_files[hemi])
cwas    = io.read_scalar_data(surf_files[hemi])
nsynth  = ns_combined[hemi]
overlap = cwas * nsynth

rois    = ba[0]
urois   = np.unique(rois); urois.sort()
labels  = np.array(ba[2])[urois]

# Only want BAs with more than 20%
select_bas = ref.ix[ref.ix[:,1]>20,0].tolist()

# Get the BAs and indices to select
d_rois  = { int(k[9:]) : urois[i] for i,k in enumerate(labels) if k.find("Brodmann") == 0 }
d_rois  = { k : v for k,v in d_rois.iteritems() if k in select_bas }

# Select
i = 1
rois_select = np.zeros_like(rois)
for k,v in d_rois.iteritems():
    rois_select[rois==v] = i
    i += 1
rois_bin = (rois_select != 0)*1

# Color bar
cbarfile = "/home2/data/Projects/CWAS/share/lib/surfwrap/colorbars/red-yellow.txt"
cbar = load_colorbar(cbarfile)

# Viz
brain = fsaverage(hemi)
#brain.add_overlay(rois_bin, name="ba")
brain = add_overlay("cwas", brain, cwas, "Blues", 
                    dmin, dmax, "pos")
brain = add_overlay("neurosynth", brain, nsynth, "Purples", 
                    dmin2, dmax2, "pos")
# Get the overlap
overlap = (overlap>0)*1
cbar = load_colorbar(np.array(([[255,255,0,255]])))
brain = add_overlay("overlap", brain, overlap, cbar, overlap[overlap.nonzero()].min(), overlap.max(), "pos")
#brain.add_contour_overlay(rois_bin, min=0.5, max=1.5, n_contours=2)

brain.save_imageset("cwas-perms-scan1_and_neurosynth-all_lh", ['lat', 'med'], colorbar=None, filetype='jpg')
montage(op.join(os.getcwd(), "cwas-perms-scan1_and_neurosynth-all"), compilation="horiz_lh")

brain.save_imageset("cwas-scan1_and_neurosynth-all_lh", ['lat', 'med'], colorbar=None, filetype='jpg')
montage(op.join(os.getcwd(), "cwas-scan1_and_neurosynth-all"), compilation="horiz_lh")

brain.save_imageset("cwas-scan1_and_neurosynth-fmri_lh", ['lat', 'med'], colorbar=None, filetype='jpg')
montage(op.join(os.getcwd(), "cwas-scan1_and_neurosynth-fmri"), compilation="horiz_lh")

brain.save_imageset("cwas-scan1_and_neurosynth-wm_lh", ['lat', 'med'], colorbar=None, filetype='jpg')
montage(op.join(os.getcwd(), "cwas-scan1_and_neurosynth-wm"), compilation="horiz_lh")

brain.save_imageset("cwas-scan1_and_neurosynth-reasoning_lh", ['lat', 'med'], colorbar=None, filetype='jpg')
montage(op.join(os.getcwd(), "cwas-scan1_and_neurosynth-reasoning"), compilation="horiz_lh")


###
# Surface Viz


for hemi,sfile in surf_files.iteritems():
    print sfile
    oprefix = path.join(odir, "A_easythresh_surface_scan%i" % (i+1))
    
    for hemi in hemis:
        surf_data = io.read_scalar_data("%s_%s.nii.gz" % (sfile, hemi))
        
        brain = fsaverage(hemi)
        brain = add_overlay(study, brain, surf_data, cbar, 
                            dmin, dmax, "pos")
        save_imageset(brain, oprefix, hemi)
    
    montage(oprefix, compilation='box')
    montage(oprefix, compilation='horiz')
    
###












for i,label in enumerate(labels):
    if label.find("Brodmann") == -1:
        continue
    
    ba          = int(label[9:])
    roi         = urois[i]
    summary_wt  = cwas[rois==roi].mean()
    summary_uwt = (cwas[rois==roi]>0).mean()
    if ba in ref_labels:
        meta_analysis = ref.ix[ref.ix[:,0]==ba,1].tolist()[0]
    else:
        meta_analysis = 0
    
    dict_df["index"].append(i)
    dict_df["roi"].append(roi)
    dict_df["ba"].append(ba)
    dict_df["summary_wt"].append(summary_wt)
    dict_df["summary_uwt"].append(summary_uwt)
    dict_df["meta_analysis"].append(meta_analysis)
    
df = DataFrame(dict_df, columns=cols)    
df.to_csv(op.join(odir, "10_dataframe_lh.csv"))

d_rois  = { int(k[9:]) : i for i,k in enumerate(labels) if k.find("Brodmann") == 0 }
{d.keys(), 


summary_wt = { labels[i] : cwas[rois==ur].mean() for k,ur in d_rois.iteritems() }
summary_wt = { int(k[9:]) : v for k,v in summary_wt.iteritems() if k.find("Brodmann") == 0 }

summary_uwt = { labels[i] : (cwas[rois==ur]>0).mean() for i,ur in enumerate(urois) }
summary_uwt = { int(k[9:]) : v for k,v in summary_uwt.iteritems() if k.find("Brodmann") == 0 }


# End goal is to correlate our measures with theirs
# Now this will mean restricting their list to match ours
# Then do the correlation

ref         = read_csv(op.join(base, "results/24_brodmann_cwas/BA_fig5.csv"))
ref_labels  = ref.ix[:,0].tolist()

ref_full    = dict.fromkeys(d_rois.keys(), 0)
for k,v in ref_full.iteritems():
    if k in ref_labels:
        ref_full[k] = ref.ix[ref.ix[:,0]==k,1].tolist()[0]

row_inds    = [ i for i,rl in enumerate(ref_labels) if rl in d_rois.keys() ]
ref_select  = ref.ix[row_inds,:]
ref_labels  = sorted(ref_select.ix[:,0].tolist())
{ k : v for k,v in d_rois.iteritems() if k not in ref_labels }