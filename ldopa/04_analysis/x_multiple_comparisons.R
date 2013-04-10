
library(connectir)
library(plyr)

terms <- c("conditions")
factors <- c("drug")
nfactors <- length(factors)


## Input Paths

basedir <- "/home2/data/Projects/CWAS"

sdist.dir <- file.path(basedir, "ldopa/cwas/rois_random_k3200")
mdmr.dir <- file.path(sdist.dir, "ldopa_subjects+meanFD.mdmr")
roi.dir <- file.path(basedir, "share/ldopa/rois")

mask.file <- file.path(sdist.dir, "mask2.nii.gz")
roi.file <- file.path(roi.dir, "rois_random_k3200.nii.gz")
pval.file <- file.path(mdmr.dir, "pvals.desc")
fperms.files <- file.path(mdmr.dir, sprintf("fperms_%s.desc", terms))


## Inputs

# Mask
hdr <- read.nifti.header(mask.file)
mask <- read.mask(mask.file)

# ROIs
rois <- read.nifti.image(roi.file)[mask]
urois <- sort(unique(rois))
urois <- urois[urois!=0]

# Pmatrix of pvals
Pmat <- attach.big.matrix(pval.file)

# Fperms
list.fperms <- lapply(fperms.files, attach.big.matrix)
nperms <- nrow(list.fperms[[1]])

# Pseudo-F Stats
Fmat <- sapply(list.fperms, function(fperms) fperms[1,])

niters <- 10
ns <- c(2000, 4000, 8000)
thrs <- -log10(c(0.05, 0.01, 0.005, 0.001))

fvals.mat <- laply(ns, function(n) {
    vcat(T, "n: %i", n)
    sapply(1:niters, function(iter) {
        vcat(T, "...iter: %i", iter)
        
        select.perms <- sample(2:nperms, n)
        list.partial.fperms <- lapply(list.fperms, function(fperms) 
                                        deepcopy(fperms, rows=c(1,select.perms)))
        Ptmp <- mdmr.fstats_to_pvals(list.partial.fperms)
        
        df <- data.frame(fstats=Fmat[,1], log.pvals=-log10(Ptmp[,1]))
        model <- lm(fstats ~ log.pvals, data=df)
        res <- predict(model, data.frame(log.pvals=thrs))
        names(res) <- thrs
        
        rm(list.partial.fperms, Ptmp)
        
        return(res)
    })
})

dimnames(fvals.mat) <- list(nperm=ns, thresh=round(thrs, 2), iters=1:niters)


# Get the number of false positives
pos <- laply(1:100, function(i) {
    list.partial.fperms <- lapply(list.fperms, function(fperms) 
                                    deepcopy(fperms, rows=c(i,1001:nperms)))
    Ptmp <- mdmr.fstats_to_pvals(list.partial.fperms, verbose=FALSE)
    colSums(Ptmp<0.05)
}, .progress="text")

