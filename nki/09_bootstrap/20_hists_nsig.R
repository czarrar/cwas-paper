#!/usr/bin/env Rscript

#' I'm going to be generated a histogram of the percent of signfiicant results
#' across all possible permutations and maybe make an indication of where the
#' result is for the actual data

#+ libraries
suppressPackageStartupMessages(library(niftir))
library(ggplot2)
library(RColorBrewer)

#+ load
idir <- "/home/data/Projects/CWAS/nki/bootstrap"
load(file.path(idir, "results_short.rda"))

#+ analyze
nsig0 <- mean(pvals0<0.05) * 100
nsigs <- colMeans(pvals.mat<0.05) * 100
df <- data.frame(nsig=nsigs)

#+ settings
# Colors
cols <- brewer.pal(6, "Dark2")[c(1,4,6,2)]
names(cols) <- c("short", "medium", "overlap", "long")
cols <- as.list(cols)
# Theme
hist_theme <- theme_grey() + 
  theme(text=element_text(family="Helvetica")) + 
  theme(axis.ticks = element_blank(), axis.title = element_blank()) + 
  theme(axis.text = element_text(size=18)) + 
  theme(panel.grid.major = element_line(color="white", size=1), 
        panel.grid.minor = element_line(color="white", size=0.25))

#' Plot our data
#+ plot
cat("Plot Histogram\n")
ggplot(df, aes(x=nsigs)) + 
    geom_histogram(binwidth=1, fill=cols$short) + 
    geom_vline(xintercept=nsig0, linetype=2) + 
    geom_hline(yintercept=0) + 
    xlim(0,40) + 
#    ylim(0,6200) + 
    xlab("Percent of significant voxels") + 
    ylab("Number of bootstrap subsamples") + 
    hist_theme

#' Save output locally and then on flickr
#+ save
odir <- "/home/data/Projects/CWAS/figures/sfig_bootstrap"
ggsave(file.path(odir, "A_hist_nsigs_scan1.png"), width=4, height=3.5)
