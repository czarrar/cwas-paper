#!/usr/bin/env python

# 1. create a conjunction between IQ and new_intelligence
# 2. register it to surface space
# 3. threshold the registrations at 0.5

import os
from os import path as op

base            = "/home2/data/Projects/CWAS"
mask_file       = op.join(base, "nki/rois/mask_gray_4mm.nii.gz")         
neurosynth_dir  = op.join(base, "neurosynth")
fi_dir          = op.join(neurosynth_dir, "forward_inference")
out_dir         = op.join(base, "results/20_cwas_iq/12_iq_surface")
if not op.exists(out_dir):
    os.mkdir(out_dir)

print '####'
print 'Register mask to 2mm'
cmd             = "3dresample -inset %s -master %s/standard_2mm.nii.gz -prefix %s/00_mask.nii.gz"
cmd             = cmd % (mask_file, neurosynth_dir, out_dir)
print cmd
os.system(cmd)

print '####'
print 'Creating the conjunction and mask by the group mask'
cmd             = "3dcalc -a %s/new_intelligence.nii.gz -b %s/00_mask.nii.gz -expr 'step(a)*step(b)' -prefix %s/10_neurosynth_iq.nii.gz"
cmd             = cmd % (fi_dir, out_dir, out_dir)
print cmd
os.system(cmd)

print '####'
print 'Register to surface'
cmd             = "./x_simple_mni2fs.bash %s/10_neurosynth_iq.nii.gz %s/20_neurosynth_iq_surf"
cmd             = cmd % (out_dir, out_dir)
print cmd
os.system(cmd)

print '####'
print 'Threshold the surface at 0.5'
infiles = [ "%s/20_neurosynth_iq_surf_%s.nii.gz" % (out_dir, hemi) for hemi in ["lh", "rh"] ]
for infile in infiles:
    outfile     = infile.replace("20_neurosynth_iq_surf", "30_neurosynth_iq_surf_thresh")
    cmd         = "3dcalc -a %s -expr 'step(a-0.5)' -prefix %s"
    cmd         = cmd % (infile, outfile)
    print cmd
    os.system(cmd)

