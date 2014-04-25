#!/usr/bin/env Rscript

# This script will compare the results between the 2 scans on a scatter plot

###
# Setup

library(niftir)

base        <- "/home2/data/Projects/CWAS"

scans       <- c("short", "medium")
strategy    <- "compcor"
kstr        <- "kvoxs_smoothed_to_kvoxs_smoothed"
mname       <- "iq_age+sex+meanFD.mdmr"
cname       <- "cluster_correct_v05_c05"
factor      <- "FSIQ"

datadirs    <- file.path(base, "nki/cwas", scans, sprintf("%s_%s", strategy, kstr), mname, cname)

logpfiles   <- file.path(datadirs, sprintf("logp_%s.nii.gz", factor))
if (!all(file.exists(logpfiles))) stop("input logp files don't exist")

zstatfiles  <- file.path(datadirs, "..", sprintf("zstats_%s.nii.gz", factor))
if (!all(file.exists(zstatfiles))) stop("input zstat files don't exist")

clustfiles  <- file.path(datadirs, sprintf("clust_%s.nii.gz", factor))
if (!all(file.exists(clustfiles))) stop("input clust files don't exist")

odir        <- file.path(base, "figures", "fig_03")

###


###
# Read

roidir  <- file.path(base, "nki/rois")
mask    <- read.mask(file.path(roidir, "mask_gray_4mm.nii.gz"))
logps   <- sapply(logpfiles, function(f) read.nifti.image(f)[mask])
zstats  <- sapply(zstatfiles, function(f) read.nifti.image(f)[mask])
clusts  <- sapply(clustfiles, function(f) read.nifti.image(f)[mask])
sig     <- (clusts[,1]>0) | (clusts[,2]>0)

print(cor(logps)[1,2])
dice <- function(a,b) (2*sum(a&b))/(sum(a) + sum(b))
print(dice(clusts[,1]>0, clusts[,2]>0))

colnames(logps)  <- scans
colnames(zstats) <- scans

df1 <- data.frame(logps)
df2 <- data.frame(zstats)

###


###
# Plot

library(ggplot2)

ggplot(df1[sig,], aes(x=short, y=medium)) + 
  geom_point(shape=1) + 
  geom_smooth(method=lm) + 
  xlab("Scan 1") + 
  ylab("Scan 2") + 
  ggtitle("Significant -log10p voxels")

ggsave(file.path(odir, "C_compare_scans_clust_logp.png"))


ggplot(df2[sig,], aes(x=short, y=medium)) + 
  geom_point(shape=1) + 
  geom_smooth(method=lm) + 
  xlab("Scan 1") + 
  ylab("Scan 2") + 
  ggtitle("Significant zstat voxels")

ggsave(file.path(odir, "C_compare_scans_clust_zstat.png"))


###


###
# Save




