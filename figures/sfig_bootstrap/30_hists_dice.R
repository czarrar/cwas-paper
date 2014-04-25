#!/usr/bin/env Rscript

#' Correlation all possible bootstrap subsamples and plot the distribution

#+ libraries
suppressPackageStartupMessages(library(niftir))
library(ggplot2)
library(RColorBrewer)

#+ functions
dice <- function(mat) {
    # (2*sum(a&b))/(sum(a)+sum(b))
    
    # This gets the number of elements in common between a & b
    sum.anb <- crossprod(mat)
    
    # We can get the sum in each set with the diagonal
    sum.a <- diag(sum.anb) %*% t(rep(1,ncol(mat)))
    sum.b <- t(sum.a)
    
    # Let's combine
    dice.mat <- (2*sum.anb)/(sum.a+sum.b)
    
    dice.mat
}

#+ load
idir    <- "/home/data/Projects/CWAS/nki/bootstrap"
load(file.path(idir, "results_short.rda"))

#+ analyze
d.mat   <- dice(pvals.mat<0.05)
df      <- data.frame(r=d.mat[lower.tri(d.mat)])

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
ggplot(df, aes(x=r)) + 
    geom_histogram(binwidth=0.05, fill=cols$short) + 
    geom_hline(yintercept=0) + 
    xlim(0,1) + 
#    ylim(0,6200) + 
    xlab("Dice Coefficient Between Each Pair of Subsamples") + 
    ylab("Number of Bootstrap Subsamples") + 
    hist_theme

#' Save output locally and then on flickr
#+ save
odir <- "/home/data/Projects/CWAS/figures/sfig_bootstrap"
ggsave(file.path(odir, "C_hist_dice_scan1.png"), width=4, height=3.5)

