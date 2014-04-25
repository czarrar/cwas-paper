#!/home2/data/PublicProgram/epd-7.2-2-rh5-x86_64/bin/python

import Image, ImageChops
from glob import glob

fpaths = glob("/home2/data/Projects/CWAS/figures/fig_07/B*.png")
for fpath in fpaths:
    print "\t%s" % fpath
    
    im = Image.open(fpath)
    im = im.convert("RGBA")
    bg = Image.new("RGBA", im.size, (255,255,255,255))
    diff = ImageChops.difference(im,bg)
    bbox = diff.getbbox()
    im2 = im.crop(bbox)
    
    datas = im2.getdata()
    newData = []
    for item in datas:
        if item[0] == 255 and item[1] == 255 and item[2] == 255:
            newData.append((255, 255, 255, 0))
        else:
            newData.append(item)
    im2.putdata(newData)
    
    im2.save(fpath)
