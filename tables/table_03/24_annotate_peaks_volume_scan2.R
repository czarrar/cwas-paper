#!/usr/bin/env Rscript

# FOR NOW THIS IS WITH SCAN 1 DATA

suppressPackageStartupMessages(library(niftir))
library(plyr)

# Functions
read_peaks <- function(fname, ...) {
    peaks <- read.table(fname, skip=10)
    colnames(peaks) <- c("Index", "Intensity", "x", "y", "z", "Count", "Dist")
    peaks$x <- peaks$x * -1    # invert to make compatible with MNI space
    peaks$y <- peaks$y * -1
    return(peaks)
}

xyz2ijk <- function(xyz, qto_ijk)  {
    xyzt <- cbind(xyz, rep(1, nrow(xyz)))
    ijkt <- qto_ijk %*% t(xyzt) + 1
    ijk  <- t(ijkt[1:3,])
    return(ijk)
}

ijk2ind <- function(ijk, dimen) {
    ijk <- ijk - 1
    ind <- ijk[,3]*prod(dimen[2:3]) + ijk[,2]*dimen[3] + ijk[,1] + 1
    return(ind)
}

read_rois <- function(name, region_dir) {
    file    <- file.path(region_dir, sprintf("%s.nii.gz", name))
    img     <- read.nifti.image(file)
    info    <- read.table(file.path(region_dir, sprintf("names_%s.txt", name)), header=T)
    names   <- as.character(info$name)
    vals    <- as.numeric(info$roi)
    list(img=img, names=names, vals=vals)
}

roi_to_factor <- function(rlist, inds) {
    vals <- rlist$img[inds]
    vec  <- factor(vals, levels=c(0, rlist$vals), labels=c("NOTHING", rlist$names))
    return(vec)
}


## SETUP


###
# MDMR DATA
###

cat("MDMR Data\n")

scan        <- "medium"

easy_dir    <- "/home2/data/Projects/CWAS/tables/table_03/data_scan2"

# Let's read in the peaks here
# (I'm assuming their calculation is done elsewhere)
peak_file   <- file.path(easy_dir, "maxima_sm6.txt")
peaks       <- read_peaks(peak_file)

# For reference, let's also load the original data
mdmr_file   <- file.path(easy_dir, "thresh_zstat_sm6.nii.gz")
mdmr        <- read.nifti.image(mdmr_file)

# Also let's load the cluster data
clust_file  <- file.path(easy_dir, "cluster_mask.nii.gz")
clust       <- read.nifti.image(clust_file)

# Get header information
hdr_4mm     <- read.nifti.header(mdmr_file)
dimen_4mm   <- hdr_4mm$dim
qto_ijk_4mm <- hdr_4mm$qto.ijk


###
# WHERE AM I DATA
###

cat("Where Am I?\n")

region_dir  <- "/home2/data/Projects/CWAS/whereami"

# Get header information
hdr_1mm     <- read.nifti.header(file.path(region_dir, "standard_1mm.nii.gz"))
dimen_1mm   <- hdr_1mm$dim
qto_ijk_1mm <- hdr_1mm$qto.ijk

# Get grey-matter
grey_matter <- read.nifti.image(file.path(region_dir, "grey_matter.nii.gz"))

# Read in different parcellations
whereami        <- list()
whereami$yeo    <- read_rois("networks", region_dir)
whereami$ba     <- read_rois("brodmann", region_dir)
whereami$subcort<- read_rois("subcortical", region_dir)
whereami$cereb  <- read_rois("cerebellum", region_dir)


###
# Map xyz coords to ijk and then to vector indices
###

cat("Map xyz coords to ijk and then to vector indices\n")

# First try to 4mm
xyz.mat     <- as.matrix(peaks[,3:5])
ijk.mat     <- xyz2ijk(xyz.mat, qto_ijk_4mm)
inds        <- ijk2ind(ijk.mat, dimen_4mm)

# Get cluster membership
clust_mems  <- clust[inds]

# Check that this works
if (!all.equal(round(mdmr[inds], 3), as.numeric(peaks$Intensity)))
    stop("Mapping xyz coordinates to vector indices not working.")

# Now go to 1mm
ijk.mat     <- xyz2ijk(xyz.mat, qto_ijk_1mm)
inds        <- ijk2ind(ijk.mat, dimen_1mm)

# TODO: Should have some sanity check here...

# Create a new dataframe
df <- data.frame(
    Index = peaks$Index, 
    Cluster = clust_mems, 
    Stat = peaks$Intensity, 
    x = peaks$x, 
    y = peaks$y, 
    z = peaks$z
)


###
# Define peaks based on Yeo network assignment
###

cat("Define peaks based on parcellations\n")

# Hemisphere
df$Hemi         <- factor(xyz.mat[,1] > 0, labels=c("Left", "Right"))

# Grey Matter
df$Cortical     <- grey_matter[inds]

# Add on different parcellations
df$YeoNetwork   <- roi_to_factor(whereami$yeo, inds)
df$BA           <- roi_to_factor(whereami$ba, inds)
df$Subcortical  <- roi_to_factor(whereami$subcort, inds)
df$Cerebellum   <- roi_to_factor(whereami$cereb, inds)


###
# Save
###

cat("Save\n")

odir <- "/home2/data/Projects/CWAS/tables/table_03"
write.csv(df, file=file.path(odir, "16_peaks_part1_scan2.csv"))
write.table(table(clust[clust!=0]), file=file.path(odir, "17_clusts_scan2.txt"))
