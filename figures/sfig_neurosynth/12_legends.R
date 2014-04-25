#!/usr/bin/env Rscript

library(RColorBrewer)

# One thought is to save this as an image
# since it is just 11 values, I should be able
# to import them into pages manually.

odir <- "/home2/data/Projects/CWAS/figures/sfig_neurosynth"
n <- 256

cat("CWAS - Blues\n")
cwas <- colorRampPalette(brewer.pal(9, "Blues"))(n)
x11(width=9, height=3)
image(1:n, 1, as.matrix(1:n), col=cwas, xlab="", ylab="", 
        xaxt="n", yaxt="n", bty="n")
dev.copy(png, filename=file.path(odir, "legend_cwas.png"))
dev.off()

cat("Neurosynth - Purples\n")
neurosynth <- colorRampPalette(brewer.pal(9, "Purples"))(n)
x11(width=9, height=3)
image(1:n, 1, as.matrix(1:n), col=neurosynth, xlab="", ylab="", 
        xaxt="n", yaxt="n", bty="n")
dev.copy(png, filename=file.path(odir, "legend_neurosynth.png"))
dev.off()
