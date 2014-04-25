#!/usr/bin/env python

import os, shutil, sys
import nibabel as nib
import tempfile


def vol2surf_enhanced(**cvars):
    """cvars should be unthr_file, thr_file, thr, oprefix, and overwrite"""
    hemis   = ["lh", "rh"]
    
    for hemi in hemis:
        ofile = "%s_%s.nii.gz" % (cvars['oprefix'], hemi)
        if os.path.exists(ofile):
            if cvars['overwrite']:
                os.remove(ofile)
            else:
                raise Exception("Output already exists")
    
    tmpdir  = tempfile.mkdtemp()
    cvars['tmpdir'] = tmpdir

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


# Given the threshold and unthresholded input files
# and the output prefix
# When this script is called
# Then intermediate surface files will be created for each input
# and new surface files are created as a conjunction of the two inputs

if len(sys.argv) != 3:
    print "usage: %s easy-thresh-dir condition" % sys.argv[0]
    sys.exit(1)

easy_dir    = sys.argv[1]
condition   = sys.argv[2]

unthr_file  = "%s/zstat_%s.nii.gz" % (easy_dir, condition)
thr_file    = "%s/thresh_zstat_%s.nii.gz" % (easy_dir, condition)
oprefix     = "%s/surf_thresh_zstat_%s" % (easy_dir, condition)

thr_data    = nib.load(thr_file).get_data()
if thr_data.sum() == 0:
    print "No data in file"
    sys.exit(2)
thr         = thr_data[thr_data.nonzero()].min()

cvars = {
    "unthr_file": unthr_file, 
    "thr_file": thr_file,
    "thr": thr, 
    "oprefix": oprefix, 
    "overwrite": False
}


###
# Register to Surface
###

print "register to surface"

vol2surf_enhanced(**cvars)
