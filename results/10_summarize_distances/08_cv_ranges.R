#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(niftir))


###
# Paths
###

cat("Paths\n")

basedir     <- "/home2/data/Projects/CWAS/nki/stability"
strategy    <- "N104_compcor"
kstr        <- "kvoxs_fwhm08_to_kvoxs_fwhm08"
measures    <- c("cv_short", "cv_medium", "consistency")
mask_file   <- "/home2/data/Projects/CWAS/nki/rois/mask_gray_4mm.nii.gz"

# Input Directory
indir       <- file.path(basedir, sprintf("%s_%s", strategy, kstr))

# Input Measure Files
infiles    <- file.path(indir, sprintf("%s.nii.gz", measures))

# Output directory
outdir      <- "/home2/data/Projects/CWAS/results/10_summarize_distances"


###
# Read NIFTI
###

cat("Load niftis\n")

# Mask
mask <- read.mask(mask_file)

# Voxelwise Images
imgs <- sapply(infiles, function(f) read.nifti.image(f)[mask])

cv.scan1 <- imgs[,1]
cv.scan2 <- imgs[,2]


###
# Dirty Work
###

# Ranges
cat("Computing mean, sd, and ranges\n")
df <- data.frame(
    scan = c("scan 1", "scan 2"), 
    mean = c(mean(cv.scan1), mean(cv.scan2)), 
    sd = c(sd(cv.scan1), sd(cv.scan2)), 
    min = c(min(cv.scan1), min(cv.scan2)), 
    max = c(max(cv.scan1), max(cv.scan2))
)

# Save
cat("Saving\n")
print(df)
write.table(df, file=file.path(outdir, "08_cv_ranges.txt"))

