#!/usr/bin/env python

# In another class get the range
# takes the volume and loads with nib load
# get min and max

import nibabel

class ImgRange(object):
    """Gets the non-zero min and max of image"""
    def __init__(self, filepath):
        super(ImgRange, self).__init__()
        self.img = nib.load(filepath)
        return
    
    def __call__(self):
        """returns a range or list"""
        return self.range()
    
    def range(self):
        data = img.get_data()
        data_max = data.max()
        if data_max == 0:
            data_min == 0
        else:
            data_min = data[data.nonzero()].min()
        return {"min": data_min, "max": data_max}
    
    def min(self):
        return self.range()["min"]
        
    def max(self):
        return self.range()["max"]
    


# 


# Select color-scale
cols = np.loadtxt("z_red_yellow.txt")   # Load color table


# Underlay

# 
        """Bring up the visualization"""
        brain = Brain("fsaverage_copy", "lh", "iter8_inflated",
                      config_opts=dict(background="white"), 
                      subjects_dir="/home2/data/PublicProgram/freesurfer")
        
        """Get the volume => surface file"""
        cwas_file = path.join(mdmr_dir, "surf_lh_clust_logp_%s.nii.gz" % factor)

        """
        You can pass this array to the add_overlay method for
        a typical activation overlay (with thresholding, etc.)
        """
        brain.add_overlay(cwas_file, min=data_min, max=data_max, name="%s_lh" % factor)

        ## get overlay and color bar
        tmp1 = brain.overlays["%s_lh" % factor]
        lut = tmp1.pos_bar.lut.table.to_array()

        ## update color scheme
        lut[:,0:3] = cols
        tmp1.pos_bar.lut.table = lut

        ## refresh view
        brain.show_view("lat")
        brain.hide_colorbar()

        """
        Save some images
        """
        odir = "/home/data/Projects/CWAS/%s/viz" % study
        brain.save_imageset(path.join(odir, "zpics_surface_%s_lh" % onames[i][j]), 
                            ['med', 'lat', 'ros', 'caud'], 'jpg')

        brain.close()
