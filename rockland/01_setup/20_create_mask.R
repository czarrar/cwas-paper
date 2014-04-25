#!/usr/bin/env Rscript

library(niftir)


# 0. File Paths
cat("File Paths\n")
base    <- "/home2/data/Projects/CWAS"
subinfo <- file.path(base, "share/rockland/subinfo")
roidir  <- file.path(base, "rockland/rois")


# 1. Setup the mask paths
cat("Mask Paths\n")
## read in func paths
funcfile    <- file.path(subinfo, "10_funcpaths.txt")
funcpaths   <- as.character(read.table(funcfile)[,1])
## convert to mask paths
maskname    <- "functional_brain_mask_to_standard_4mm.nii.gz"
maskpaths   <- file.path(dirname(dirname(funcpaths)), maskname)
if (!all(file.exists(maskpaths))) stop("mask path fail")


# 2. Loop through each mask and add onto the other
cat("Loop through individual masks to create overlap and binary\n")
percent_mask    <- read.mask(maskpaths[1])
for (maskpath in maskpaths[-1]) {
    percent_mask <- percent_mask + read.mask(maskpath)
}
percent_mask    <- (percent_mask / length(maskpaths)) * 100
## also create binary mask
mask            <- (percent_mask == 100) * 1


# 3. Save this overlap percent and binary across subject mask
cat("Save\n")
hdr <- read.nifti.header(maskpaths[1])
write.nifti(percent_mask, hdr, out_file=file.path(roidir, "overlap_mask_4mm.nii.gz"))
write.nifti(mask, hdr, out_file=file.path(roidir, "mask_4mm.nii.gz"))


# 4. Load the grey matter mask and mask this
cat("Load 25% grey matter\n")
grey_mask       <- read.mask(file.path(roidir, "grey_matter_4mm.nii.gz"))
mask            <- mask * grey_mask


# 5. Save final mask
cat("Save\n")
write.nifti(mask, hdr, out_file=file.path(roidir, "mask_grey_4mm.nii.gz"))
