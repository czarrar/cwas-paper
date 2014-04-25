#!/usr/bin/env Rscript

# This script generates brain mask for each subject in Xmm space
# and then creates the group brain mask

suppressPackageStartupMessages(library(connectir))


# Read in arg
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
    msg <- paste(
        "", 
        "usage: 22_generate_mask_Xmm.R strategy resolution", 
        "strategy: compcor or global", 
        "resolution: integer resolution of resampled data", 
        sep="\n"
    )
    stop(msg)
}
strategy <- as.character(args[1])
res <- as.integer(args[2])

# check
strategies <- c("compcor", "global")
if(!(strategy %in% strategies)) stop("invalid strategy")


###
# Setup
###

# Paths
basedir <- "/home2/data/Projects/CWAS/share/nki"
subinfo <- file.path(basedir, "subinfo")
roidir <- "/home2/data/Projects/CWAS/nki/rois"

# Scan stuff
scans <- c("short", "medium", "long")
scan_folder <- c("40_Set1_N104", "40_Set1_N104", "40_Set2_N92")



###
# Do it
###

maskfiles <- lapply(1:length(scans), function(si) {
    vcat(T, "scan: %s", scans[si])
    
    ## Individual Subjects
    vcat(T, "...individual subjects")
    flist <- file.path(subinfo, scan_folder[si], 
                        sprintf("%s_%s_funcpaths_%imm.txt", scans[si], strategy, res))
    raw <- read.table(flist)[,1]
    funcpaths <- as.character(raw)
    funcpaths <- sub("/home/", "/home2/", funcpaths)
    
    cmd <- "fslmaths %s -Tstd -abs -bin %s"
    maskfiles <- sapply(funcpaths, function(funcpath) {
        outdir <- dirname(dirname(funcpath))
        outfile <- file.path(outdir, 
                    sprintf("functional_brain_mask_to_standard_%imm.nii.gz", res))
        real_cmd <- sprintf(cmd, funcpath, outfile)
        
        if (file.exists(outfile)) {
            cat("skipping, file exists", outfile, "\n")
            return(outfile)
        } else {
            cat(real_cmd, "\n")
            system(real_cmd)
            return(outfile)
        }
    })
    
    return(maskfiles)
})
maskfiles <- unlist(maskfiles)


## Group Mask
vcat(T, "...group mask")

# Files
outfile1 <- file.path(roidir, sprintf("mask_%imm.nii.gz", res))
outfile2 <- file.path(roidir, sprintf("mask_gray_%imm.nii.gz", res))
gray_mask_file <- file.path(roidir, sprintf("grey_matter_%imm.nii.gz", res))

# Initial images
hdr <- read.nifti.header(gray_mask_file)
gray_mask <- read.mask(gray_mask_file)
overlap_mask <- rep(T, length(gray_mask))

# Loop through for group mask
for (maskfile in maskfiles)
    overlap_mask <- overlap_mask & read.mask(maskfile)

# Save
write.nifti(overlap_mask*1, hdr, outfile=outfile1, odt="int")

# Mask by gray matter
overlap_mask <- overlap_mask & gray_mask

# Save
write.nifti(overlap_mask*1, hdr, outfile=outfile2, odt="int")
