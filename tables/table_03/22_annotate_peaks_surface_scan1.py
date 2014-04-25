#!/usr/bin/env python

"""
Here, we will take in peak coordinates and match them against parcellations and curvuture related to the fsaverage.


"""

import os
from os import path as op 
from surfer import io, utils
from pandas import read_csv
import numpy as np
import pandas


## Load the peaks
#def read_peaks(fname):
#    """Reads in AFNI generated peak locations"""
#    import numpy as np
#    from pandas import DataFrame
#    
#    peaks = np.loadtxt(fname, skiprows=10)
#    peaks = DataFrame(peaks, columns=["Index", "Intensity", "x", "y", "z", "Count", "Dist"])
#    
#    peaks.x = peaks.x * -1
#    peaks.y = peaks.y * -1
#    
#    return peaks

print "Setup"

subjects_dir = "/home2/data/PublicProgram/freesurfer"
surf_dir     = op.join(subjects_dir, "fsaverage_copy/surf")
label_dir    = op.join(subjects_dir, "fsaverage_copy/label")

whereami_dir = "/home2/data/Projects/CWAS/whereami"
table_dir    = "/home2/data/Projects/CWAS/tables/table_03"

# Load df (peaks?)
df_file     = op.join(table_dir, "12_peaks_part1_scan1.csv")
df          = read_csv(df_file)
df          = df.ix[:,1:]

# Load MNI152 to MNI305 (freesurfer) transformation
mat_file    = op.join(whereami_dir, "mni152_to_fsaverage.mat")
mat         = np.loadtxt(mat_file)

# Split peaks on whether they are on the left or right hemisphere
df_lh       = df.ix[df.x<0,:]
df_rh       = df.ix[df.x>0,:]
df_both     = {"lh": df_lh, "rh": df_rh}

# Loop through hemis
print "Looping through"
for hemi in ["lh", "rh"]:
    print "...hemi: %s" % hemi
    
    # Get coordinates
    raw_coords  = df_both[hemi].ix[:,3:6].as_matrix()
    np.savetxt("tmp_mni152_coords.txt", raw_coords, fmt="%.4f")
    cmd         = "img2imgcoord -src %s/mni152.nii.gz -dest %s/fsaverage.nii.gz -xfm %s/mni152_to_fsaverage.mat -mm %s > %s"
    cmd         = cmd % (whereami_dir, whereami_dir, whereami_dir, "tmp_mni152_coords.txt", "tmp_fs_coords.txt")
    print(cmd)
    os.system(cmd)
    coords      = np.loadtxt("tmp_fs_coords.txt", skiprows=1)
    coords      = coords[:-1,:] # program gives last coordinate twice

    # Now we can take these peak coordinates and get the surface vertex
    foci_surf   = io.Surface("fsaverage_copy", hemi, "white", subjects_dir=subjects_dir)
    foci_surf.load_geometry()
    foci_vtxs   = utils.find_closest_vertices(foci_surf.coords, coords)

    # Load the geometry
    curv_file   = op.join(surf_dir, "%s.curv" % hemi)
    curv        = io.read_morph_data(curv_file) # < 0 = gyrus & > 0 = sulcus

    # Load the parcellations
    aparc_file  = op.join(label_dir, "%s.aparcDKT40JT.annot" % hemi)
    aparc9_file = op.join(label_dir, "%s.aparc.a2009s.annot" % hemi)
    ba_file     = op.join(label_dir, "%s.PALS_B12_Brodmann.annot" % hemi)
    yeo_file    = op.join(label_dir, "%s.Yeo2011_7Networks_N1000.annot" % hemi)
    aparc       = io.read_annot(aparc_file)
    ba          = io.read_annot(ba_file)
    yeo         = io.read_annot(yeo_file)
    aparc9      = io.read_annot(aparc9_file)

    yeo_names   = ["Medial_Wall", "Visual", "Somatomotor", "Dorsal Attention", 
                   "Ventral Attention", "Limbic", "Frontoparietal", "Default"]
    
    aparc_names = ['Unknown',
     'Banks Superior Temporal',
     'Caudal Anterior Cingulate',
     'Caudal Middle Frontal',
     'Corpus Callosum',
     'Cuneus',
     'Entorhinal',
     'Fusiform',
     'Inferior Parietal',
     'Inferior Temporal',
     'Isthmus Cingulate',
     'Lateral Occipital',
     'Lateral Orbital Frontal',
     'Lingual',
     'Medial Orbital Frontal',
     'Middle Temporal',
     'Parahippocampal',
     'Paracentral',
     'Pars Opercularis',
     'Pars Orbitalis',
     'pars Triangularis',
     'Peri Calcarine',
     'Post Central',
     'Posterior Cingulate',
     'Precentral',
     'Precuneus',
     'Rostral Anterior Cingulate',
     'Rostral Middle Frontal',
     'Superior Frontal',
     'Superior Parietal',
     'Superior Temporal',
     'Supra Marginal',
     'Frontal Pole',
     'Temporal Pole',
     'Transverse Temporal',
     'Insula']
    
    # Get at the regions
    df_both[hemi]["aparc"] = np.array(aparc_names)[aparc[0][foci_vtxs]]
    df_both[hemi]["curv"]  = np.array(["Sulcus", "Gyrus"])[((curv<0)*1)[foci_vtxs]]
    df_both[hemi]["aparc9"]= np.array(aparc9[2])[aparc9[0][foci_vtxs]]
    df_both[hemi]["ba"]    = np.array(ba[2])[ba[0][foci_vtxs]]
    df_both[hemi]["yeo"]   = np.array(yeo_names)[yeo[0][foci_vtxs]]


print "Recombine and index"

# Recombine the two hemisphere's into one unified whole!
# Also check if anyone's missing
df_new = df_both["lh"].append(df_both["rh"])

# Redo index
df_new.index = range(df_new.shape[0])

# Sort the column
print "Sort by Hemi, Cluster, and Stat"

import rpy2.robjects as robjects
r = robjects.r

cluster = robjects.IntVector(df_new.Cluster.tolist())
network = robjects.StrVector(df_new.YeoNetwork.tolist())
stat    = robjects.FloatVector(df_new.Stat.tolist())

o       = np.array(r.order(cluster, network, stat, decreasing=True)) - 1
df2     = df_new.ix[o,:]


#####

print "Combine, Select, Mash"

# Combine the aparc, subcortical, and cerebellum
cols      = ["Cluster", "Network", "Hemi", "Region", "BA", "x", "y", "z", "Statistic"]
dict3     = { k : [] for k in cols }

for i,row in df2.iterrows():
    # Cluster, Network, Hemi
    dict3["Cluster"].append(row["Cluster"])
    dict3["Network"].append(row["YeoNetwork"])
    dict3["Hemi"].append(row["Hemi"])
    
    # Deal with cortical region
    if (row["Subcortical"] == "NOTHING") and (row["Cerebellum"] == "NOTHING"):
        txt = row["aparc"] + " " + row["curv"]
        dict3["Region"].append(txt)
        # Use cortical BAs if region is within cortex
        if row["Cortical"] == 1:
            dict3["BA"].append(row["ba"].replace("Brodmann.", "BA"))
        # Otherwise use BAs based on volume space
        else:
            dict3["BA"].append(row["BA"].replace("NOTHING",""))
    
    # Deal with subcortical region
    elif row["Subcortical"] != "NOTHING":
        txt = row["Subcortical"].replace("Left ", "").replace("Right ", "")
        dict3["Region"].append(txt)
        dict3["BA"].append("")
    
    # Deal with Cerebellum
    elif row["Cortical"] != "NOTHING":
        txt = "Cerebellum (%s)" % row["Cerebellum"].replace("Left ", "").replace("Right ", "")
        dict3["Region"].append(txt)
        dict3["BA"].append("")
    
    else:
        raise Exception("unknown row %i" % i)
    
    # x, y, z, and statistic
    dict3["x"].append(row["x"])
    dict3["y"].append(row["y"])
    dict3["z"].append(row["z"])
    dict3["Statistic"].append(row["Stat"])

df3 = pandas.DataFrame(dict3, columns=cols)

####

# Save
print "Save"
df3.to_csv(op.join(table_dir, "14_peaks_scan1.csv"))
