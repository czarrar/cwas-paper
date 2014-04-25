#!/usr/bin/env Rscript

#' Scatter plot of scan effects vs iq effects
#' * Read in iq effects for each scan
#' * Read in scan effects
#' * Create a scatter plot
#' * Calculate difference between scan iq effects
#' * Create scatter plot of scan effects vs scatter plot

#+ setup
library(ggplot2)
library(niftir)
basedir <- "/home2/data/Projects/CWAS/nki/cwas"
sname   <- "compcor_kvoxs_smoothed_to_kvoxs_smoothed"
miq     <- "iq_age+sex+meanFD.mdmr"
mscan   <- "scan_subject+meanFD.mdmr"
scan1.iq.f     <- file.path(basedir, "short", sname, miq, "zstats_FSIQ.nii.gz")
scan2.iq.f     <- file.path(basedir, "medium", sname, miq, "zstats_FSIQ.nii.gz")
scan.effects.f <- file.path(basedir, "_scan_effects", sname, mscan, "zstats_scan.nii.gz")
mask           <- file.path(basedir, "short", sname, "mask.nii.gz")

#+ read
mask <- read.mask(mask)
scan.effects <- read.nifti.image(scan.effects.f)[mask]
scan1.iq <- read.nifti.image(scan1.iq.f)[mask]
scan2.iq <- read.nifti.image(scan2.iq.f)[mask]
diff.iq  <- scan1.iq-scan2.iq

#+ combine
df <- data.frame(
    scan = rep(c("scan 1", "scan 2", "scan 1 - scan 2"), each=sum(mask)), 
    effects = rep(scan.effects, 3), 
    iq = c(scan1.iq, scan2.iq, diff.iq)
)

#+ main-scatter-plots
odir <- file.path("/home2/data/Projects/CWAS", "figures", "sfig_scan_effects")
dir.create(odir, F)
ggplot(df, aes(x=effects, y=iq)) + 
    geom_point(shape=1) +
    geom_smooth() + 
    facet_grid(scan ~ .) +
    xlab("Scan Effects (Z-Score)") + 
    ylab("IQ Effects (Z-Score)") + 
    theme(axis.text = element_text(size=16))
ggsave(file.path(odir, "B_scatter_plots.png"), width=5, height=5)
