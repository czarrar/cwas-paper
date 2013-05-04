#!/usr/bin/env Rscript

# This script generates brain mask for each subject in 2mm space
# and then creates the group brain mask. It makes use of all the
# set 1 short and medium scans as well as set 2 long scans.

###
# Get Individual Subject Masks
###

basedir <- ".."
subinfodir <- file.path(basedir, "subinfo")

scans <- c("short", "medium", "long")
scan_folder <- c("40_Set1_N104", "40_Set1_N104", "40_Set2_N92")

funcpaths <- lapply(1:length(scans), function(si) {
  fn <- file.path(subinfodir, scan_folder[si], sprintf("%s_compcor_funcpaths.txt", scans[si]))
  funcpaths <- read.table(fn)[,1]
  funcpaths <- as.character(funcpaths)
  funcpaths
})
funcpaths <- unlist(funcpaths)

maskfiles <- sapply(funcpaths, function(funcpath) {
  outdir <- dirname(dirname(funcpath))
  outfile <- file.path(outdir, "functional_brain_mask_to_standard.nii.gz")
  return(outfile)
})



###
# Group Mask
###

library(niftir)
library(plyr)

roidir <- "/home2/data/Projects/CWAS/nki/rois"
outfile <- file.path(roidir, "mask_gray_2mm.nii.gz")
std_mask_file <- file.path(roidir, "grey_matter_2mm.nii.gz")

hdr <- read.nifti.header(std_mask_file)
overlap_mask <- read.mask(std_mask_file)

l_ply(maskfiles, function(maskfile) {
  overlap_mask <- overlap_mask & read.mask(maskfile)
}, .progress="text")

write.nifti(overlap_mask*1, hdr, outfile=outfile, odt="int")

