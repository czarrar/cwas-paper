#!/usr/bin/env Rscript

#' This script compares the regressor info for IQ and mean global connectivity.

library(plyr)
library(ggplot2)
library(RColorBrewer)

base <- "/home2/data/Projects/CWAS"
subdir <- file.path(base, "share", "nki", "subinfo", "40_Set1_N104")

obase <- file.path(base, "figures", "fig_04")

df <- read.csv(file.path(subdir, "subject_info_with_iq_and_gcors.csv"))
show.df <- data.frame(
    Scan = rep(c("Scan 1", "Scan 2"), each=nrow(df)), 
    IQ = rep(df$FSIQ, 2), 
    Global = c(df$short_meanGcor, df$medium_meanGcor)
)

print(ddply(show.df, .(Scan), function(x) cor(x$IQ, x$Global)))

#p <- ggplot(show.df, aes(x=Global, y=IQ, color=Scan)) + 
#        geom_point(shape=1) + 
#        facet_grid(". ~ Scan") + 
#        xlab("Mean Global Connectivity") + 
#        scale_color_manual(values=brewer.pal(8, "Dark2")[c(1,4)], guide=FALSE) + 
#        theme(axis.text = element_text(size=16))
#print(p)
#
#outfile <- file.path(obase, "D_iq_vs_global.png")
#ggsave(outfile, width=6, height=3)
#
## t(102) = -1.6; p = 0.1
#print(summary(lm(FSIQ ~ short_meanGcor, df)))
#
## t(102) = -2.1; p < 0.05
#print(summary(lm(FSIQ ~ medium_meanGcor, df)))
#