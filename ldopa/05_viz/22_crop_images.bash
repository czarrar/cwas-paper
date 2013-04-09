#!/usr/bin/env python

# First will crop the image and will then make background transparent

import os
import Image, ImageChops
from glob import glob

os.chdir("/home2/data/Projects/CWAS/ldopa/viz")

fpaths = glob("*.jpg")

for fpath in fpaths:
    print fpath
    im = Image.open(fpath)
    im = im.convert("RGBA")
    bg = Image.new("RGBA", im.size, (255,255,255,255))
    diff = ImageChops.difference(im,bg)
    bbox = diff.getbbox()
    im2 = im.crop(bbox)
    im2.save(fpath)
