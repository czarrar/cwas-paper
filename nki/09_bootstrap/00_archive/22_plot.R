#!/usr/bin/env Rscript

#' This script will create various plots for the bootstrap results
#' including histograms and scatterplots

#' Ideally, I would have the two scans done.
#' However, for now I only have one so I'll load that and put it into a dataframe

#+ setup, include=FALSE
library(ggplot2)
idir <- "/home/data/Projects/CWAS/nki/bootstrap"


#' # Scan 1 (TR = 645ms)

#+ load-data
load(file.path(idir, "results_short.rda"))
df <- data.frame(
    scan = rep("short", length(results$t0)), 
    logp = -log10(results$t0), 
    prop = prop_sig
)

#' Get the histogram of proportion of significant results
#+ histo
p <- ggplot(df, aes(x=prop)) + 
        geom_histogram() + 
        xlab("Proportion of Significant Bootstrap Results")
print(p)

#' Get the scatter plot comparing
#' - the significant results with the complete data
#' - to the proportion of significant bootstrap results
#+ scatter
p <- ggplot(df, aes(x=logp, y=prop)) + 
        geom_point() + 
        geom_vline(xintercept=-log10(0.05), linetype=2, color="red") + 
        xlab("Original Results") + 
        ylab("Proportion of Significant Bootstrap Results") + 
        ggtitle("IQ CWAS")
print(p)

#' The above plot is a bit strange
#' I've looked up stuff for boot. It generates each bootstrap by resampling 
#' the subject indices with replacement. Truthfully, this procedure would
#' indicate to me that there should be a greater match with the original data 
#' than if I resampled without replacement. So I'm a little confused.
