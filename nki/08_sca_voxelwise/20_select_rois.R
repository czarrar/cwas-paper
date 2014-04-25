#!/usr/bin/env Rscript

#' Several steps to get the range of ROIs to assess if MDMR can guide the 
#' selection of ROIs for SCA
#' 1. Find the extrema or maximas
#' 2. Find the minimas
#' 3. Find random non-extrema and significant regions
#' 4. Find randon non-minima and non-significant regions


#cat("think before running this script again. you've been jammed.\n")
#quit("no", status=1)


suppressPackageStartupMessages(library(niftir))

# Functions
read_peaks <- function(fname, ...) {
    peaks <- read.table(fname, skip=10)
    colnames(peaks) <- c("Index", "Intensity", "x", "y", "z", "Count", "Dist")
    peaks$x <- peaks$x * -1    # invert to make compatible with MNI space
    peaks$y <- peaks$y * -1
    return(peaks)
}

calc_min_dists <- function(compare.coords) {
    min.dists <- sapply(1:nrow(compare.coords), function(i) {
        dists <- sqrt(rowSums((sweep(compare.coords[-i,], 2, compare.coords[i,]))^2))
        min(dists)
    })
    return(min.dists)
}

find_intensities <- function(raw, filtered) {
    row_ids <- apply(filtered, 1, function(filt) {
        row_id <- which(raw$x == filt[1] & raw$y == filt[2] & raw$z == filt[3])
        return(row_id)
    })
    intensities <- raw$Intensity[row_ids]
    return(intensities)
}

# Settings
scan <- "short"
di   <- 20  # distance in mm btw ROIs within each group
bi   <- 10  # distance in mm btw ROIs between groups
n    <- 25  # num of rois per group

# Directories
base  <- "/home2/data/Projects/CWAS"
indir <- file.path(base, "nki/sca_voxelwise_scan1/10_mdmr_data")
odir  <- file.path(base, "nki/sca_voxelwise_scan1/20_rois")
dir.create(odir)

# Files
mask.file   <- file.path(indir, "mask.nii.gz")
hdr         <- read.nifti.header(mask.file)
mask        <- read.mask(mask.file)
cmat        <- coords(hdr$dim)
cstat.file  <- file.path(indir, "thresh_zstat_sm6.nii.gz")
stat.file   <- file.path(indir, "zstat_sm6.nii.gz")


###
# MAXIMAS & MINIMAS
###

# Read in the maximas 
maxima        <- read_peaks(file.path(indir, "maxima_sm6.txt"))
maxima.coords <- as.matrix(maxima[,3:5])

# Read in minimas
minima        <- read_peaks(file.path(indir, "minima_sm6.txt"))
minima.coords <- as.matrix(minima[,3:5])

# Filter

#' Check distances between maxima and minima
compare.coords <- rbind(maxima.coords, minima.coords)
compare.dists  <- sapply(1:nrow(maxima.coords), function(i) {
    dists <- sqrt(rowSums((sweep(compare.coords[-i,], 2, compare.coords[i,]))^2))
    min(dists)
})

#' Filter out any maxima that are too close (<10mm) to a minima
rm_maxima_inds  <- compare.dists>bi
maxima.coords   <- maxima.coords[rm_maxima_inds,]

#' Select the top 25 in each group
minima.coords <- minima.coords[1:n,]
maxima.coords <- maxima.coords[1:n,]

#' then compute distances (within)
maxima.dists  <- calc_min_dists(maxima.coords)
minima.dists  <- calc_min_dists(minima.coords)



#' ## Random Significant
stat     <- read.nifti.image(stat.file)         # raw significance map
sig.cmat <- cmat[stat>1.67,]                    # coordinates for sig voxs
nvoxs    <- sum(stat>1.67)                      # number of sig voxs

inds  <- sample(1:nvoxs, n)                     # initialize with random indices
for (i in 1:n) {
    cat("i:", i, "\n")
    
    iter <- 0
    while (iter < 20) {
        iter <- iter + 1
        
        # Transform ijk to xyz
        tmp.coords      <- as.matrix(sig.cmat[inds,]) - 1
        new.coords      <- (cbind(tmp.coords, rep(1,n)) %*% t(hdr$qto.xyz))[,1:3]
        
        # Euclidian distances amongst sample
        dists1 <- sqrt(rowSums((sweep(new.coords[-i,], 2, new.coords[i,]))^2))
        comp1  <- any(dists1 < di)
        
        # Euclidean distances between sample and maxima/minima
        compare.coords <- rbind(maxima.coords, minima.coords)
        dists2         <- sqrt(rowSums((sweep(compare.coords, 2, new.coords[i,]))^2))
        comp2          <- any(dists2 < (di/2))
        
        if (comp1 | comp2) {
            cat("...redo", round(min(dists1), 2), round(min(dists2), 2), "\n")
            inds[i] <- sample(1:nvoxs, 1)
        } else {
            break
        }
    }    
}
tmp.coords <- as.matrix(sig.cmat[inds,]) - 1
sig.coords <- (cbind(tmp.coords, rep(1,n)) %*% t(hdr$qto.xyz))[,1:3]

sig.dists  <- calc_min_dists(sig.coords)


#' ## Random Non-Significant
nonsig.cmat <- cmat[stat<1.67 & mask,]     # coordinates for non-sig voxs
nvoxs       <- sum(stat<1.67 & mask)       # number of non-sig voxs

inds  <- sample(1:nvoxs, n)                     # initialize with random indices
for (i in 1:n) {
    cat("i:", i, "\n")
    
    iter <- 0
    while (iter < 20) {
        iter <- iter + 1
        
        # Transform ijk to xyz
        tmp.coords      <- as.matrix(nonsig.cmat[inds,]) - 1
        new.coords      <- (cbind(tmp.coords, rep(1,n)) %*% t(hdr$qto.xyz))[,1:3]
        
        # Euclidian distances amongst sample
        dists1 <- sqrt(rowSums((sweep(new.coords[-i,], 2, new.coords[i,]))^2))
        comp1  <- any(dists1 < di)
        
        # Euclidean distances between sample and maxima/minima/others
        compare.coords <- rbind(maxima.coords, minima.coords, sig.coords)
        dists2         <- sqrt(rowSums((sweep(compare.coords, 2, new.coords[i,]))^2))
        comp2          <- any(dists2 < (di/2))
        
        if (comp1 || comp2) {
            cat("...redo", round(min(dists1), 2), round(min(dists2), 2), "\n")
            inds[i] <- sample(1:nvoxs, 1)
        } else {
            break
        }
    }    
}
tmp.coords    <- as.matrix(nonsig.cmat[inds,] - 1)
nonsig.coords <- (cbind(tmp.coords, rep(1,n)) %*% t(hdr$qto.xyz))[,1:3]

nonsig.dists  <- calc_min_dists(nonsig.coords)




#' ## Measure each region's minimum distance with the other ROIs
all.coords <- rbind(maxima.coords, sig.coords, nonsig.coords, minima.coords)
min.dists       <- sapply(1:nrow(all.coords), function(i) {
    dists <- sqrt(rowSums((sweep(all.coords[-i,], 2, all.coords[i,]))^2))
    min(dists)
})
which.min.dists <- sapply(1:nrow(all.coords), function(i) {
    dists <- sqrt(rowSums((sweep(all.coords[-i,], 2, all.coords[i,]))^2))
    which.min(dists)
})


#' ## Combine everything in one massive load
all.coords  <- rbind(maxima.coords, sig.coords, nonsig.coords, minima.coords)
my.coords   <- data.frame(
    label      = rep(c("maxima", "significant", "not-significant", "minima"), each=n), 
    val        = unlist(lapply(1:4, function(i) seq(100*i, by=2, length.out=n))), 
    all.coords, 
    stat       = c(find_intensities(maxima, maxima.coords), 
                   stat[as.numeric(row.names(sig.coords))], 
                   stat[as.numeric(row.names(nonsig.coords))], 
                   find_intensities(minima, minima.coords)), 
    local.dist = c(maxima.dists, sig.dists, nonsig.dists, minima.dists), 
    all.dist   = min.dists, 
    row.names  = 1:(n*4)
)
my.simple.coords <- my.coords[,3:5]
my.cpac.coords   <- cbind(my.coords[,2:5], radius=rep(4, nrow(my.coords)), 
                          resolution=rep("2mm", nrow(my.coords)))

#' ## Save
write.csv(my.coords, file=file.path(odir, "rois_all_info.csv"))
write.table(my.simple.coords, row.names=F, col.names=F, quote=F, file=file.path(odir, "rois_all_coords.txt"))
write.table(my.cpac.coords, row.names=F, col.names=F, quote=F, file=file.path(odir, "rois_all_cpac.txt"))
