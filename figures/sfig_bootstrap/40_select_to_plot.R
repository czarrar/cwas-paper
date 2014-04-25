#!/usr/bin/env Rscript

#+ libraries
suppressPackageStartupMessages(library(niftir))

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
idir    <- "/home2/data/Projects/CWAS/nki/bootstrap"
load(file.path(idir, "results_short.rda"))
mfile   <- "/home2/data/Projects/CWAS/nki/cwas/short/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/mask.nii.gz"
mask    <- read.mask(mfile)
hdr     <- read.nifti.header(mfile)

#+ analyze
d.mat   <- dice(pvals.mat<0.05)
df      <- data.frame(r=d.mat[lower.tri(d.mat)])

#' I will plot the data for these two subjects with median values
#+ select
coords <- expand.grid(list(x=1:nrow(d.mat), y=1:ncol(d.mat)))
coords <- coords[which(lower.tri(d.mat)),]

mval <- median(df$r)
inds <- which(abs(df$r - mval) < 1e-4)
rinds <- sample(inds, 2) # 25744, 106078

samples <- sort(as.numeric(as.matrix(coords[rinds,])))
# 55, 384, 307, 356

#+ save
odir <- idir
for (sample in samples) {
    logp <- -log10(pvals.mat[,sample])
    write.nifti(logp, hdr, mask, outfile=file.path(odir, sprintf("sample%03i_log_pvals.nii.gz", sample)), overwrite=T)
}
