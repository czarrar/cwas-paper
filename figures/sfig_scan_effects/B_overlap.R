#!/usr/bin/env Rscript

#' Scatter plot of scan effects vs iq effects
#' * Read in overlap brain image from iq effects
#' * Read in scan effects
#' * Divide into 1=neither scan, 2=scan one, 3=scan two, and 4=both scans
#' * Get mean significance in each of the two bins.

#+ setup
library(ggplot2)
library(niftir)
basedir <- "/home2/data/Projects/CWAS/nki/cwas"
sname   <- "compcor_kvoxs_smoothed_to_kvoxs_smoothed"
miq     <- "iq_age+sex+meanFD.mdmr"
mscan   <- "scan_subject+meanFD.mdmr"
scan.effects.f <- file.path(basedir, "_scan_effects", sname, mscan, "zstats_scan.nii.gz")
overlap.f      <- file.path("/home2/data/Projects/CWAS/figures/fig_03/C_overlap.nii.gz")
mask.f         <- file.path(basedir, "short", sname, "mask.nii.gz")

#+ read
mask <- read.mask(mask.f)
scan.effects <- read.nifti.image(scan.effects.f)[mask]
overlap <- read.nifti.image(overlap.f)[mask]

#+ label-overlap
labels <- overlap + 1
ulabels <- sort(unique(labels))

#+ mean-signif
mean.scan.effects <- sapply(ulabels, function(ul) {
    mean(scan.effects[labels==ul])
})
sd.scan.effects <- sapply(ulabels, function(ul) {
  sd(scan.effects[labels==ul])
})
df <- data.frame(
    signif = c("Neither Scan", "Scan 1", "Scan 2", "Both Scans"), 
    mean   = mean.scan.effects, 
    sd     = sd.scan.effects
)
df$signif <- factor(df$signif, labels=c("Neither Scan", "Scan 1", "Scan 2", "Both Scans"))

#+ barplots
odir <- file.path("/home2/data/Projects/CWAS", "figures", "sfig_scan_effects")
dir.create(odir, F)
ggplot(df, aes(x=signif, y=mean)) + 
    geom_bar(stat="identity") +
    theme(axis.text = element_text(size=16))
ggsave(file.path(odir, "C_overlap_bar_plots.png"), width=5, height=5)
