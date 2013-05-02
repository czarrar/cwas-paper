#!/usr/bin/env python

# For now just does MNI152 => MNI305

import shutil
from tempfile import mkdtemp
from os import path
from process import Process

class Convert(object):
    """For now just converts an MNI152 volume image to MNI305 surface image"""
    def __init__(self, infile, outprefix=None):
        super(Convert, self).__init__()
        self.infile = infile
        self.outprefix = outprefix
        return
    
    def _args(self):
        """generates a dictionary of args for cmds"""
        if self.outprefix is None:
            self.tmpdir = mkdtemp()
            prefix = path.splitext(infile)[0].splitext(prefix)[0]
            outprefix = path.join(self.tmpdir, "surf_%s" % prefix)
        else:
            self.tmpdir = None
            outprefix = self.outprefix
        args = ['infile': self.infile]
        args["outfile_lh"] = "%s_lh" % outprefix
        args["outfile_rh"] = "%s_rh" % outprefix
        return args
    
    def _cmds(self):
        args = self._args
        self.cmds = []
        self.cmds.append(
            "mri_vol2surf \
                --mov {infile} \
                --mni152reg \
                --projfrac 0.5 \
                --interp trilinear \
                --hemi lh \
                --out {outfile_lh} \
                --reshape" % args
            )
        self.cmds.append(
            "mri_vol2surf \
                --mov {infile} \
                --mni152reg \
                --projfrac 0.5 \
                --interp trilinear \
                --hemi rh \
                --out {outfile_rh} \
                --reshape" % args
            )
        return
    
    def run(self):
        cmds = self._cmds(args)
        
        for cmd in cmds:
            p = Process(cmd)
            if p.pid != 0:
                print p.stderr
                raise Exception("convert failed - non-zero exit")
        
        return True
    
    def clean(self):
        """removes any temporary directory created for the outputs"""
        if self.outprefix is None:
            shutil.rmtree(self.tmpdir)
        return True

