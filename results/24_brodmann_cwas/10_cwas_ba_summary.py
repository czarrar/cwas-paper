#!/usr/bin/env python

"""
This script will get the percent of significant associations within each BA.

Steps include (for a given scan):
- Load surface images
- Load brodmann map
- Organize brodmann areas
- Loop through BAs and get average significance
"""

import numpy as np
from surfer import io
from os import path as op
from pandas import read_csv, DataFrame


base = "/home2/data/Projects/CWAS"
odir = op.join(base, "results/24_brodmann_cwas")

sdir = "compcor_kvoxs_fwhm08_to_kvoxs_fwhm08"
mdir = "iq_age+sex+meanFD.mdmr"
edir = "cluster_correct_v05_c05/easythresh"
easydirs = {
    "short":    op.join(base, "nki/cwas/short", sdir, mdir, edir), 
    "medium":   op.join(base, "nki/cwas/medium", sdir, mdir, edir)
}



scan = "short"

easydir = easydirs[scan]
surf_files = {
    "lh": op.join(easydir, "surf_lh_thresh_zstat_FSIQ.nii.gz"), 
    "rh": op.join(easydir, "surf_rh_thresh_zstat_FSIQ.nii.gz")
}
ba_files = {
    "lh": "/home2/data/PublicProgram/freesurfer/fsaverage_copy/label/lh.PALS_B12_Brodmann.annot", 
    "rh": "/home2/data/PublicProgram/freesurfer/fsaverage_copy/label/rh.PALS_B12_Brodmann.annot", 
}


hemi    = "lh"

ba      = io.read_annot(ba_files[hemi])
cwas    = io.read_scalar_data(surf_files[hemi])

rois    = ba[0]
urois   = np.unique(rois); urois.sort()
labels  = np.array(ba[2])[urois]

cols    = ["index", "roi", "ba", "summary_wt", "summary_uwt", "meta_analysis"]
dict_df = { k : [] for k in cols }

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