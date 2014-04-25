#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(niftir))
library(plyr)
library(ggplot2)


####
# Setup
####

base  <- "/home2/data/Projects/CWAS/nki/cwas"
scans <- c("short", "medium")

# mask
mask_file <- "/home/data/Projects/CWAS/nki/rois/mask_gray_4mm.nii.gz"
mask <- read.mask(mask_file)
nvoxs <- sum(mask)

outdir <- "/home2/data/Projects/CWAS/figures/sfig_roi_comparison"
if (!file.exists(outdir)) dir.create(outdir)

ks <- c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400)
str_ks <- sprintf("rois_random_k%04i", ks)
voxels <- "kvoxs_fwhm08_to_kvoxs_fwhm08"
all_ks <- c(str_ks, voxels)

#' Subject Distances
paths <- ldply(scans, function(scan) {
  sdirs  <- file.path(base, scan, sprintf("compcor_%s", all_ks))
  rfiles <- file.path(roidir, sprintf("rois_random_k%04i.nii.gz", ks))
  n <- length(sdirs)
  data.frame(
    k         = c(ks, sum(mask)), 
    scan      = rep(scan, n), 
    sdir      = file.path(sdirs, "subdist.desc"), 
    roifile   = c(rfiles, NA)
  )
})


# Voxelwise distances
vox.dists <- attach.big.matrix(as.character(paths$sdir[nrow(paths)]))

# Get lower half of matrix indices
nsubs <- sqrt(nrow(vox.dists))
matinds     <- matrix(1:nrow(vox.dists), nsubs, nsubs)
lowerinds   <- matinds[lower.tri(matinds)]
nlower      <- length(lowerinds)

# Actually get lower half
lower_vox.dists <- bedeepcopy(x=vox.dists, x.rows=lowerinds)
rm(vox.dists)

# Filter the paths
filt_paths <- subset(paths, k!=sum(mask))
n <- nrow(filt_paths)

sim.vox2rois <- sapply(1:n, function(i) {
    # Loop through each voxel and correlate with the vox.dists
    # Since we are doing a voxelwise correlation, we would want
    # to have a ROI => voxelwise transform.
    cat("Scan", filt_paths$scan[i], "ROI number", filt_paths$k[i], "\n")
    
    ## load ROI distances
    roi.dists <- attach.big.matrix(as.character(filt_paths$sdir[i]))
    lower_roi.dists <- bedeepcopy(x=roi.dists, x.rows=lowerinds)
    rm(roi.dists)
    
    ## read in rois and create mask
    cat("...read in ROIs and create mask\n")
    roi.file <- as.character(filt_paths$roifile[i])
    rois <- read.nifti.image(roi.file)
    hdr  <- read.nifti.header(roi.file)
    mask <- as.vector(rois!=0)
    rois <- rois[mask]  # this basically represents the voxelwise level of the rois
    nvoxs <- sum(mask)

    ## get unique rois and related indices
    cat("...determine unique rois and indices\n")
    urois <- sort(unique(rois))
    urois <- urois[urois!=0]
    nrois <- length(urois)
    rois.inds <- lapply(urois, function(ur) which(rois==ur))

    # Now loop through
    cat("...calculating similarity\n")
    sim.voxroi <- laply(1:nvoxs, function(i) {
        cor(lower_vox.dists[,i], lower_roi.dists[,rois[i]], method="s")
    }, .progress="text")

    return(sim.voxroi)
})

sim.vox2rois_pearson <- sapply(1:n, function(i) {
    # Loop through each voxel and correlate with the vox.dists
    # Since we are doing a voxelwise correlation, we would want
    # to have a ROI => voxelwise transform.
    cat("Scan", filt_paths$scan[i], "ROI number", filt_paths$k[i], "\n")
    
    ## load ROI distances
    roi.dists <- attach.big.matrix(as.character(filt_paths$sdir[i]))
    lower_roi.dists <- bedeepcopy(x=roi.dists, x.rows=lowerinds)
    rm(roi.dists)
    
    ## read in rois and create mask
    cat("...read in ROIs and create mask\n")
    roi.file <- as.character(filt_paths$roifile[i])
    rois <- read.nifti.image(roi.file)
    hdr  <- read.nifti.header(roi.file)
    mask <- as.vector(rois!=0)
    rois <- rois[mask]  # this basically represents the voxelwise level of the rois
    nvoxs <- sum(mask)

    ## get unique rois and related indices
    cat("...determine unique rois and indices\n")
    urois <- sort(unique(rois))
    urois <- urois[urois!=0]
    nrois <- length(urois)
    rois.inds <- lapply(urois, function(ur) which(rois==ur))

    # Now loop through
    cat("...calculating similarity\n")
    sim.voxroi <- laply(1:nvoxs, function(i) {
        cor(lower_vox.dists[,i], lower_roi.dists[,rois[i]])
    }, .progress="text")

    return(sim.voxroi)
})
