#!/usr/bin/env Rscript

#' # Goals
#' In this script, we want to calculate a p-value for the dice and spearman between scans
#'
#' # Implementation
#' To get this going, we will
#' - first read in the Fperms
#' - then loop through each permutation and calculate significance for both scans
#' - compare the two scans p < 0.05
#' - record this result (dice and spearman)

#' # Setup

#+ load
library(bigmemory)
library(plyr)
suppressPackageStartupMessages(library(connectir))

#+ functions
dice <- function(a,b) (2*sum(a&b))/(sum(a) + sum(b))

#' ## Paths

#+ paths
cat("Paths\n")

base  <- "/home2/data/Projects/CWAS"

###
# Scan 1
###

scan        <- "short"
sdist.dir   <- file.path(base, "nki/cwas", scan, "compcor_kvoxs_fwhm08_to_kvoxs_fwhm08")
mdmr.dir    <- file.path(sdist.dir, "iq_age+sex+meanFD.mdmr")
ref.dir     <- file.path(sdist.dir, "reference_iq_age+sex+meanFD.mdmr")

# Original Set
fperm.file  <- file.path(mdmr.dir, "fperms_FSIQ.desc")
fperms.o1   <- attach.big.matrix(fperm.file)

# Reference Set (compare regular to reference aka null distributions)
ref.file   <- file.path(ref.dir, "fperms_FSIQ.desc")
fperms.r1  <- attach.big.matrix(ref.file)

###
# Scan 2
###

scan        <- "medium"
sdist.dir   <- file.path(base, "nki/cwas", scan, "compcor_kvoxs_fwhm08_to_kvoxs_fwhm08")
mdmr.dir    <- file.path(sdist.dir, "iq_age+sex+meanFD.mdmr")
ref.dir     <- file.path(sdist.dir, "reference_iq_age+sex+meanFD.mdmr")

# Original Set
fperm.file  <- file.path(mdmr.dir, "fperms_FSIQ.desc")
fperms.o2   <- attach.big.matrix(fperm.file)

# Reference Set (compare regular to reference aka null distributions)
ref.file   <- file.path(ref.dir, "fperms_FSIQ.desc")
fperms.r2  <- attach.big.matrix(fperm.file)

###
# General
###

nperms      <- nrow(fperms.o1)  # all the perms should be the same

# Mask
mask.file   <- file.path(sdist.dir, "mask.nii.gz")
mask        <- read.mask(mask.file)
nvoxs       <- sum(mask)

# Output
odir        <- file.path(base, "results/20_cwas_iq")



#' # Compute

cat("Compute\n")

#' Loop through all the permutations (will take a while).
#' Compute the p-values and then compare the scans using dice and spearman.

#+ compute
compare.perms <- laply(1:nperms, function(i) {
    
    # Copy one row from the original F-perms to the reference F-perms
    # the idea here is that we will calculate the p-values for the set
    # of F-perms in the original set based on the reference set.
    # In this way, there won't be weird double-dipping.
    #
    # Then we calculate significance
    # 
    # We do this for scan1 and scan2 seperately
    ## scan 1
    bedeepcopy(x=fperms.o1, x.rows=i, y=fperms.r1, y.rows=1)
    pvals.s1 <- mdmr.fstats_to_pvals(list(fperms.r1), verbose=FALSE)[,]
    ## scan 2
    bedeepcopy(x=fperms.o2, x.rows=i, y=fperms.r2, y.rows=1)
    pvals.s2 <- mdmr.fstats_to_pvals(list(fperms.r2), verbose=FALSE)[,]
    
    # Compare the two scans with dice and spearman
    d <- dice(pvals.s1<0.05, pvals.s2<0.05)
    s <- cor(pvals.s1, pvals.s2, method="s")
    
    # Return
    c(dice=d, spearman=s)
}, .progress="text")

#' # Results

#' Dice
#+ dice
sum(compare.perms[,1] >= compare.perms[1,1])/nperms

#' Spearman
#+ spearman
sum(compare.perms[,2] >= compare.perms[2,2])/nperms

#' # Save
#+ save
save(compare.perms, nperms, file=file.path(odir, "50_compare_scans.rda"))
