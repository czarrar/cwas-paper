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
infiles1    <- file.path(indir, sprintf("%s.nii.gz", measures))
infiles2    <- file.path(indir, sprintf("%s_zscore.nii.gz", measures))

# Output directory
outdir      <- "/home2/data/Projects/CWAS/results/10_summarize_distances"


###
# Read NIFTI
###

cat("Load niftis\n")

# Mask
mask <- read.mask(mask_file)

# Voxelwise Images
imgs1 <- sapply(infiles1, function(f) read.nifti.image(f)[mask])
imgs2 <- sapply(infiles2, function(f) read.nifti.image(f)[mask])

# Only use the second set of images
cv.scan1 <- imgs2[,1]
cv.scan2 <- imgs2[,2]


###
# Dirty Work
###

# Compute correlations
cat("Computing correlations\n")
pearson.r   <- cor(cv.scan1, cv.scan2, method="pearson")
spearman.r  <- cor(cv.scan1, cv.scan2, method="spearman")
kendall.r   <- cor(cv.scan1, cv.scan2, method="kendall")

# Save
cat("Saving\n")
df.r        <- data.frame(
    measure = c("pearson", "spearman", "kendall"), 
    value   = c(pearson.r, spearman.r, kendall.r)
)
print(df.r)
write.table(df.r, file=file.path(outdir, "10_cv_scan_similarity.txt"))
