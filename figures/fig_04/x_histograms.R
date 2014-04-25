#!/usr/bin/env Rscript

#' # Goal
#' Overlay the distribution of associations between IQ with vs without mean connectivity

#' # Methods
#' - Read in the files
#' - Code for overlap
#' - Compute
#' - Save


suppressPackageStartupMessages(library(niftir))
library(ggplot2)


#' # Paths

base    <- "/home2/data/Projects/CWAS"
scans   <- c("short", "medium")

odir    <- file.path(base, "figures/fig_04")

sdirs   <- file.path(base, "nki/cwas", scans, "compcor_kvoxs_fwhm08_to_kvoxs_fwhm08")

mdirs.nomean    <- file.path(sdirs, "iq_age+sex+meanFD.mdmr")
mdirs.yesmean   <- file.path(sdirs, "iq_age+sex+meanFD+meanGcor.mdmr")

cname           <- "cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz"
ufiles.nomean   <- file.path(mdirs.nomean, cname)
ufiles.yesmean  <- file.path(mdirs.yesmean, cname)

maskfile        <- file.path(base, "nki/rois/mask_gray_4mm.nii.gz")


#' # Read in files

mask <- read.mask(maskfile)
nvoxs <- sum(mask)

mdmrs.no   <- -log10(pt(sapply(ufiles.nomean, function(f) read.nifti.image(f)[mask]), Inf, lower.tail=F))
mdmrs.yes  <- -log10(pt(sapply(ufiles.yesmean, function(f) read.nifti.image(f)[mask]), Inf, lower.tail=F))


#' # Compile
mdmr.scan1 <- data.frame(
    mean.correct = rep(c("no", "yes"), each=nvoxs), 
    mdmr         = c(mdmrs.no[,1], mdmrs.yes[,1])
)
mdmr.scan2 <- data.frame(
    mean.correct = rep(c("no", "yes"), each=nvoxs), 
    mdmr         = c(mdmrs.no[,2], mdmrs.yes[,2])
)
mdmr.diff <- data.frame(
    scan = rep(scans, each=nvoxs), 
    mdmr         = c(mdmrs.no[,1] - mdmrs.yes[,1], mdmrs.no[,2] - mdmrs.yes[,2])
)

#' # Code for overlap

ggplot(mdmr.scan1, aes(x=mdmr, fill=mean.correct)) + 
    geom_density(alpha=0.5)
ggsave(file.path(odir, "x_histogram_scan1.png"))

ggplot(mdmr.scan2, aes(x=mdmr, fill=mean.correct)) + 
    geom_density(alpha=0.5)
ggsave(file.path(odir, "x_histogram_scan2.png"))

ggplot(mdmr.diff, aes(x=mdmr, fill=scan)) + 
    geom_density(alpha=0.5)
ggsave(file.path(odir, "x_histogram_diff.png"))
