#!/usr/bin/env Rscript

library(ggplot2)

basedir <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/timing"
mat <- read.csv(file.path(basedir, "collected_times.csv"))
mat <- as.matrix(mat[,-1])

df <- data.frame(
    parcellations = rep(sub("X", "", colnames(mat)), each=10), 
    values = as.vector(mat)
)

setwd("/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/combined_rois+voxelwise")
x11(width=12, height=6)
ggplot(df, aes(factor(parcellations), values)) + geom_violin() + 
    stat_summary(fun.y=mean, geom="point",fill="black", shape=21, size=3) + 
    theme(axis.text = element_text(face="bold", size=20), axis.title=element_blank())
ggsave("compare_timings.png")
dev.off()

