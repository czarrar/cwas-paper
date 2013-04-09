"""
For a given parcellation level:

    For a given fold:
    
        Read in the pvalues
"""

###
# Setup
###

library(connectir)
library(epiR)
library(plyr)
library(ggplot2)

base <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"
mask <- read.mask(file.path(base, "voxelwise", "mask.nii.gz"))
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

dice <- function(a,b) {
    (2*sum(a&b))/sum(a+b)
}

dice.mat <- function(a, b=a, z=0) {
    xa <- a > z; xb <- b > z
    mat <- matrix(1, ncol(xa), ncol(xb))
    inds <- expand.grid(list(a=1:ncol(xa), b=1:ncol(xb)))
    for (ri in 1:nrow(inds)) {
        i <- inds[ri,1]; j <- inds[ri,2]
        mat[i,j] <- dice(xa[,i], xb[,j])
    }
    mat
}

concordance.mat <- function(xa, xb=xa) {
    mat <- matrix(1, ncol(xa), ncol(xb))
    inds <- expand.grid(list(a=1:ncol(xa), b=1:ncol(xb)))
    for (ri in 1:nrow(inds)) {
        i <- inds[ri,1]; j <- inds[ri,2]
        mat[i,j] <- epi.ccc(xa[,i], xb[,j])$rho.c$est
    }
    mat
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


###
# Similarities (Regular P-Values)
###

list.kendall <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        kendall_ref(logpvals)
    }, .progress="text")
})

list.dice <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=-log10(0.05))[w]
    }, .progress="text")
})

list.pearson <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        cor(logpvals, method="p")[w]
    }, .progress="text")
})

#list.spearman <- lapply(1:length(factors), function(fi) {
#    laply(1:length(ks), function(ki) {
#        logpvals <- list.logpvals[[fi]][[ki]]
#        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
#        cor(logpvals, method="s")[w]
#    }, .progress="text")
#})
#
#list.concordance <- lapply(1:length(factors), function(fi) {
#    laply(1:length(ks), function(ki) {
#        logpvals <- list.logpvals[[fi]][[ki]]
#        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
#        concordance.mat(logpvals)[w]
#    }, .progress="text")
#})


###
# Similarities (FDR-Corrected P-Values)
###

list.fdr.kendall <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.fdr.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        kendall_ref(logpvals)
    }, .progress="text")
})

list.fdr.dice <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.fdr.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=-log10(0.05))[w]
    }, .progress="text")
})

list.fdr.pearson <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.fdr.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        cor(logpvals, method="p")[w]
    }, .progress="text")
})

#list.fdr.spearman <- lapply(1:length(factors), function(fi) {
#    laply(1:length(ks), function(ki) {
#        logpvals <- list.fdr.logpvals[[fi]][[ki]]
#        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
#        cor(logpvals, method="s")[w]
#    }, .progress="text")
#})
#
#list.fdr.concordance <- lapply(1:length(factors), function(fi) {
#    laply(1:length(ks), function(ki) {
#        logpvals <- list.fdr.logpvals[[fi]][[ki]]
#        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
#        concordance.mat(logpvals)[w]
#    }, .progress="text")
#})


###
# Plot Age
###

# 1. Setup
fi <- 1
nreps <- ncol(list.fdr.dice[[1]])
#slabs <- rep(c(rep(ks, 2), sum(mask)), nreps)
slabs <- rep(rep(ks, 2), nreps)

# 2. Data Frame
df <- data.frame(
    size = slabs, 
    log.size = log(slabs), 
    log10.size = log10(slabs), 
    dice = as.vector(list.fdr.dice[[fi]]), 
    pearson = as.vector(list.fdr.pearson[[fi]])
)

# 3. Plot box plots
## dice
x11(width=8, height=6)
ggplot(df, aes(x=as.factor(log.size), y=dice)) + 
    geom_boxplot() + 
    scale_x_discrete(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("13-02-11_parcels2vox_fdr_dice_age.png")
dev.off()
## pearson
x11(width=8, height=6)
ggplot(df, aes(x=as.factor(log.size), y=pearson)) + 
    geom_boxplot() + 
    scale_x_discrete(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("13-02-11_parcels2vox_fdr_pearson_age.png")
dev.off()



###
# Plot Sex
###

# 1. Setup
fi <- 2
nreps <- ncol(list.fdr.dice[[2]])
#slabs <- rep(c(rep(ks, 2), sum(mask)), nreps)
slabs <- rep(rep(ks, 2), nreps)

# 2. Data Frame
df <- data.frame(
    size = slabs, 
    log.size = log(slabs), 
    log10.size = log10(slabs), 
    dice = as.vector(list.dice[[fi]]), 
    pearson = as.vector(list.fdr.pearson[[fi]])
)

# 3. Plot box plots
## dice
x11(width=8, height=6)
ggplot(df, aes(x=as.factor(log.size), y=dice)) + 
    geom_boxplot() + 
    scale_x_discrete(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("13-02-11_parcels2vox_dice_sex.png")
dev.off()
## pearson
x11(width=8, height=6)
ggplot(df, aes(x=as.factor(log.size), y=pearson)) + 
    geom_boxplot() + 
    scale_x_discrete(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("13-02-11_parcels2vox_fdr_pearson_sex.png")
dev.off()


