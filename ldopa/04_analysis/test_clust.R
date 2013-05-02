# This script will run cluster correction for the MDMR Results

## Libraries/Functions/Basics

library(connectir)
library(plyr)
source("y_inline_connectir.R")
basedir <- "/home2/data/Projects/CWAS"

## Terms and Factors

terms <- c("conditions")
factors <- c("drug")
nfactors <- length(factors)


## ROIs

# Paths
roi.dir <- file.path(basedir, "share/ldopa/rois")
mask.file <- file.path(roi.dir, "mask_for_ldopa_gray_4mm.nii.gz")
roi.file <- file.path(roi.dir, "rois_random_k3200.nii.gz")

# Mask
hdr <- read.nifti.header(mask.file)
mask <- read.mask(mask.file)
nvoxs <- sum(mask)

# ROIs
rois <- read.nifti.image(roi.file)[mask]
urois <- sort(unique(rois))
urois <- urois[urois!=0]
nrois <- length(urois)
rois.inds <- lapply(urois, function(ur) which(rois==ur))


## Load Fstats for 15k Permutations

# Paths
sdist.dir <- file.path(basedir, "ldopa/cwas/rois_random_k3200")
mdmr.dir <- file.path(sdist.dir, "ldopa_subjects+meanFD.mdmr")
fperms.files <- file.path(mdmr.dir, sprintf("fperms_%s.desc", terms))
pval.file <- file.path(mdmr.dir, "pvals.desc")

# Fperms
list.fperms <- lapply(fperms.files, attach.big.matrix)
nperms <- nrow(list.fperms[[1]])


## Clusterize

fi <- 1; i <- 1
vox.thresh <- 1.5
img <- rois_to_voxelwise(list.fperms[[fi]], as.double(i), rois.inds, as.double(nvoxs))
orig.ct <- cluster.table(img, vox.thresh, hdr$dim, mask)
new.ct <- cpp.cluster.table(img, vox.thresh, hdr$dim, mask)




img[,] <- 0
img[500,1] <- 1
img[501,1] <- 1
img[1000,1] <- 1

# will want to go through cpp.cluster.table and check at each level

tmp <- cpp.cluster.table(img, vox.thresh, hdr$dim, mask)