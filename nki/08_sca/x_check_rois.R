#!/usr/bin/env Rscript

# I'm checking the MDMR values from the generating ROIs within this script

suppressPackageStartupMessages(library(niftir))


###
# SETUP
###

base        <- "/home2/data/Projects/CWAS"

# ROI Paths
rois_file2  <- file.path(base, "nki/sca/seeds/rois_2mm.nii.gz")
rois_file4  <- file.path(base, "nki/sca/seeds/rois_4mm.nii.gz")
std_file    <- mask_file   <- file.path(base, "nki/rois/standard_4mm.nii.gz")

# ROI Info
rois_info   <- file.path(base, "nki/sca/seeds/rois_all_info.csv")

# Sample 2mm ROI file into 4mm
file.remove(rois_file4)
system(sprintf("3dresample -inset %s -master %s -prefix %s -rmode NN", rois_file2, std_file, rois_file4))

# MDMR Paths
mask_file   <- file.path(base, "nki/rois/mask_gray_4mm.nii.gz")
sdist_dir   <- file.path(base, "nki/cwas/short/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08")
mdmr_file   <- file.path(sdist_dir, "iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz")
mdmr_file2  <- file.path(sdist_dir, "iq_age+sex+meanFD+meanGcor.mdmr/cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz")

###
# DATA
###

# Load data
mask        <- read.mask(mask_file)
rois        <- read.nifti.image(rois_file4)[mask]
mdmr        <- read.nifti.image(mdmr_file)[mask]
mdmr2       <- read.nifti.image(mdmr_file2)[mask]
rois_df     <- read.csv(rois_info)

# Get ROIs
urois <- sort(unique(rois[rois!=0]))

# Missing?
bad_roi <- !sapply(rois_df$val, function(ur) any(ur == urois))
rois_df$val[bad_roi]
## seem to be missing ROI 308
## ROI 55 is bad!!

# Extract mean MDMR values
roi_mdmr_vals <- sapply(urois, function(ur) mean(mdmr[rois==ur]))

# Examine mean of means
maxs <- mean(roi_mdmr_vals[urois>99 & urois<200])
sigs <- mean(roi_mdmr_vals[urois>99 & urois<300])
nigs <- mean(roi_mdmr_vals[urois>299 & urois<400])
mins <- mean(roi_mdmr_vals[urois>399 & urois<500])

# Compare with other df
sapply(urois, function(ur) {
    ref_stat <- rois_df$stat[rois_df$val == ur]
    stats <- mdmr[rois==ur]
    sum(abs(stats - ref_stat) < 0.001)
})

tmp1 <- sapply(urois, function(ur) {
    ref_stat <- rois_df$stat[rois_df$val == ur]
    stats <- mdmr[rois==ur]
    stats[which.min(abs(stats - ref_stat))]
})

tmp2 <- sapply(urois, function(ur) {
    ref_stat <- rois_df$stat[rois_df$val == ur]
    stats <- mdmr[rois==ur]
    min(abs(stats - ref_stat))
})

tmp3 <- sapply(urois, function(ur) {
    ref_stat <- rois_df$stat[rois_df$val == ur]
    stats <- mdmr[rois==ur]
    c(ref_stat, stats[4])
})



# meanGcor
roi_mdmr_vals2 <- sapply(urois, function(ur) mean(mdmr2[rois==ur]))
maxs2 <- mean(roi_mdmr_vals2[urois>99 & urois<200])
sigs2 <- mean(roi_mdmr_vals2[urois>99 & urois<300])
nigs2 <- mean(roi_mdmr_vals2[urois>299 & urois<400])
mins2 <- mean(roi_mdmr_vals2[urois>399 & urois<500])
