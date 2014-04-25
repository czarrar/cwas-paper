#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(niftir))


###
# Paths
###

cat("Paths\n")

basedir     <- "/home2/data/Projects/CWAS/nki/stability"
strategy    <- "N104_compcor"
kstr        <- "kvoxs_fwhm08_to_kvoxs_fwhm08"
measures    <- c("consistency")
mask_file   <- "/home2/data/Projects/CWAS/nki/rois/mask_gray_4mm.nii.gz"

# Input Directory
indir       <- file.path(basedir, sprintf("%s_%s", strategy, kstr))

# Input Measure Files
infiles     <- file.path(indir, sprintf("%s.nii.gz", measures))

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

# Only use the second set of images
consist  <- imgs[,1]


###
# Dirty Work
###

# Ranges
cat("Computing mean, sd, and ranges\n")
df <- data.frame(
    mean = mean(consist), 
    sd = sd(consist), 
    min = min(consist), 
    max = max(consist)
)

# Save
cat("Saving\n")
print(df)
write.table(df, file=file.path(outdir, "20_consistency_ranges.txt"))
