#!/usr/bin/env Rscript

library(RColorBrewer)

# One thought is to save this as an image
# since it is just 11 values, I should be able
# to import them into pages manually.

cat("...colorbrewer reduced\n")
cb.col <- rev(brewer.pal(11, "Spectral"))
print(cb.col)
cb.rgb <- t(col2rgb(cb.col))
print(cb.rgb)
