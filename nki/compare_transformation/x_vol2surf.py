#!/usr/bin/env python

import os, shutil, sys
import nibabel as nib
import tempfile

# Given the threshold and unthresholded input files
# and the output prefix
# When this script is called
# Then intermediate surface files will be created for each input
# and new surface files are created as a conjunction of the two inputs

if len(sys.argv) != 4:
    print "usage: %s raw-stats thr-stats out-prefix" % sys.argv[0]
    sys.exit(1)

unthr_file  = sys.argv[1]
thr_file    = sys.argv[2]
oprefix     = sys.argv[3]

thr_data    = nib.load(thr_file).get_data()
thr         = thr_data[thr_data.nonzero()].min()

cvars = {
    "unthr_file": unthr_file, 
    "thr_file": thr_file,
    "thr": thr, 
    "oprefix": oprefix 
}


###
# Register to Surface
###

print "register to surface"

tmpdir  = tempfile.mkdtemp()
cvars['tmpdir'] = tmpdir

hemis   = ["lh", "rh"]

for hemi in hemis:
    cvars['hemi'] = hemi
    print "...hemi: %s" % hemi
    
    cmd = "mri_vol2surf --mov %(unthr_file)s --hemi %(hemi)s --mni152reg --projfrac-max 0 1 0.1 --interp trilinear --out %(tmpdir)s/surf_unthr_%(hemi)s.nii.gz" % cvars
    print cmd
    os.system(cmd)

    cmd = "mri_vol2surf --mov %(thr_file)s --hemi %(hemi)s --mni152reg --projfrac-max 0 1 0.1 --interp trilinear --out %(tmpdir)s/surf_thr_%(hemi)s.nii.gz" % cvars
    print cmd
    os.system(cmd)
    
    cmd = "3dcalc -a %(tmpdir)s/surf_unthr_%(hemi)s.nii.gz -b %(tmpdir)s/surf_thr_%(hemi)s.nii.gz -expr '(step(a-%(thr)s)*a)*step(step(b)-0.5)' -prefix %(oprefix)s_%(hemi)s.nii.gz" % cvars
    print cmd
    os.system(cmd)

shutil.rmtree(tmpdir)
