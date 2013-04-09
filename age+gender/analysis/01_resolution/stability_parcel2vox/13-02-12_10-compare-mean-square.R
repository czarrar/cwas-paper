"""
1. Setup

2. Read in p-values => log format => FDR correct

3. 
"""


###
# Setup
###

library(connectir)
library(epiR)
library(plyr)
library(ggplot2)

base <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"

mfile <- file.path(base, "voxelwise", "mask.nii.gz")
mask <- read.mask(mfile)
hdr <- read.nifti.header(mfile)

ks <- c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400, sum(mask))
sdirnames <- c(sprintf("rois_random_k%04i", ks[-length(ks)]), "voxelwise")
folds <- 1:10
factors <- c("age", "sex")

odir <- file.path(base, "stability", "Rplots")
dir.create(odir, showWarnings=F, recursive=T)
setwd(odir)



###
# Functions
###

mse <- function(a,b) {
    (a-b)^2
}

mse <- function(x) {
    mat <- matrix(0, ncol(x), ncol(x))
    inds <- expand.grid(list(a=1:ncol(x), b=1:ncol(x)))
    inds <- inds[which(lower.tri(mat)),]
    diffsq <- sapply(1:nrow(inds), function(ri) {
        i <- inds[ri,1]; j <- inds[ri,2]
        a <- x[,i]; b <- x[,j]        
        sqrt((a-b)^2)
    })
    mse <- rowSums(diffsq)/ncol(diffsq)
    mse
}



###
# Read in P-Values => Log Format
###

list.logpvals <- lapply(1:length(factors), function(fi) {
    llply(1:length(ks), function(ki) {
        # Paths
        sdir <- file.path(base, sdirnames[ki])
        mfile <- file.path(sdir, "mask.nii.gz")
        mdirs <- file.path(sdir, "partial_mdmrs", sprintf("fold%02i_age+gender_with-meanFD_15k.mdmr", folds))
        pfiles <- file.path(mdirs, sprintf("one_minus_pvals_%s.nii.gz", factors[fi]))
        
        # Images
        mask <- read.mask(mfile)
        logpvals <- sapply(pfiles, function(f) -log10(1-read.nifti.image(f)[mask]))
        
        return(logpvals)
    }, .progress="text")
})

list.fdr.logpvals <- lapply(1:length(factors), function(fi) {
    llply(1:length(ks), function(ki) {
        pvals <- 10^(-list.logpvals[[fi]][[ki]])
        fdr.pvals <- p.adjust(pvals, "fdr")
        fdr.logpvals <- matrix(-log10(fdr.pvals), nrow(pvals), ncol(pvals))
        return(fdr.logpvals)
    }, .progress="text")
})



####
## Calculate regions that are significant in 8/9/10 runs
####
#
#list.mean.sig <- lapply(1:length(factors), function(fi) {
#    laply(1:length(ks), function(ki) {
#        vec <- rowMeans(list.logpvals[[fi]][[ki]])
#        vec
#    }, .progress="text"))
#})
#
#list.fdr.mean.sig <- lapply(1:length(factors), function(fi) {
#    laply(1:length(ks), function(ki) {
#        vec <- rowMeans(list.logpvals[[fi]][[ki]])
#        vec
#    }, .progress="text"))
#})



###
# Compute Mean Square Error
###

list.mse <- lapply(1:length(factors), function(fi) {
    t(laply(1:length(ks), function(ki) {
        mse(list.logpvals[[fi]][[ki]])
    }, .progress="text"))
})

list.fdr.mse <- lapply(1:length(factors), function(fi) {
    t(laply(1:length(ks), function(ki) {
        mse(list.fdr.logpvals[[fi]][[ki]])
    }, .progress="text"))
})



####
## Compute Overlap Sig & MSE
####
#
#list.comb <- lapply(1:length(factors), function(fi) {
#    vsig <- list.sig[[fi]] * 2
#    vmse <- list.mse[[fi]]
#    vcomb <- vsig + vmse
#    vcomb
#})
#
#list.fdr.comb <- lapply(1:length(factors), function(fi) {
#    vsig <- list.sig[[fi]] * 2
#    vmse <- list.mse[[fi]]
#    vcomb <- vsig + vmse
#    vcomb
#})
#
#vsig <- list.sig[[fi]] * 2
#vmse <- list.mse[[fi]]
#
#u <- sort(unique(vsig))
#tapply(vmse, vsig, mean)



###
# Plot
###

# 1. Setup
nvoxs <- nrow(list.fdr.mse[[1]])
slabs <- rep(ks, each=nvoxs)
df <- data.frame(
    size = slabs, 
    log.size = log(slabs), 
    log10.size = log10(slabs), 
    mse.age = as.vector(list.fdr.mse[[1]]), 
    mse.sex = as.vector(list.mse[[1]])
)

# 2. Plot box plots for age
## dice
x11(width=10, height=6)
ggplot(df, aes(x=as.factor(log.size), y=mse.age)) + 
#    geom_violin() + 
    geom_boxplot() + 
    scale_x_discrete(breaks=log(ks), labels=ks) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("13-02-14_parcels2vox_fdr_mse_age.png")
dev.off()

# 3. Plot box plots for sex
## dice
x11(width=10, height=6)
ggplot(df, aes(x=as.factor(log.size), y=mse.sex)) + 
#    geom_violin() + 
    geom_boxplot() + 
    scale_x_discrete(breaks=log(ks), labels=ks) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("13-02-14_parcels2vox_mse_sex.png")
dev.off()




###
# Save nifti
###

fi <- 1
for (ki in 1:length(ks)) {
    cat(sprintf("Factor: %s; k %i\n", factors[fi], ks[ki]))
    voxs <- list.fdr.mse[[fi]][,ki]
    ofile <- sprintf("13-02-13_fdr_mse_%s_k%04i.nii.gz", factors[fi], ks[ki])
    write.nifti(voxs, hdr, mask, outfile=ofile, overwrite=T)
}

fi <- 2
for (ki in 1:length(ks)) {
    cat(sprintf("Factor: %s; k %i\n", factors[fi], ks[ki]))
    voxs <- list.mse[[fi]][,ki]
    ofile <- sprintf("13-02-13_mse_%s_k%04i.nii.gz", factors[fi], ks[ki])
    write.nifti(voxs, hdr, mask, outfile=ofile, overwrite=T)
}
