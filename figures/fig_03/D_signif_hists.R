#!/usr/bin/env Rscript

library(ggplot2)
library(RColorBrewer)

base    <- "/home2/data/Projects/CWAS"
idir    <- file.path(base, "results/20_cwas_iq")
odir    <- file.path(base, "figures/fig_03")

# loads: falsey, sigs, sig.rates
load(file.path(idir, "40_false_positives.rda"))

# Spit out:
# - percent of significant voxels in real data vs mean percent in permutations
# - percent of permutations with more significant voxels
# - plot histogram of significant voxels with a line for the real deal

# Colors
cols <- brewer.pal(6, "Dark2")[c(1,4,6,2)]
names(cols) <- c("short", "medium", "overlap", "long")
cols <- as.list(cols)


# Data
df <- data.frame(
    scan    = rep(c("Scan 1", "Scan 2"), each=nrow(sig.rates)), 
    value   = as.vector(sig.rates)
)

# Theme Setting
hist_theme <- theme_grey() + 
  theme(text=element_text(family="Helvetica")) + 
  theme(axis.ticks = element_blank(), axis.title = element_blank()) + 
  theme(axis.text = element_text(size=18)) + 
  theme(panel.grid.major = element_line(color="white", size=1), 
        panel.grid.minor = element_line(color="white", size=0.25))

# Scan 1
cat("Plot: Histogram of Scan 1\n")
ggplot(subset(df, scan == "Scan 1"), aes(x=value)) + 
    geom_histogram(binwidth=2, fill=cols$short) + 
    geom_vline(xintercept=sig.rates[1,1], linetype=2) + 
    xlim(0,30) + 
    ylim(0,6200) + 
    xlab("Percent of significant voxels") + 
    ylab("Number of permuted datasets") + 
    hist_theme
ggsave(file.path(odir, "D_plot_hist_scan1.png"), width=4, height=3.5)

# Scan 2
cat("Plot: Histogram of Scan 2\n")
ggplot(subset(df, scan == "Scan 2"), aes(x=value)) + 
    geom_histogram(binwidth=2, fill=cols$medium) + 
    geom_vline(xintercept=sig.rates[1,2], linetype=2) + 
    xlim(0,30) + 
    ylim(0,6200) + 
    xlab("Percent of significant voxels") + 
    ylab("Number of permuted datasets") + 
    hist_theme
ggsave(file.path(odir, "D_plot_hist_scan2.png"), width=4, height=3.5)
