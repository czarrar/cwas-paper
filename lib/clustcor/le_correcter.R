#!/usr/bin/env Rscript

# This script will
# - take the subject distance and mdmr directory as input
# - if needed, convert roi data to voxelwise
#
# - create the unthresh logp maps (15k perms)
# - create the unthres fdr-corrected logp maps
# - run cluster correction
#   - determine fstat threshold (5k perms)
#   - determine cluster thresholds (5k perms)
#   - create the clusterized results

cat("Loading necessary libraries and functions\n")
source("inline_connectir.R")    # loads connectir

# Take the subject distance and mdmr directories as input
# the roi file is optional

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
    stop("usage: correct.R distance-dir mdmr-dir [roi-file]")
}

dist.dir <- args[1]
mdmr.dir <- args[2]
roi.file <- args[3] # optional

roify <- !is.na(roi.file)

## fixed but extra options
### overwrite output if it exists?
overwrite <- FALSE
### voxel and cluster thresholds
vox.thresh <- 0.05
clust.thresh <- 0.05
### # of perms for cluster parts
### should include non-permuted data
nperms4clust <- 5000

# Output Directory
vstr <- sub("0.", "", as.character(vox.thresh))
cstr <- sub("0.", "", as.character(clust.thresh))
outdir <- file.path(mdmr.dir, sprintf("cluster_correct_v%s_c%s", vstr, cstr))

if (file.exists(outdir)) {
    vstop("output directory '%s' already exists", outdir)
} else {
    dir.create(outdir)
}


# Checks
vcat(T, "\nChecks")

## check if ROI file is needed
vcat(T, "...are rois needed")
if (is.na(roi.file) && file.exists(file.path(dist.dir, "mask.txt"))) {
    stop("ROI file needed but not given")
}


# Setup
vcat(T, "\nSetup")

## vector of permuted factor names
vcat(T, "...factor names")
load(file.path(mdmr.dir, "modelinfo.rda"))
factors <- names(attr(modelinfo$qrhs, "factors2perm"))
nfactors <- length(factors)

## p-value matrix from all permutations
vcat(T, "...p-values from all permutations")
f <- file.path(mdmr.dir, "pvals.desc")
pvals.mat <- attach.big.matrix(f)

## list of permuted matrices
vcat(T, "...load permutations")
files <- file.path(mdmr.dir, sprintf("fperms_%s.desc", factors))
list.fperms <- lapply(files, function(f) attach.big.matrix(f))

## determine number of permutations
vcat(T, "...determine number of permutations for clustering")
nperms <- nrow(list.fperms[[1]])
if (nperms < nperms4clust) {
    vcat(T, "...changing nperms4cluster to %i", nperms)
    nperms4clust <- nperms
} else {
    vcat(T, "...will use %ik permutations for clustering", nperms4clust)
}

## subset of permuted matrices for clustering
vcat(T, "...take subset of permutations for clustering")
tmp <- lapply(list.fperms, function(fperms) {
    deepcopy(fperms, rows=1:nperms4clust, shared=FALSE)
})
rm(list.fperms); invisible(gc(F,T))
list.fperms <- tmp

## new p-values for subset
vcat(T, "...calculate p-values for new subset of permutations")
pvals4clust.mat <- mdmr.fstats_to_pvals(list.fperms)


# ROI stuff
if (roify) {
    vcat(T, "ROI Setup")
    
    ## read in rois and create mask
    vcat(T, "...read in ROIs and create mask")
    rois <- read.nifti.image(roi.file)
    hdr  <- read.nifti.header(roi.file)
    mask <- as.vector(rois!=0)
    rois <- rois[mask]
    nvoxs <- sum(mask)

    ## get unique rois and related indices
    vcat(T, "...determine unique rois and indices")
    urois <- sort(unique(rois))
    urois <- urois[urois!=0]
    nrois <- length(urois)
    rois.inds <- lapply(urois, function(ur) which(rois==ur))

    ## simple method for rois => voxelwise 
    simple.rois2voxelwise <- function(roi.data, vox.rois) {
        vox.data <- vector("numeric", length(vox.rois))
    
        urois <- sort(unique(vox.rois))
        urois <- urois[urois!=0]
        nrois <- length(urois)
    
        for (ri in 1:nrois)
            vox.data[vox.rois==urois[ri]] <- roi.data[ri]
    
        return(vox.data)
    }
} else {
    vcat(T, "...read mask")
    
    maskfile <- file.path(dist.dir, "mask.nii.gz")
    hdr <- read.nifti.header(maskfile)
    mask <- read.mask(maskfile)
    
    rois.inds <- NULL
}

fstat_from_pval <- function(fstats, pvals, pthr) {
    df <- data.frame(fstats=fvals, logps=-log10(pvals))
    model <- lm(fstats ~ logps, data=df)
    fthr <- predict(model, data.frame(logps=-log10(pthr)))
    return(fthr)
}

permute_max_sizes <- function(fperms, fthr, hdr, mask, rois.inds=NULL) {
    roify <- !is.null(rois.inds)
    nperms <- nrow(fperms)
    nvoxs <- sum(mask)
    
    max.sizes <- laply(1:nperms, function(i) {
        if (roify) {
            img <- rois_to_voxelwise(fperms, as.double(i), rois.inds, as.double(nvoxs))
        } else {
            img <- get_row(fperms, as.double(i))
        }
        ct <- cpp.cluster.table(img, fthr, hdr$dim, mask)
        ct$max.size
    }, .progress="text")
    
    return(max.sizes)
}


# The Meat
for (fi in 1:nfactors) {
    factor <- factors[fi]
    vcat(T, "\nFactor: %s", factor)
    
    
    ## Create unthresholded logp maps
    vcat(T, "...unthresholded logp and fdr logp maps")
    
    pvals       <- -log10(pvals.mat[,fi])
    fdr.pvals   <- -log10(p.adjust(pvals.mat[,fi], "fdr"))
    
    if (roify) {
        pvals     <- simple.rois2voxelwise(pvals, rois)
        fdr.pvals <- simple.rois2voxelwise(fdr.pvals, rois)
    }
        
    outfile <- file.path(outdir, sprintf("logp_%s.nii.gz", factor))
    write.nifti(pvals, hdr, mask, outfile=outfile, overwrite=overwrite)
    
    outfile <- file.path(outdir, sprintf("fdr_logp_%s.nii.gz", factor))
    write.nifti(fdr.pvals, hdr, mask, outfile=outfile, overwrite=overwrite)
    
    
    ## Comparison Easy Thresh Clustering
    vcat(T, "...comparison with easythresh")
    
    easy.dir <- file.path(outdir, "easythresh")
    dir.create(easy.dir, FALSE)
    
    # Convert p-value to zstats
    vcat(T, "...pvals to zstats")
    
    zstats <- qt(pvals.mat[,fi], Inf, lower.tail=F)
    if (roify) zstats <- simple.rois2voxelwise(zstats, rois)
    
    outfile0 <- file.path(easy.dir, sprintf("zstat_%s_tmp.nii.gz", factor))
    write.nifti(zstats, hdr, mask, outfile=outfile0, overwrite=overwrite)
    
    # Fix to remove any infinite values
    curdir <- getwd()
    setwd(easy.dir)
    outfile <- file.path(easy.dir, sprintf("zstat_%s.nii.gz", factor))
    cmd <- sprintf("3dcalc -a %s -expr a -prefix %s", outfile0, outfile)
    vcat(T, cmd)
    system(cmd)
    file.remove(outfile0)
    setwd(curdir)
    
    # Brain mask
    if (roify) {
        # Save mask file
        vcat(T, "...saving mask file")
        maskfile <- file.path(outdir, "mask.nii.gz")
        write.nifti(mask, hdr, outfile=maskfile, overwrite=overwrite)
    } else {
        maskfile <- file.path(dist.dir, "mask.nii.gz")
    }
    
    # Background (underlay) image
    bgfile <- file.path(dist.dir, "bg_image.nii.gz")
    
    # Run it
    curdir <- getwd()
    setwd(easy.dir)
    zstatfile <- outfile
    zthr <- qt(vox.thresh, Inf, lower.tail=F)
    cmd <- sprintf("easythresh %s %s %.4f %.4f %s zstat_%s --mm", 
                    zstatfile, maskfile, zthr, clust.thresh, bgfile, factor)
    vcat(T, cmd)
    system(cmd)
    setwd(curdir)
    
        
    # Cluster correct
    vcat(T, "...Cluster Correcting")
    
    fperms <- list.fperms[[fi]]
    
    # Determine pseudo-F given a particular p-value
    # this would be the voxel threshold before clustering
    vcat(T, "...determine pseudo-F threshold with a p=%.4f", vox.thresh)
    
    fvals <- fperms[1,]
    pvals <- pvals4clust.mat[,fi]
    fthr <- fstat_from_pval(fstats, pvals, vox.thresh)
    
    
    # Determine clusters from non-permuted data
    vcat(T, "...clusters in non-permuted data")
    
    if (roify) {
        img <- simple.rois2voxelwise(fvals, rois)
    } else {
        img <- fvals
    }
    orig.ct <- cluster.table(img, fthr, hdr$dim, mask)
    
    # Maximum cluster sizes across permutations
    vcat(T, "...max clust sizes across permutations")
    
    max.sizes <- permute_max_sizes(fperms, fthr, hdr, mask, rois.inds)
    
    # Cluster significance
    vcat(T, "...determine significant clusters")
    
    clust.sig <- sapply(orig.ct$size, function(ocs) {
        sapply(ocs, function(s) sum(s<max.sizes)/nperms4clust)
    })
    
    clust <- orig.ct$clust[mask]
    w.clusts <- which(rev(clust.sig<clust.thresh))
    clust.keep <- clust*0    # empty vector
    for (i in 1:length(w.clusts)) clust.keep[clust==w.clusts[i]] <- 1
    
    logps <- -log10(pvals.mat[,fi])
    if (roify) logps <- simple.rois2voxelwise(logps, rois)
    clust.logps <- logps * clust.keep
    
    # Save
    vcat(T, "...saving")
    
    outfile <- file.path(outdir, sprintf("clust_%s.nii.gz", factor))
    write.nifti(clust.keep, hdr, mask, outfile=outfile, overwrite=overwrite)
    
    outfile <- file.path(outdir, sprintf("clust_logp_%s.nii.gz", factor))
    write.nifti(clust.logps, hdr, mask, outfile=outfile, overwrite=overwrite)    
    
    outfile <- file.path(outdir, sprintf("clustinfo_%s.rda", factor))
    save(orig.ct, max.sizes, clust.sig, fthr, fvals, pvals, img, logps, clust.keep, 
         file=outfile)
}

