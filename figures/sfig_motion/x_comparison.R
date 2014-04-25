#!/usr/bin/env Rscript

library(niftir)
library(ggplot2)

dice <- function(a,b) (2*sum(a&b))/(sum(a)+sum(b))


###
# SETUP
###

# General Variables
base    <- "/home2/data/Projects/CWAS"
outdir  <- file.path(base, "figures/sfig_motion")

# Basics
study   <- "development+motion"
prefix  <- file.path(base, study, "cwas")

# MDMR
mdmr_subpaths <- list(
    "compcor_age+motion"        = "compcor_kvoxs_smoothed/age+motion_sex+tr.mdmr", 
    "global_age+motion"         = "global_kvoxs_smoothed/age+motion_sex+tr.mdmr", 
    "compcor_age+motion+gcor"   = "compcor_kvoxs_smoothed/age+motion_sex+tr+meanGcor.mdmr"
)

# Thresholded data
suffix_thr  <- "cluster_correct_v05_c05/easythresh/thresh_zstat_mean_FD.nii.gz"
logp_paths <- file.path(prefix, mdmr_subpaths, suffix_thr)
names(logp_paths) <- names(mdmr_subpaths)

# Unthresholded data
suffix_uthr <- "cluster_correct_v05_c05/easythresh/zstat_mean_FD.nii.gz"
ulogp_paths <- file.path(prefix, mdmr_subpaths, suffix_uthr)
names(ulogp_paths) <- names(mdmr_subpaths)

# Brain masks
mask_paths <- file.path(dirname(file.path(prefix, mdmr_subpaths)), "mask.nii.gz")
names(mask_paths) <- names(mdmr_subpaths)

# Number of files
n <- length(logp_paths)


###
# THRESHOLDED
###

cat("Thresholded Data\n")

# Read in the files
dat <- sapply(1:n, function(i) {
    logp_path <- logp_paths[i]
    mask_path <- mask_paths[i]
    logp <- read.nifti.image(logp_path)[read.mask(mask_path)]
    return(logp)
})
colnames(dat) <- names(mdmr_subpaths)

# N voxels active
cat("...% voxels with significant associations\n")
n.dat <- colMeans(dat>0)
names(n.dat) <- names(mdmr_subpaths)
print(n.dat)



###
# Save
###

write.table(n.dat, file=file.path(outdir, "B_thr_nvoxs.txt"))
