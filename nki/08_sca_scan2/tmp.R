#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(niftir))
library(plyr)
library(ggplot2)

#' # Input Details
#' All the inputs are within `/home/data/Projects/CWAS/nki/sca`.
#' => ${scan}_${strategy}_sink directories
#' => roi_n%02i directories
#' => merged, rendered, stats
#' in stats => threshold => thresh_zstat?.nii.gz (we are interested in 1 and 2)


base     <- "/home/data/Projects/CWAS/nki/sca"
scans    <- c("short", "medium", "long")
strategy <- "compcor"
rois     <- (1:100)

#sinkdirs <- file.path(base, sprintf("%s_%s_sink", scans, strategy))
#zfiles   <- file.path(sinkdirs[1], sprintf("roi_n%02i", rois), "stats/threshold/thresh_zstat1.nii.gz")
#tmp <- file.exists(zfiles)
#zfiles[!tmp]
#zfiles   <- file.path(sinkdirs[2], sprintf("roi_n%02i", rois), "stats/threshold/thresh_zstat1.nii.gz")
#tmp <- file.exists(zfiles)
#zfiles[!tmp]
#zfiles   <- file.path(sinkdirs[3], sprintf("roi_n%02i", rois), "stats/threshold/thresh_zstat1.nii.gz")
#tmp <- file.exists(zfiles)
#zfiles[!tmp]


maskfile <- "/home/data/Projects/CWAS/nki/rois/mask_gray_2mm.nii.gz"
mask     <- read.mask(maskfile)
nvoxs    <- sum(mask)

df2   <- read.csv("tmp.csv")[,-c(1:2)]
roi_types <- c("maxima", "significant", "not-significant", "minima")
#scans     <- c("short", "medium", "long")
df2$label  <- factor(df2$label, levels=roi_types)
#df$scan   <- factor(df$scan, levels=scans) 

mdf2 <- ddply(df2, .(label), colwise(mean))

ggplot(data=mdf, aes(x=label, y=ps1, group=label, fill=label)) + 
  geom_bar(postition="dodge", stat="identity") + 
  ggtitle("Scan 1") + 
  xlab("ROI Types") + 
  ylab("MDMR -log10p")
ggsave(file.path(base, "figures/fig_06/tmp_scan1.png"), width=5, height=3)

ggplot(data=mdf, aes(x=label, y=ps2, group=label, fill=label)) + 
  geom_bar(postition="dodge", stat="identity") + 
  ggtitle("Scan 2") + 
  xlab("ROI Types") + 
  ylab("MDMR -log10p")
ggsave(file.path(base, "figures/fig_06/tmp_scan2.png"), width=5, height=3)

ggplot(data=df, aes(x=label, y=ps2, group=label, color=label)) + 
  geom_point(position="dodge") + 
  xlab("ROI Types") + 
  ylab("MDMR -log10p")

