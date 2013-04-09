"""
Notes for 3/4/13:
- Edited dice to get thresholds at -log10 => 2, 3, 4
- Only plot 3200 parcellation result
- Only ploy dice, kendall, and pearson
"""


###
# Setup
###

library(connectir)
library(epiR)
library(plyr)
library(ggplot2)

base <- "/home2/data/Projects/CWAS/age+gender/03_robustness/cwas"
mask <- read.mask(file.path(base, "voxelwise", "mask.nii.gz"))

samples <- c("discovery", "replication")
#ks <- c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400, sum(mask))
ks <- c(3200)

sdirnames <- sprintf("%s_rois_random_k%04i", samples, ks)
factors <- c("age", "sex")

odir <- file.path(dirname(base), "rplot_cwas")
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
        sdirnames <- sprintf("%s_rois_random_k%04i", samples, ks[ki])
        sdirs <- file.path(base, sdirnames)
        mfile <- file.path(sdirs, "mask2.nii.gz")[1]
        mdirs <- file.path(sdirs, "age+gender_15k.mdmr")
        pfiles <- file.path(mdirs, sprintf("logp_%s.nii.gz", factors[fi]))
        
        # Images
        mask <- read.mask(mfile)
        logpvals <- sapply(pfiles, function(f) read.nifti.image(f)[mask])
        
        return(logpvals)
    }, .progress="text")
})

list.fdr.logpvals <- lapply(1:length(factors), function(fi) {
    llply(1:length(ks), function(ki) {
        # Paths
        sdirnames <- sprintf("%s_rois_random_k%04i", samples, ks[ki])
        sdirs <- file.path(base, sdirnames)
        mfile <- file.path(sdirs, "mask2.nii.gz")[1]
        mdirs <- file.path(sdirs, "age+gender_15k.mdmr")
        pfiles <- file.path(mdirs, sprintf("fdr_logp_%s.nii.gz", factors[fi]))
        
        # Images
        mask <- read.mask(mfile)
        fdr.logpvals <- sapply(pfiles, function(f) read.nifti.image(f)[mask])
        
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

list.dice1 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=1)[w]
    }, .progress="text")
})

list.dice15 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=1.5)[w]
    }, .progress="text")
})

list.dice2 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=2)[w]
    }, .progress="text")
})

list.dice25 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.fdr.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=2.5)[w]
    }, .progress="text")
})

list.dice3 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=3)[w]
    }, .progress="text")
})

list.dice35 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=3.5)[w]
    }, .progress="text")
})

list.dice4 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=4)[w]
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


# Save
cat("Saving...\n")
save(list.kendall, list.pearson, 
     list.dice1, list.dice15, list.dice2, list.dice25, list.dice3, list.dice35, list.dice4, 
     file="/home/data/Projects/CWAS/age+gender/03_robustness/cwas/similarities.rda")



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

list.fdr.dice1 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.fdr.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=1)[w]
    }, .progress="text")
})

list.fdr.dice15 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.fdr.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=1.5)[w]
    }, .progress="text")
})

list.fdr.dice2 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.fdr.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=2)[w]
    }, .progress="text")
})

list.fdr.dice25 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.fdr.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=2.5)[w]
    }, .progress="text")
})

list.fdr.dice3 <- lapply(1:length(factors), function(fi) {
    laply(1:length(ks), function(ki) {
        logpvals <- list.fdr.logpvals[[fi]][[ki]]
        w <- lower.tri(matrix(0, ncol(logpvals), ncol(logpvals)))
        dice.mat(logpvals, z=3)[w]
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

# Save
cat("Saving...\n")
save(list.fdr.kendall, list.fdr.pearson, 
     list.fdr.dice1, list.fdr.dice15, list.fdr.dice2, list.fdr.dice25, list.fdr.dice3, 
     file="/home/data/Projects/CWAS/age+gender/03_robustness/cwas/similarities_fdr.rda")


