#!/usr/bin/env python

import numpy as np
import nibabel as nib
from os import path
from surfer import Brain, io
import Image, ImageChops
from glob import glob
from process import Process

from rpy2 import robjects
from rpy2.robjects.packages import importr


def vol_to_surf(infile, hemis=["lh", "rh"], outdir=None, interp="lin"):
    """transforms overlay from volume to surface"""
    interp_choices = {"lin": "trilinear", "nn": "nearest"}
    
    substitute = dict(input=infile, interp=interp_choices[interp])
    outfiles = {}
    for hemi in hemis:
        substitute["hemi"] = hemi
        if outdir is None:
            outdir = path.dirname(infile)
        output = "%s/surf_%s_%s.nii.gz" % (outdir, \
                                           hemi, \
                                           path.basename(infile).replace(".nii.gz", ""))
        substitute["output"] = output
        outfiles[hemi] = output
        
        #cmd = "mri_vol2surf --mov %(input)s \
        #--mni152reg --projfrac 0.5 --interp trilinear --hemi %(hemi)s \
        #--out %(output)s --reshape" % substitute
        
        cmd = "mri_vol2surf --mov %(input)s --interp %(interp)s \
        --mni152reg --projfrac-max 0 1 0.1 --hemi %(hemi)s \
        --out %(output)s --reshape" % substitute
           
        print cmd
        p = Process(cmd)
        print p.stdout
        print p.stderr
        if p.retcode != 0:
            raise Exception("mri_vol2surf failed")
    return outfiles

class SurfWrap(object):
    """A pipeline to visualize functional overlays with pysurfer"""
    def __init__(self, name=None, infile=None, cbar=None, outprefix=None, hemis=["lh", "rh"], interp="trilinear"):
        """hemis => hemispheres to plot"""
        super(SurfWrap, self).__init__()
        self.hemis = hemis
        self.interp = interp
        if name is not None:
            self.set_underlay()
            self.set_overlay(name, infile, cbar)
            self.set_options()
            self.set_output(outprefix)
        return
    
    def set_underlay(self, subject_id="fsaverage_copy", surf="iter8_inflated", 
                     subjects_dir="/home2/data/PublicProgram/freesurfer"):
        """Sets the underlay by calling the Brain class...later"""
        self.subject_id = subject_id
        self.surf = surf
        self.subjects_dir = subjects_dir
        return
        
    def vol_to_surf(self, interp="trilinear"):
        """transforms overlay from volume to surface"""
        substitute = dict(input=self.overlay_vol, interp=interp)
        self.overlay_surf = {}
        for hemi in self.hemis:
            substitute["hemi"] = hemi
            output = "%s/surf_%s_%s.nii.gz" % (path.dirname(self.overlay_vol), \
                                               hemi, \
                    path.basename(self.overlay_vol).replace(".nii.gz", ""))
            substitute["output"] = output
            self.overlay_surf[hemi] = output
            
            cmd = "mri_vol2surf --mov %(input)s \
            --mni152reg --projfrac-max 0 1 0.1 \
            --interp %(interp)s --hemi %(hemi)s \
            --out %(output)s --reshape" % substitute
            
            print cmd
            p = Process(cmd)
            print p.stdout
            print p.stderr
            if p.retcode != 0:
                raise Exception("mri_vol2surf failed")
        return
    
    def set_overlay(self, name, volume_file, cbar, min='auto', max='auto', sign="auto"):
        """
        volume_file: path to file with overlay in volume space, will transform to surface space
        cbar: options include only red-yellow for now
        sign: has options auto, abs, pos, and neg
        min/max: float, otherwise if 'auto' will determine nonzero min / max
        """
        self.overlay_name = name
        volume_file = path.abspath(volume_file)
        self.overlay_vol = volume_file
        
        # might want to take into account if negative as well!
        if min == 'auto' or max == 'auto' or sign == 'auto':
            img = nib.load(volume_file)
            data = img.get_data()
            data_max = data.max()
            if data_max == 0:
                data_min = data_max
            else:
                data_min = data[data.nonzero()].min()
            if max == 'auto': max = data_max
            if min == 'auto': min = data_min
            if sign == 'auto':
                if data_min < 0 and data_max > 0:
                    sign = "abs"
                elif data_min > 0:
                    sign = "pos"
                else:
                    sign = "neg"
        self.min    = min
        self.max    = max
        self.sign   = sign
        
        if isinstance(cbar, str):
            filepath = path.abspath(path.join(path.dirname(__file__), "colorbars", "%s.txt" % cbar))
            self.colorbar = np.loadtxt(filepath)
            #self.colorbar = cbar
        elif isinstance(cbar, np.ndarray):
            if cbar.shape[1] != 4:
                raise Exception("cbar array must have 4 columns for rgb and the alpha channel")
            ncols     = cbar.shape[0]
            lut       = np.zeros((256,4))
            steps     = range(0, 256, np.floor(256.0/ncols).astype('int'))
            steps[-1] = 256
            for i in range(ncols):
                lut[steps[i]:steps[i+1],:] = cbar[i,:]
        else:
            raise Exception("unrecognized type %s for cbar" % type(cbar))        
        
        self.vol_to_surf(self.interp)
        return
    
    def set_options(self, background="white", **opts):
        """
        The config_opts that go into a new Brain class.
        
        **opts can be
            - cortex
              preset choices: classic, bone, high_contrast, and low_contrast
            - size
              size of window (a positive number)
            - default_view
              choices: lateral, medial, rostral, caudal, dorsal, ventral, frontal, and parietal
        
        TODO: add something nicer for 'cortex'
              - colormap for the binarized curvature on the cortex (any cortical curvature color scheme name)
        """
        opts["background"] = background
        self.config_opts = opts
        return
    
    def set_output(self, prefix, views=["med", "lat"]):
        """output prefix for the saved images"""
        self.outprefix = path.abspath(prefix)
        self.views = views
        return
    
    def run(self, compilation="stick"):
        self.vizify()
        self.cropify()
        self.montage(compilation)
        return
    
    def vizify(self):
        for hemi in self.hemis:
            print "visualize %s" % hemi
            
            # Bring up the beauty (the underlay)
            brain = Brain(self.subject_id, hemi, self.surf, \
                          config_opts=self.config_opts, \
                          subjects_dir=self.subjects_dir)
            
            surf_data = io.read_scalar_data(self.overlay_surf[hemi])
            if (sum(abs(surf_data)) > 0):
                # Overlay another hopeful beauty (functional overlay)
                brain.add_overlay(self.overlay_surf[hemi], name=self.overlay_name, 
                                  min=self.min, max=self.max, sign=self.sign)
            
                # Update colorbar
                #brain.overlays[self.overlay_name].pos_bar.lut_mode = self.colorbar
                tmp = brain.overlays[self.overlay_name]
                lut = tmp.pos_bar.lut.table.to_array()
                lut[:,0:3] = self.colorbar
                tmp.pos_bar.lut.table = lut
            
                # Refresh
                brain.show_view("lat")
                brain.hide_colorbar()
            
            # Save the beauts
            brain.save_imageset("%s_%s" % (self.outprefix, hemi), self.views, 
                                'jpg', colorbar=None)
            
            # End a great journey, till another life
            brain.close()
        return
    
    def cropify(self):
        """Crops output images"""
        print "crop images"
        # Oh we are back!
        for fpath in self._outpaths():
            print "\t%s" % fpath
            im = Image.open(fpath)
            im = im.convert("RGBA")
            bg = Image.new("RGBA", im.size, (255,255,255,255))
            diff = ImageChops.difference(im,bg)
            bbox = diff.getbbox()
            im2 = im.crop(bbox)
            im2.save(fpath)
    
    def _outpaths(self):
        fpaths = glob("%s_*.jpg" % self.outprefix)
        return fpaths
    
    def montage(self, compilation="stick"):
        """
        this will put together the lh/rh med/lat images
        
        compilation: can be stick (1x4) or box (2x2)
        """
        print "montage"
        
        # pre-reqs
        jpeg = importr('jpeg')
        r = robjects.r
        
        # R functions for creating the montage
        r.source(path.join(path.dirname(__file__), "montage_functions.R"))
        surfer_montage_coords = robjects.globalenv["surfer_montage_coords"]
        surfer_montage_dims = robjects.globalenv["surfer_montage_dims"]
        surfer_montage_viz = robjects.globalenv["surfer_montage_viz"]
        
        # Files ordered for proper display
        if compilation == "stick":
            order_views = [ "lh_lat", "lh_med", "rh_med", "rh_lat" ]
        elif compilation == "box":
            order_views = [ "lh_lat", "lh_med", "rh_lat", "rh_med" ]
        elif compilation == "uni_lh":
            order_views = [ "lh_lat", "lh_med" ]
        fpaths = [ "%s_%s.jpg" % (self.outprefix,ov) for ov in order_views ]
        
        # Read in images
        images = r.lapply(fpaths, jpeg.readJPEG)
        
        # Get coordinates on montage of multiple images
        if compilation == "stick":
            scalings = robjects.FloatVector([1,0.95,0.95,1])
            coords = surfer_montage_coords(images, 1, 4, scalings, 12)
        elif compilation == "box":
            scalings = robjects.FloatVector([1,0.96,1,0.96])
            coords = surfer_montage_coords(images, 2, 2, scalings, 24, 12)
        elif compilation == "uni_lh":
            scalings = robjects.FloatVector([1,0.95])
            coords = surfer_montage_coords(images, 1, 2, scalings, 12)
        
        # Plot and save montage
        outdir  = path.dirname(self.outprefix)
        outbase = path.basename(self.outprefix)
        ofile   = "%s/montage-%s_%s.png" % (outdir, compilation, outbase)
        r.png(ofile, width=coords[6], height=coords[7])
        surfer_montage_viz(images, coords)
        r["dev.off"]()
        
        print "...see %s" % ofile
        
        return
    
