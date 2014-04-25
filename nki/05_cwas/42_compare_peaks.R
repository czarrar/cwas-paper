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
sdist   <- file.path(base, "/nki/cwas/short/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08")
indir   <- file.path(sdist, "iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh")


###
# Peaks
###

peaks_file      <- file.path(indir, "peaks_thresh_zstat_FSIQ.txt")
sm_peaks_file   <- file.path(indir, "peaks_thresh_zstat_FSIQ_sm6.txt")

maxima1        <- read_peaks(peaks_file)
maxima1.coords <- as.matrix(maxima1[,3:5])

maxima2        <- read_peaks(sm_peaks_file)
maxima2.coords <- as.matrix(maxima2[,3:5])

# For later, get numbers
cat("Number of un-smoothed data peaks,", nrow(maxima1.coords), "\n")
cat("Number of smoothed data peaks,", nrow(maxima2.coords), "\n")


###
# Compare distances of two peak sets
###

compare.dists1  <- sapply(1:nrow(maxima1.coords), function(i) {
    dists <- sqrt(rowSums((sweep(maxima2.coords, 2, maxima1.coords[i,]))^2))
    min(dists)
})

compare.dists2  <- sapply(1:nrow(maxima2.coords), function(i) {
    dists <- sqrt(rowSums((sweep(maxima1.coords, 2, maxima2.coords[i,]))^2))
    min(dists)
})

# For later, get additional info
cat("Number of peaks from unsmoothed data also in smoothed data\n")
print(table(compare.dists1==0))
cat("Number of peaks from smoothed data also in unsmoothed data\n")
print(table(compare.dists2==0))    # should be the same


###
# Which cluster?
###

mask        <- read.mask(file.path(base, "nki/rois/mask_gray_4mm.nii.gz"))
hdr         <- read.nifti.header(file.path(base, "nki/rois/mask_gray_4mm.nii.gz"))
clust       <- read.nifti.image(file.path(indir, "cluster_mask_zstat_FSIQ"))

# Get voxel indices
vox1_inds <- laply(1:nrow(maxima1.coords), function(i) {
    row <- as.vector(maxima1.coords[i,])
    ijk <- as.vector(hdr$qto.ijk %*% c(row,1))[1:3] + 1
    ind <- ijk2ind(ijk, hdr)
    ind
})
vox2_inds <- laply(1:nrow(maxima2.coords), function(i) {
    row <- as.vector(maxima2.coords[i,])
    ijk <- as.vector(hdr$qto.ijk %*% c(row,1))[1:3] + 1
    ind <- ijk2ind(ijk, hdr)
    ind
})

# Get cluster membership for each
cat("Unsmoothed peaks\n")
print(table(clust[vox1_inds]))
cat("Smoothed peaks\n")
print(table(clust[vox2_inds]))
cat("Common peaks\n")
print(table(clust[vox1_inds[compare.dists1==0]]))


###
# SCA by cluster
###

# Get indices for the maximas used
rois_df     <- read.csv(file.path(base, "nki/sca/seeds/rois_all_info.csv"))
maximas_df  <- subset(rois_df, label=="maxima")
vox3_inds <- laply(1:nrow(maximas_df), function(i) {
    row <- maximas_df[i,]
    ijk <- as.vector(hdr$qto.ijk %*% c(row$x,row$y,row$z,1))[1:3] + 1
    ind <- ijk2ind(ijk, hdr)
    ind
})

# 
print("Maxima ROI peaks\n")
print(table(clust[vox3_inds]))
maxima_clust_members <- clust[vox3_inds]

# Get the SCA values
summary_df           <- read.csv("/home/data/Projects/CWAS/nki/sca/summarize_sca-iq.csv")
summary_df$clust     <- rep(maxima_clust_members, 3)

ret <- ddply(subset(summary_df, label=="maxima"), .(scan), function(sdf) {
    tapply(sdf$perc, maxima_clust_members, mean)
})



###
# Estimated SCA values for smoothed peaks
###

vox2mask    <- mask*1
vox2mask[mask] <- 1:sum(mask)

# Dataframe with voxelwise SCA
glm_df1 <- read.csv(file.path(base, "nki/glm/short_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/summary/dataframe_glm+mdmr.csv"))
glm_df2 <- read.csv(file.path(base, "nki/glm/medium_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/summary/dataframe_glm+mdmr.csv"))
glm_df1 <- glm_df1[1:sum(mask),-1]; glm_df2 <- glm_df2[1:sum(mask),-1]
glm_df <- cbind(scan=rep(c("short", "medium"), each=sum(mask)), rbind(glm_df1, glm_df2))

# Masked indices for unsmoothed and smoothed peaks
masked1_inds <- vox2mask[vox1_inds]
masked2_inds <- vox2mask[vox2_inds]
masked3_inds <- vox2mask[vox3_inds]

# Get the values?
sca1_means <- ddply(glm_df, .(scan), function(sdf) tapply(sdf$glm.uwt[masked1_inds], clust[vox1_inds], mean))
sca2_means <- ddply(glm_df, .(scan), function(sdf) tapply(sdf$glm.uwt[masked2_inds], clust[vox2_inds], mean))
sca3_means <- ddply(glm_df, .(scan), function(sdf) tapply(sdf$glm.uwt[masked3_inds], clust[vox3_inds], mean))

cat("Maxima\n")
print(sca3_means)
cat("Unsmoothed Data\n")
print(sca1_means)
cat("Smoothed Data\n")
print(sca2_means)
