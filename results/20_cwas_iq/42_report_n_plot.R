#!/usr/bin/env Rscript

library(ggplot2)

base    <- "/home2/data/Projects/CWAS"
idir    <- file.path(base, "results/20_cwas_iq")
logfile <- file.path(idir, "42_report.txt")

# loads: falsey, sigs, sig.rates
load(file.path(idir, "40_false_positives.rda"))

# Spit out:
# - percent of significant voxels in real data vs mean percent in permutations
# - percent of permutations with more significant voxels
# - plot histogram of significant voxels with a line for the real deal

cat("Saving basic info to text file\n")

if (file.exists(logfile))
    file.remove(logfile)
msg <- paste(sig.rates[1,], "% of significant voxels in real data (scan 1 & 2, respectively)", "\n\n")
msg <- paste(msg, colMeans(sig.rates[-1,]), "mean % of significant voxels in permuted data (scan 1 & 2, respectively)", "\n\n")
msg <- paste(msg, sigs*100, "% of permutations with more significant voxels than real data (scan 1 & 2, respectively)", "\n\n")
cat(msg, file=logfile)

# Plot
df <- data.frame(
    scan    = rep(c("Scan 1", "Scan 2"), each=nrow(sig.rates)), 
    value   = as.vector(sig.rates)
)
## scan 1
cat("Plot: Histogram of Scan 1\n")
ggplot(subset(df, scan == "Scan 1"), aes(x=value)) + 
    geom_histogram(binwidth=1) + 
    geom_vline(xintercept=sig.rates[1,1], linetype=2) + 
    xlim(0,30) + 
    ggtitle("Scan 1") + 
    xlab("Percent of significant voxels") + 
    ylab("Number of permuted datasets")
ggsave(file.path(idir, "42_plot_hist_scan1.png"))
## scan 2
cat("Plot: Histogram of Scan 2\n")
ggplot(subset(df, scan == "Scan 2"), aes(x=value)) + 
    geom_histogram(binwidth=1) + 
    geom_vline(xintercept=sig.rates[1,2], linetype=2) + 
    xlim(0,30) + 
    ggtitle("Scan 2") + 
    xlab("Percent of significant voxels") + 
    ylab("Number of permuted datasets")
ggsave(file.path(idir, "42_plot_hist_scan2.png"))
