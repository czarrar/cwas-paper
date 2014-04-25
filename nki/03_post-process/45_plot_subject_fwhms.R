#' Here we will plot the estimated smoothness for scan 1 and scan 2.

#+ setup
library(ggplot2)
subdir <- "../subinfo/40_Set1_N104"
short.file <- file.path(subdir, "short_compcor_fwhm_4mm.txt")
medium.file <- file.path(subdir, "medium_compcor_fwhm_4mm.txt")

#+ read
shorts <- t(read.table(short.file)[,])
mediums <- t(read.table(medium.file)[,])

#+ datafy
df <- data.frame(
    scan = rep(c("scan 1", "scan 2", "scan 1-2"), each=prod(dim(shorts))), 
    dimension = rep(rep(c("x", "y", "z"), each=nrow(shorts)), ncol(shorts)), 
    fwhm = c(as.vector(shorts), as.vector(mediums), as.vector(shorts-mediums))
)
df$scan <- factor(df$scan, levels=c("scan 1", "scan 2", "scan 1-2"))

#' # Plot
#' The figure below shows the estimated smoothness across subjects for the x, y, 
#' and z dimensions. For each dimension, a violin plot is shown for scan 1, scan 2, 
#' and the paired difference between scans 1 vs 2.
#' 
#' Scan 1 (3mm isotropic) is aboud 1mm more smooth then scan 2.

#+ violin-plot
ggplot(df, aes(scan, fwhm, fill=scan)) + 
  geom_violin() +
  facet_grid(. ~ dimension)

