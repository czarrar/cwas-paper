#!/usr/env/bin Rscript

#' This script will get the summary SCA values for the 100 ROIs (scan 1)
#' 
#' 1. Load the coordinates used for the ROIs
#'    Also load the glm-mdmr dataframe with voxelwise results
#' 2. Transform the coordinates to voxel indices and masked voxel indices
#' 3. Get the mdmr values and check those match with the data frame
#'    and Get the sca values from the same summary matrix
#'
#' Loads scan 1 first and then scan 2. Finally combines them.
#' Note these are seeds for scan 1

suppressPackageStartupMessages(library(niftir))
library(plyr)

#' # General
#+ general
base        <- "/home2/data/Projects/CWAS"
odir        <- file.path(base, "nki/sca/seeds")
rois_df     <- read.csv(file.path(base, "nki/sca/seeds/rois_all_info.csv"))
mask        <- read.mask(file.path(base, "nki/rois/mask_gray_4mm.nii.gz"))
hdr         <- read.nifti.header(file.path(base, "nki/rois/mask_gray_4mm.nii.gz"))
# Go from voxel indices to masked indices
vox2mask    <- mask*1
vox2mask[mask] <- 1:sum(mask)
ijk2ind <- function(ijk, hdr) {
    ijk <- ijk - 1
    ret <- ijk[3]*prod(hdr$dim[2:3]) + ijk[2]*hdr$dim[3] + ijk[1] + 1
    return(ret)
}


###
# SCAN 1
###

#' # 1: Load
#' Load the coordinates used for the ROIs amongst other things
#+ load
summary_df  <- read.csv(file.path(base, "nki/glm/short_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/summary/dataframe_glm+mdmr.csv"))
mdmr        <- read.nifti.image(file.path(base, "nki/cwas/short/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz"))

#' # 2: Transform
#' Convert the coordinates to vector indices
#+ transform
# Scan 1
vox_inds <- laply(1:nrow(rois_df), function(i) {
    row <- rois_df[i,]
    ijk <- as.vector(hdr$qto.ijk %*% c(row$x,row$y,row$z,1))[1:3] + 1
    ind <- ijk2ind(ijk, hdr)
    ind
})
masked_inds <- vox2mask[vox_inds]

#+ checks
all.equal(round(rois_df$stat, 3), round(mdmr[vox_inds], 3))
all.equal(round(summary_df$mdmr[masked_inds], 3), round(mdmr[vox_inds], 3))

#' # 3: Extract
new_df1 <- subset(rois_df, select=c(label, val))
new_df1$scan <- "short"
new_df1$mdmr <- summary_df$mdmr[masked_inds]
new_df1$glm <- summary_df$glm.uwt[masked_inds]



###
# SCAN 2
###

#' # 1: Load
#' Load the coordinates used for the ROIs amongst other things
#+ load
summary_df  <- read.csv(file.path(base, "nki/glm/medium_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/summary/dataframe_glm+mdmr.csv"))
mdmr        <- read.nifti.image(file.path(base, "nki/cwas/medium/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz"))

#' # 2: Transform
#' Convert the coordinates to vector indices
#+ transform
# Scan 1
vox_inds <- laply(1:nrow(rois_df), function(i) {
    row <- rois_df[i,]
    ijk <- as.vector(hdr$qto.ijk %*% c(row$x,row$y,row$z,1))[1:3] + 1
    ind <- ijk2ind(ijk, hdr)
    ind
})
masked_inds <- vox2mask[vox_inds]

#+ checks
all.equal(round(summary_df$mdmr[masked_inds], 3), round(mdmr[vox_inds], 3))

#' # 3: Extract
new_df2 <- subset(rois_df, select=c(label, val))
new_df2$scan <- "medium"
new_df2$mdmr <- summary_df$mdmr[masked_inds]
new_df2$glm <- summary_df$glm.uwt[masked_inds]



###
# COMBINE
###

new_df <- rbind(new_df1, new_df2)
write.csv(new_df, file=file.path(odir, "summarize_glm-iq.csv"))
