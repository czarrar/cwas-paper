#!/usr/bin/env Rscript

# This script will compare the similarity between the 2 scans related to IQ

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
sig     <- (threshs[,1]>0) | (threshs[,2]>0)

colnames(zstats) <- scans
colnames(threshs)<- scans

df1 <- data.frame(zstats)
df2 <- data.frame(threshs)

###


###
# Measure

dice <- function(a,b) (2*sum(a&b))/(sum(a) + sum(b))

dice_coeff  <- dice(df2[,1]>0, df2[,2]>0)
pearson_r   <- cor(df1[,1], df1[,2], method="p")
spearman_r  <- cor(df1[,1], df1[,2], method="s")
kendalls_r  <- cor(df1[,1], df1[,2], method="k")

df <- data.frame(
    measures = c("dice", "pearson", "spearman", "kendalls"), 
    values = c(dice_coeff, pearson_r, spearman_r, kendalls_r)
)

###


###
# Report

print(df)
write.table(df, file=file.path(odir, "20_scan_comparisons.txt"))

###
