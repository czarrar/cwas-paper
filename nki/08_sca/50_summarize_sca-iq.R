#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(niftir))
library(plyr)

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

roi_df   <- read.csv("/home/data/Projects/CWAS/nki/sca/seeds/rois_all_info.csv")

#' # Summarize

#' This functions reads in the 2 IQ related results 
#' and gets the # of significant voxels

summarize_zstats <- function(roidir, mask) {
    zstatfiles  <- file.path(roidir, "stats/threshold", sprintf("thresh_zstat%i.nii.gz", 1:2))
    zstats      <- sapply(zstatfiles, function(f) read.nifti.image(f)[mask])
    colnames(zstats) <- c("pos", "neg")
    zsummary    <- colSums(zstats>0)
    return(zsummary)
}

summarize_roi <- function(roi, scan) {
	sinkdir	 <- file.path(base, sprintf("%s_%s_sink", scan, strategy))
	roidir 	 <- file.path(sinkdir, sprintf("roi_n%02i", roi))
	summarize_zstats(roidir, mask)
}

#' We want to have a nice dataframe with all this data and relevant context

df <- ldply(scans, function(scan) {
    rdf <- ldply(rois, summarize_roi, scan, .progress="text")
    rdf <- cbind(scan=rep(scan, length(rois)), roi=rois, label=roi_df$label, stat=roi_df$stat, rdf)
    return(rdf)
})
df$tot <- df$pos + df$neg

#scan <- "short"
#sinkdir <- file.path(base, sprintf("%s_%s_sink", scan, strategy))
#roidir <- file.path(sinkdir, sprintf("roi_n%02i", rois))
#zstatfiles  <- file.path(roidir, "stats/threshold", sprintf("thresh_zstat%i.nii.gz", 1:2))
#zstatfiles[!file.exists(zstatfiles)]



# df$label <- factor(df$label, levels=c("maxima", "significant", "not-significant", "minima"))

write.csv(df, file="/home/data/Projects/CWAS/nki/sca/summarize_sca-iq.csv")

