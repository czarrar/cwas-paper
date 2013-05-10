#!/usr/bin/env Rscript

# This script generates brain mask for each subject in 4mm space
# and then creates the group brain mask

library(connectir)

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

# Other
strategies <- c("compcor", "global")
strategy <- strategies[1]


###
# Do it
###

maskfiles <- lapply(1:length(scans), function(si) {
    vcat(T, "scan: %s", scans[si])
    
    ## Individual Subjects
    vcat(T, "...individual subjects")
    flist <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_funcpaths_4mm.txt", scans[si], strategy))
    raw <- read.table(flist)[,1]
    funcpaths <- as.character(raw)
    funcpaths <- sub("/home/", "/home2/", funcpaths)
    
    cmd <- "fslmaths %s -Tstd -abs -bin %s"
    maskfiles <- sapply(funcpaths, function(funcpath) {
        outdir <- dirname(dirname(funcpath))
        outfile <- file.path(outdir, "functional_brain_mask_to_standard_4mm.nii.gz")
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
outfile <- file.path(roidir, "mask_gray_4mm.nii.gz")
std_mask_file <- file.path(roidir, "grey_matter_4mm.nii.gz")
    
hdr <- read.nifti.header(std_mask_file)
overlap_mask <- read.mask(std_mask_file)
    
for (maskfile in maskfiles)
    overlap_mask <- overlap_mask & read.mask(maskfile)
    
write.nifti(overlap_mask*1, hdr, outfile=outfile, odt="int")
