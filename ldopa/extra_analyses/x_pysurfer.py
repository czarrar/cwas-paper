#!/usr/bin/env python

"""
This script acts as a simple wrapper around pysurfer. The main difference are 
additional color scale options and better/easier montage options. Also multiple
overlays are allowed. It requires a particular shared library.
"""

import argparse

parser = argparse.ArgumentParser(description="Render functional data onto the surface using pysurfer")
parser.add_argument('--name', required=True, help="Name to give the overlay")
parser.add_argument('--lh', help="Name of surface file for the left-hemisphere")
parser.add_argument('--rh', help="Name of surface file for the right-hemisphere")
parser.add_argument('--color', help="Can be a path to a text file with color information or even a numpy array (this may not work)")
parser.add_argument('--min', default=None, type=float, help="Minimum value to display for overlay (default: autoset).")
parser.add_argument('--max', default=None, type=float, help="Maximum value to display for overlay (default: autoset).")
parser.add_argument('--sign', default="pos", help="Maximum value to display for overlay (default: autoset).")
parser.add_argument('--outdir', required=True, help="Output directory. Output file will be a combination of outdir and name.")

args = parser.parse_args()



# If all the parsing is good, load the other libraries
import sys
sys.path.append("/home2/data/Projects/CWAS/share/lib/surfwrap")

import os
from os import path as op
import numpy as np
import nibabel as nib
from newsurf import *


# Setup the basic dictionary
overlays = {
    args.name: []
}
for hemi in ["lh", "rh"]:
    if hemi in args:
        overlays[args.name].append({
            "name": args.name, 
            "hemi": hemi, 
            "file": getattr(args, hemi), 
            "color": args.color, 
            "sign": args.sign
        })

# Do we need to set the min/max?
if args.min is None or args.max is None:
    tmin = []; tmax = []
    for name,ois in overlays.iteritems():
        for oi in ois:
            lmin, lmax, _ = auto_minmax(oi["file"])
            tmin.append(lmin); tmax.append(lmax)
    if args.min is None:
        args.min  = np.min(tmin)
    if args.max is None:
        args.max  = np.max(tmax)

# Set the min and max
for name,oi in overlays.iteritems():
    for i in range(len(oi)):
        overlays[name][i]["min"] = args.min
        overlays[name][i]["max"] = args.max


def visualize_hemisphere(overlay_info, outprefix):
    """docstring for visualize_hemisphere"""
    # Setup overlay info
    oi = overlay_info
    
    # Render underlay
    brain = fsaverage(oi["hemi"])
        
    # Load overlay
    overlay_data = io.read_scalar_data(oi["file"])
    
    # Load colorbar
    cbar = load_colorbar(oi["color"])
    
    # Render overlay
    brain = add_overlay(oi["name"], brain, overlay_data, cbar, 
                        oi["min"], oi["max"], oi["sign"])
     
    # Save
    save_imageset(brain, outprefix, oi["hemi"])
    
    return brain

def visualize_and_montage(name, overlay_info, outdir):
    outprefix = op.join(outdir, "surf_%s" % name)
    for oi in overlay_info:
        brain = visualize_hemisphere(oi, outprefix)
        brain.close()
    montage_types=["box"]   # need to allow this be in options
    for montage_type in montage_types:
        montage(outprefix, compilation=montage_type)

for name,overlay_infos in overlays.iteritems():
    visualize_and_montage(name, overlay_infos, args.outdir)
    # move the montage file to a nicer location
