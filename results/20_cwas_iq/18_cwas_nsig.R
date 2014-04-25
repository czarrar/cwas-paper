#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(niftir))

###
# Setup

suppressPackageStartupMessages(library(niftir))

base        <- "/home2/data/Projects/CWAS"

scans       <- c("short", "medium")
strategy    <- "compcor"
kstr        <- "kvoxs_fwhm08_to_kvoxs_fwhm08"
mname       <- "iq_age+sex+meanFD.mdmr"
cname       <- "cluster_correct_v05_c05"
factor      <- "FSIQ"

datadirs    <- file.path(base, "nki/cwas", scans, sprintf("%s_%s", strategy, kstr), mname, cname)
easydirs    <- file.path(datadirs, "easythresh")

zstatfiles  <- file.path(easydirs, sprintf("zstat_%s.nii.gz", factor))
if (!all(file.exists(zstatfiles))) stop("input zstat files don't exist")

threshfiles  <- file.path(easydirs, sprintf("thresh_zstat_%s.nii.gz", factor))
if (!all(file.exists(threshfiles))) stop("input thresh zstat files don't exist")

odir        <- file.path(base, "results", "20_cwas_iq")


###


###
# Read

roidir  <- file.path(base, "nki/rois")
mask    <- read.mask(file.path(roidir, "mask_gray_4mm.nii.gz"))
zstats  <- sapply(zstatfiles, function(f) read.nifti.image(f)[mask])
threshs <- sapply(threshfiles, function(f) read.nifti.image(f)[mask])

colnames(zstats) <- scans
colnames(threshs)<- scans

###


###
# Measure

thr <- qt(0.05, Inf, lower.tail=F)
df <- data.frame(
    scan = scans, 
    uncorrected = colMeans(zstats>thr) * 100, 
    corrected = colMeans(threshs>thr) * 100
)

###


###
# Report

print(df)
write.table(df, file=file.path(odir, "18_cwas_nig.txt"))

###
