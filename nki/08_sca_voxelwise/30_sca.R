#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(niftir))
library(plyr)

ijk2ind <- function(ijk, hdr) {
    ijk <- ijk - 1
    ret <- ijk[3]*prod(hdr$dim[2:3]) + ijk[2]*hdr$dim[3] + ijk[1] + 1
    return(ret)
}


read_peaks <- function(fname, ...) {
    peaks <- read.table(fname, skip=10)
    colnames(peaks) <- c("Index", "Intensity", "x", "y", "z", "Count", "Dist")
    peaks$x <- peaks$x * -1    # invert to make compatible with MNI space
    peaks$y <- peaks$y * -1
    return(peaks)
}

base    <- "/home2/data/Projects/CWAS"
indir   <- file.path(base, "nki/sca_voxelwise_scan1/20_rois")
odir    <- file.path(base, "nki/sca_voxelwise_scan1/30_sca")
dir.create(odir)


###
# ROIs
###

rois_file   <- file.path(indir, "rois_all_info.csv")
rois_df     <- read.csv(rois_file)


###
# MASK AND CONVERT FROM VOXEL 2 MASKED INDICES
###

mask            <- read.mask(file.path(base, "nki/rois/mask_gray_4mm.nii.gz"))
hdr             <- read.nifti.header(file.path(base, "nki/rois/mask_gray_4mm.nii.gz"))

vox2mask        <- mask*1
vox2mask[mask]  <- 1:sum(mask)



###
# MDMR/GLM SUMMARY DATA
###

glm_df1 <- read.csv(file.path(base, "nki/glm/short_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/summary/dataframe_glm+mdmr.csv"))
glm_df2 <- read.csv(file.path(base, "nki/glm/medium_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/summary/dataframe_glm+mdmr.csv"))

glm_df1 <- glm_df1[1:sum(mask),-1]
glm_df2 <- glm_df2[1:sum(mask),-1]

glm_df <- cbind(scan=rep(c("short", "medium"), each=sum(mask)), rbind(glm_df1, glm_df2))



###
# Estimated SCA
###

# Voxel Indices of ROIs
vox_inds <- laply(1:nrow(rois_df), function(i) {
    row <- rois_df[i,]
    ijk <- as.vector(hdr$qto.ijk %*% c(row$x,row$y,row$z,1))[1:3] + 1
    ind <- ijk2ind(ijk, hdr)
    ind
})



read_peaks <- function(fname, ...) {
    peaks <- read.table(fname, skip=10)
    colnames(peaks) <- c("Index", "Intensity", "x", "y", "z", "Count", "Dist")
    peaks$x <- peaks$x * -1    # invert to make compatible with MNI space
    peaks$y <- peaks$y * -1
    return(peaks)
}

maxima        <- read_peaks(file.path(base, "nki/sca_voxelwise_scan1/10_mdmr_data/maxima_sm6.txt"))
maxima.coords <- as.matrix(maxima[,3:5])
tmp_inds <- laply(1:nrow(maxima.coords), function(i) {
    row <- maxima.coords[i,]
    ijk <- as.vector(hdr$qto.ijk %*% c(row,1))[1:3] + 1
    ind <- ijk2ind(ijk, hdr)
    ind
})
x_inds <- c(tmp_inds, vox_inds[26:length(vox_inds)])

# Masked indices of ROIs
masked_inds <- vox2mask[vox_inds]

xmasked_inds <- vox2mask[x_inds]

# Combine with rois_df
summary_df <- data.frame(
    scan  = rep(c("short", "medium"), each=nrow(rois_df)), 
    label = rep(rois_df$label, 2), 
    stat  = rep(rois_df$stat, 2), 
    mdmr  = c(glm_df1$mdmr[masked_inds], glm_df2$mdmr[masked_inds]), 
    sca   = c(glm_df1$glm.uwt[masked_inds], glm_df2$glm.uwt[masked_inds])
)

summary_df <- data.frame(
    scan  = rep(c("short", "medium"), each=nrow(rois_df)), 
    label = rep(rois_df$label, 2), 
    stat  = rep(rois_df$stat, 2), 
    mdmr  = c(glm_df1$mdmr[masked_inds], glm_df2$mdmr[masked_inds]), 
    sca   = c(glm_df1$glm.uwt[masked_inds], glm_df2$glm.uwt[masked_inds])
)



# Save
write.csv(summary_df, file=file.path(odir, "rois_glm+mdmr.csv"))



### CLUSTER

clust <- read.nifti.image(file.path(base, "nki/sca_voxelwise_scan1/10_mdmr_data/cluster_mask.nii.gz"))

table(clust[vox_inds[1:25]])
