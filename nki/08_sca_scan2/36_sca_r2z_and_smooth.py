#!/usr/bin/env python

import os, sys
from os import path as op
import nibabel as nib
import numpy as np

if len(sys.argv) != 4:
    print "usage: x_fischer_transform.py corr-file mask-file fwhm"
    print "- set fwhm to 0 if you want to turn if off"
    sys.exit(2)

def check_input_file(fname):
    """checks if the fname exists, otherwise exits"""
    if not op.exists(fname):
        print "ERROR: input file '%s' doesn't exist" % fname
    return


print "...setup"
corr_file = sys.argv[1]
mask_file = sys.argv[2]
fwhm      = int(sys.argv[3])

check_input_file(corr_file)
check_input_file(mask_file)

# Fischer Z
z_dir     = op.dirname(corr_file)
z_name, _ = op.splitext(op.basename(corr_file))
z_prefix  = op.join(z_dir, "zscore_%s" % z_name)

# Smoothed Output
s_dir     = op.join(z_dir, "fwhm_%02i" % fwhm)
if not op.exists(s_dir): os.mkdir(s_dir)
s_name    = z_name
s_prefix  = op.join(s_dir, "smoothed_zscore_%s" % s_name)


print "...loading data"
mask = nib.load(mask_file).get_data().astype('bool')
mask_indices = np.where(mask)

img  = nib.load(corr_file)
hdr  = img.get_header()
aff  = img.get_affine()
#import code
#code.interact(local=locals())
data = img.get_data()
data.shape = (data.shape[0], data.shape[1], data.shape[2], data.shape[4])

dims = data.shape
nx, ny, nz, nrois = dims


print "...fischer z transforming"
data[mask_indices] = np.arctanh(data[mask_indices])


print "...saving %i rois" % nrois
z_files = [ "%s_roi_n%02i.nii.gz" % (z_prefix, i+1) for i in range(nrois) ]
for i in range(nrois):
    z_file = z_files[i]
    if op.exists(z_file):
        os.remove(z_file)
        #continue
    roi_img  = nib.Nifti1Image(data[:,:,:,i], header=hdr, affine=aff)
    roi_img.to_filename(z_file)

if fwhm == 0:
    print "...skipping smoothing"
else:
    print "...smoothing"
    s_files = [ "%s_roi_n%02i.nii.gz" % (s_prefix, i+1) for i in range(nrois) ]
    for i in range(nrois):
        s_file = s_files[i]
        z_file = z_files[i]
        if op.exists(s_file):
            os.remove(s_file)
            #continue
        opts = {"infile": z_file, "maskfile": mask_file, "fwhm": fwhm, 
                "outfile": s_file}
        cmd  = "3dBlurToFWHM -input %(infile)s -mask %(maskfile)s -FWHM %(fwhm)s -prefix %(outfile)s" % opts
        print cmd
        ret = os.system(cmd)
        if ret != 0:
            print "ERROR: non-zero return for roi #%i" % (i+1)
