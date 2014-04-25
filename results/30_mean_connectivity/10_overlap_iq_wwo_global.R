#!/usr/bin/env Rscript

#' # Goal
#' Get the overlap (and similarity) of IQ CWAS with or without mean connectivity
#' Add with global

#' # Methods
#' - Read in the files
#' - Code for overlap
#' - Compute
#' - Save


suppressPackageStartupMessages(library(niftir))


#' # Paths

base    <- "/home2/data/Projects/CWAS"
scans   <- c("short", "medium")

odir    <- file.path(base, "results/30_mean_connectivity")

sdirs0  <- file.path(base, "nki/cwas", scans, "compcor_kvoxs_fwhm08_to_kvoxs_fwhm08")
sdirs1  <- file.path(base, "nki/cwas", scans, "compcor_kvoxs_fwhm08_global_to_kvoxs_fwhm08_global")

mdirs.vanilla   <- file.path(sdirs0, "iq_age+sex+meanFD.mdmr")
mdirs.mean      <- file.path(sdirs0, "iq_age+sex+meanFD+meanGcor.mdmr")
mdirs.gsr       <- file.path(sdirs1, "iq_age+sex+meanFD.mdmr")

cname           <- "cluster_correct_v05_c05/easythresh/thresh_zstat_FSIQ.nii.gz"
mfiles.vanilla  <- file.path(mdirs.vanilla, cname)
mfiles.mean     <- file.path(mdirs.mean, cname)
mfiles.gsr      <- file.path(mdirs.gsr, cname)

cname           <- "cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz"
ufiles.vanilla  <- file.path(mdirs.vanilla, cname)
ufiles.mean     <- file.path(mdirs.mean, cname)
ufiles.gsr      <- file.path(mdirs.gsr, cname)

maskfile        <- file.path(base, "nki/rois/mask_gray_4mm.nii.gz")


#' # Read in files

mask <- read.mask(maskfile)

mdmrs.vanilla   <- sapply(mfiles.vanilla, function(f) read.nifti.image(f)[mask])
mdmrs.mean      <- sapply(mfiles.mean, function(f) read.nifti.image(f)[mask])
mdmrs.gsr       <- sapply(mfiles.gsr, function(f) read.nifti.image(f)[mask])
mdmr.scan1.thr  <- cbind(vanilla=mdmrs.vanilla[,1], mean=mdmrs.mean[,1], gsr=mdmrs.gsr[,1])
mdmr.scan2.thr  <- cbind(vanilla=mdmrs.vanilla[,2], mean=mdmrs.mean[,2], gsr=mdmrs.gsr[,2])

mdmrs.vanilla   <- sapply(ufiles.vanilla, function(f) read.nifti.image(f)[mask])
mdmrs.mean      <- sapply(ufiles.mean, function(f) read.nifti.image(f)[mask])
mdmrs.gsr       <- sapply(ufiles.gsr, function(f) read.nifti.image(f)[mask])
mdmr.scan1.uthr <- cbind(vanilla=mdmrs.vanilla[,1], mean=mdmrs.mean[,1], gsr=mdmrs.gsr[,1])
mdmr.scan2.uthr <- cbind(vanilla=mdmrs.vanilla[,2], mean=mdmrs.mean[,2], gsr=mdmrs.gsr[,2])


#' # Code for overlap

dice <- function(a,b) (2*sum(a>0 & b>0))/(sum(a>0) + sum(b>0))
dice.mat <- function(mat) {
    nc <- ncol(mat)
    res <- matrix(0, nc, nc)
    for (i in 1:nc) {
        for (j in 1:nc) {
            if (i == j) {
                res[i,j] <- 1
            } else {
                res[i,j] <- dice(mat[,i], mat[,j])
            }
        }
    }
    return(res)
}

#' # Compute

scan1.res <- list()
scan2.res <- list()
scanb.res <- list()

#' Scan 1: IQ CWAS & Effect of Mean Connectivity
scan1.res$cor   <- cor(mdmr.scan1.uthr, method="s")
scan1.res$dice  <- dice.mat(mdmr.scan1.thr)
scan1.res$voxs  <- table(as.data.frame((mdmr.scan1.thr>0)*1))
scan1.res$perc  <- colMeans(mdmr.scan1.thr>0)*100

#' Scan 2: IQ CWAS & Effect of Mean Connectivity
scan2.res$cor   <- cor(mdmr.scan2.uthr, method="s")
scan2.res$dice  <- dice.mat(mdmr.scan2.thr)
scan2.res$voxs  <- table(as.data.frame((mdmr.scan2.thr>0)*1))
scan2.res$perc  <- colMeans(mdmr.scan2.thr>0)*100

#' Between Scans
scanb.res$cor   <- sapply(1:3, function(i) cor(mdmr.scan1.uthr[,i], mdmr.scan2.uthr[,i]))
scanb.res$dice  <- sapply(1:3, function(i) dice(mdmr.scan1.thr[,i], mdmr.scan2.thr[,i]))

#' Save
sink(file.path(odir, "11_comparison_scan1.txt"))
print(scan1.res)
sink()
sink(file.path(odir, "12_comparison_scan2.txt"))
print(scan2.res)
sink()
sink(file.path(odir, "13_comparison_scanb.txt"))
print(scanb.res)
sink()
