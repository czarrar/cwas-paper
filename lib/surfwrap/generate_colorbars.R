#!/usr/bin/env Rscript

library(colorspace)
library(RColorBrewer)

# To plot any of the colorbars, you can use the function below
pal <- function(col, border = NA, ...) {
    n <- length(col)
    plot(0, 0, type="n", xlim = c(0, 1), ylim = c(0, 1),
        axes = FALSE, xlab = "", ylab = "", ...)
    rect(0:(n-1)/n, 0, 1:n/n, 1, col = col, border = border)
}


###
# Spectral

cat("Spectral\n")

# HCL
cat("...hcl\n")
hcl.spectral <- t(col2rgb(rev(rainbow_hcl(256, start=0, end=315))))
write.table(hcl.spectral, file="colorbars/spectral-hcl.txt", 
            row.names=F, col.names=F, quote=F)

# ColorBrewer
cat("...colorbrewer\n")
cb.spectral <- t(col2rgb(colorRampPalette(rev(brewer.pal(11, "Spectral")))(256)))
write.table(cb.spectral, file="colorbars/spectral-cb.txt", 
            row.names=F, col.names=F, quote=F)

# ColorBrewer - Reduced
cat("...colorbrewer reduced\n")
tmp <- t(col2rgb(rev(brewer.pal(11, "Spectral"))))
inds <- sort(rep(1:11, length.out=256))
cb.spectral <- tmp[inds,]
write.table(cb.spectral, file="colorbars/spectral-reduced-cb.txt", 
            row.names=F, col.names=F, quote=F)

###

###
# Discrete

cat("Discrete\n")

cat("...hcl1-3\n")
cols <- rainbow_hcl(2, start=180, end=320, c=65, l=75)
cols <- col2rgb(cols)
cols <- cbind(cols[,1], cols[,2], (cols[,1]+cols[,2])/2)
cols <- cols[,rep(1:ncol(cols),each=floor(256/ncol(cols)))]
if (ncol(cols) < 256)
    cols <- cbind(cols, cols[,rep(ncol(cols), 256-ncol(cols))])
hcl1.discrete <- t(cols)
write.table(hcl1.discrete, file="colorbars/discrete-hcl1-3.txt", 
            row.names=F, col.names=F, quote=F)

cat("...colorbrewer1-3\n")
cols <- brewer.pal(8, "Dark2")[c(1,4,3)]
cols <- col2rgb(cols)
#cols <- cbind(cols[,1], cols[,2], (cols[,1]+cols[,2])/2)
cols <- cols[,rep(1:ncol(cols),each=floor(256/ncol(cols)))]
if (ncol(cols) < 256)
    cols <- cbind(cols, cols[,rep(ncol(cols), 256-ncol(cols))])
cb1.discrete <- t(cols)
write.table(cb1.discrete, file="colorbars/discrete-cb1-3.txt", 
            row.names=F, col.names=F, quote=F)

cat("...colorbrewer2-3\n")
cols <- brewer.pal(8, "Dark2")[c(1,4,6)]
cols <- col2rgb(cols)
#cols <- cbind(cols[,1], cols[,2], (cols[,1]+cols[,2])/2)
cols <- cols[,rep(1:ncol(cols),each=floor(256/ncol(cols)))]
if (ncol(cols) < 256)
    cols <- cbind(cols, cols[,rep(ncol(cols), 256-ncol(cols))])
cb2.discrete <- t(cols)
write.table(cb2.discrete, file="colorbars/discrete-cb2-3.txt", 
            row.names=F, col.names=F, quote=F)
