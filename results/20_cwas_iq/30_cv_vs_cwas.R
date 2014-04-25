#!/usr/bin/env Rscript

# This script will compare the similarity between the 2 scans related to IQ

suppressPackageStartupMessages(library(niftir))

###
# CV: Paths
###

cat("Paths\n")

basedir     <- "/home2/data/Projects/CWAS/nki/stability"
strategy    <- "N104_compcor"
kstr        <- "kvoxs_fwhm08_to_kvoxs_fwhm08"
measures    <- c("cv_short", "cv_medium", "consistency")
mask_file   <- "/home2/data/Projects/CWAS/nki/rois/mask_gray_4mm.nii.gz"

# Input Directory
indir       <- file.path(basedir, sprintf("%s_%s", strategy, kstr))

# Input Measure Files
infiles1    <- file.path(indir, sprintf("%s.nii.gz", measures))
infiles2    <- file.path(indir, sprintf("%s_zscore.nii.gz", measures))

# Output directory
outdir      <- "/home2/data/Projects/CWAS/results/10_summarize_distances"


###
# CV: Read
###

cat("Load niftis\n")

# Mask
mask <- read.mask(mask_file)

# Voxelwise Images
imgs1 <- sapply(infiles1, function(f) read.nifti.image(f)[mask])
imgs2 <- sapply(infiles2, function(f) read.nifti.image(f)[mask])

# Only use the second set of images
cv.scan1 <- imgs2[,1]
cv.scan2 <- imgs2[,2]
consist  <- imgs2[,3]


###
# CWAS: Setup

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
# CWAS: Read

roidir  <- file.path(base, "nki/rois")
mask    <- read.mask(file.path(roidir, "mask_gray_4mm.nii.gz"))
zstats  <- sapply(zstatfiles, function(f) read.nifti.image(f)[mask])
threshs <- sapply(threshfiles, function(f) read.nifti.image(f)[mask])
sig     <- (threshs[,1]>0) | (threshs[,2]>0)

colnames(zstats) <- scans
colnames(threshs)<- scans

df1 <- data.frame(zstats)
df2 <- data.frame(threshs)

# only keep zstats
cwas.scan1 <- df1[,1]
cwas.scan2 <- df1[,2]
scan_diffs <- abs(cwas.scan1 - cwas.scan2)

###


###
# Measure

spearman.scan1 <- cor(cv.scan1, cwas.scan1, method="s")
spearman.scan2 <- cor(cv.scan2, cwas.scan2, method="s")
spearman.diff  <- cor(consist, scan_diffs, method="s")

df <- data.frame(
    measures = c("scan1", "scan2", "diff"), 
    values = c(spearman.scan1, spearman.scan2, spearman.diff)
)

###


###
# Report

print(df)
write.table(df, file=file.path(odir, "30_cv_vs_cwas.R"))

###



###
# Plot

library(ggplot2)

ggplot(data.frame(x=cv.scan1, y=cwas.scan1), aes(x=x, y=y)) + 
  geom_point(shape=1) + 
  geom_smooth(method=lm) + 
  xlab("CV (Z-Scores)") + 
  ylab("IQ CWAS (Z-Scores)") + 
  ggtitle("Scan 1")
ggsave(file.path(odir, "z_30b_cv_vs_cwas_scan1.png"))

ggplot(data.frame(x=cv.scan2, y=cwas.scan2), aes(x=x, y=y)) + 
  geom_point(shape=1) + 
  geom_smooth(method=lm) + 
  xlab("CV (Z-Scores)") + 
  ylab("IQ CWAS (Z-Scores)") + 
  ggtitle("Scan 2")
ggsave(file.path(odir, "z_30c_cv_vs_cwas_scan2.png"))

ggplot(data.frame(x=consist, y=scan_diffs), aes(x=x, y=y)) + 
  geom_point(shape=1) + 
  geom_smooth(method=lm) + 
  xlab("Reproducibility of Distances (Z-Scores)") + 
  ylab("Absolute Difference Between Scan IQ CWAS (Z-Scores)") + 
  ggtitle("Scan 1 vs Scan 2")
ggsave(file.path(odir, "z_30d_cv_vs_cwas_diff.png"))


###