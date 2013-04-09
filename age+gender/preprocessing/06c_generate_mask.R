# This script will generate the group mask at 4mm

basedir <- "/home2/data/Projects/CWAS/share/age+gender"
funcpaths <- read.table(file.path(basedir, "subinfo/04_all_funcpaths_4mm.txt"))[,1]
funcpaths <- as.character(funcpaths)

# Ugh need to fix the subsample script to create the brain-mask afterwards!

hdr <- read.nifti.header(funcpaths[1])
overlap_mask <- read.mask(funcpaths[1])

