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
consist  <- imgs2[,3]


###
# Dirty Work
###

# Compute correlations
cat("Computing correlations\n")
pearson.r1  <- cor(cv.scan1, consist, method="pearson")
spearman.r1 <- cor(cv.scan1, consist, method="spearman")
kendall.r1  <- cor(cv.scan1, consist, method="kendall")
pearson.r2  <- cor(cv.scan2, consist, method="pearson")
spearman.r2 <- cor(cv.scan2, consist, method="spearman")
kendall.r2  <- cor(cv.scan2, consist, method="kendall")

# Save
cat("Saving\n")
df.r        <- data.frame(
    measure = c("pearson", "spearman", "kendall"), 
    scan1   = c(pearson.r1, spearman.r1, kendall.r1), 
    scan2   = c(pearson.r2, spearman.r2, kendall.r2)
)
print(df.r)
write.table(df.r, file=file.path(outdir, "30_cv_vs_consistency_similarity.txt"))
