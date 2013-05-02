#!/usr/bin/env Rscript

# This script generates brain mask for each subject in 4mm space
# and then creates the group brain mask


###
# Individual Subject Masks
###

basedir <- "/home2/data/Projects/CWAS/share/adhd200_rerun"
funcpaths <- read.table(file.path(basedir, "subinfo/30_compcor_funcpaths_4mm.txt"))[,1]
funcpaths <- as.character(funcpaths)

cmd <- "fslmaths %s -Tmin -abs -bin %s"

maskfiles <- sapply(funcpaths, function(funcpath) {
    outdir <- dirname(dirname(funcpath))
    outfile <- file.path(outdir, "functional_brain_mask_to_standard_4mm.nii.gz")
    real_cmd <- sprintf(cmd, funcpath, outfile)
    
    cat(real_cmd, "\n")
    system(real_cmd)
    
    return(outfile)
})


###
# Group Mask
###

library(niftir)

outfile <- file.path("/home2/data/Projects/CWAS/adhd200_rerun", "rois", "mask_gray_4mm.nii.gz")
std_mask_file <- file.path("/home2/data/Projects/CWAS/adhd200_rerun", "rois", "grey_matter_4mm.nii.gz")

hdr <- read.nifti.header(std_mask_file)
overlap_mask <- read.mask(std_mask_file)

for (maskfile in maskfiles)
    overlap_mask <- overlap_mask & read.mask(maskfile)

write.nifti(overlap_mask*1, hdr, outfile=outfile, odt="int")
