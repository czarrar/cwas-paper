#!/usr/bin/env python

import sys
from os import path as op
import nibabel as nib
import numpy as np

if len(sys.argv) != 3:
    print "usage: x_fischer_transform.py func-file mask-file"
    sys.exit(2)

def check_input_file(fname):
    """checks if the fname exists, otherwise exits"""
    if not op.exists(fname):
        print "ERROR: input file '%s' doesn't exist" % fname
    return

func_file = sys.argv[1]
mask_file = sys.argv[2]
check_input_file(func_file)
check_input_file(mask_file)

print "...loading data"
mask = nib.load(mask_file).get_data().astype('bool')
mask_indices = np.where(mask)

img  = nib.load(func_file)
data = img.get_data()
data[mask_indices] = np.arctanh(data[mask_indices])

hdr = data.get_header()

dims = data.shape

x, y, z, one, roi_number = dims

corr_data