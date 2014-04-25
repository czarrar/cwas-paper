#!/usr/bin/env Rscript

#' # Goal:
#' Falsey (name of this script) wants to calculate the % of significant 
#' connections in the real data versus permuted data.
#'
#' # Methods:
#' - find the path to the Fperms matrix
#' - loop through each row (may 100 or 500x)
#' - calculate the number of significant voxels
#' 

library(bigmemory)
library(plyr)
suppressPackageStartupMessages(library(connectir))


###
# Paths

cat("Paths\n")

base  <- "/home2/data/Projects/CWAS"
scans <- c("short", "medium")

sdist.dirs  <- file.path(base, "nki/cwas", scans, "compcor_kvoxs_fwhm08_to_kvoxs_fwhm08")
mdmr.dirs   <- file.path(sdist.dirs, "iq_age+sex+meanFD.mdmr")
ref.dirs    <- file.path(sdist.dirs, "reference_iq_age+sex+meanFD.mdmr")

# Regular Set
fperm.files <- file.path(mdmr.dirs, "fperms_FSIQ.desc")
list.fperms <- lapply(fperm.files, attach.big.matrix)
nperms      <- nrow(list.fperms[[1]])

# Reference Set (compare regular to reference aka null distributions)
ref.files   <- file.path(ref.dirs, "fperms_FSIQ.desc")
list.refs   <- lapply(ref.files, attach.big.matrix)
nrefs       <- nrow(list.refs[[1]])

# Mask
mask.file   <- file.path(sdist.dirs, "mask.nii.gz")[1]
mask        <- read.mask(mask.file)
nvoxs       <- sum(mask)

odir        <- file.path(base, "results/20_cwas_iq")

###


###
# Compute

cat("Compute\n")

# Loop through all the permutations (will take a while)
falsey <- laply(1:nperms, function(i) {
    # Copy one row from the original F-perms to the reference F-perms
    # the idea here is that we will calculate the p-values for the set
    # of F-perms in the original set based on the reference set.
    # In this way, there won't be weird double-dipping.
    for (j in 1:length(list.fperms)) {
        bedeepcopy(x=list.fperms[[j]], x.rows=i, y=list.refs[[j]], y.rows=1)
    }
    
    # Calculate significance
    Ptmp <- mdmr.fstats_to_pvals(list.refs, verbose=FALSE)
    
    # Calculate number of significant voxels
    colSums(Ptmp<0.05)
}, .progress="text")

###


###
# Summarize

cat("Summarize\n")

# Get number of permutations with more significant voxels
sigs <- apply(falsey, 2, function(x) sum(x[1]<=x)/length(x))

# Get percent of significant voxels for each row (this gives the false positive rate)
sig.rates <- (falsey/nvoxs)*100

###


###
# Save

cat("Save\n")

# Save falsey, sigs, and sig.rates
ofile <- file.path(odir, "40_false_positives.rda")
if (file.exists(ofile)) {
    file.rename(ofile, file.path(odir, "40_false_positives_old.rda"))
}
save(falsey, sigs, sig.rates, file=ofile)

###
