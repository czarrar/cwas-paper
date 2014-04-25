#!/usr/bin/env Rscript

#' Create thresholded whole-brain maps with Pseudo-F values
#' note: uses easythresh for cluster correction

#scan <- "short"
scan <- "medium"

#+ libraries
library(bigmemory)
library(niftir)

#' ## Paths
#+ paths
base        <- "/home2/data/Projects/CWAS"
cwasdir     <- file.path(base, "nki", "cwas")
strategy    <- "compcor"
kstr        <- "kvoxs_fwhm08_to_kvoxs_fwhm08"
mdmr_name   <- "meanGcor_iq+age+sex+meanFD.mdmr"
cdir_name   <- "cluster_correct_v05_c05"
#+ directories
sdir        <- file.path(cwasdir, scan, sprintf("%s_%s", strategy, kstr))
mdir        <- file.path(sdir, mdmr_name)
#+ files
fperm_file  <- file.path(mdir, sprintf("fperms_%s_meanGcor.desc", scan))
mask_file   <- file.path(sdir, "mask.nii.gz")
clust_file  <- file.path(mdir, cdir_name, "easythresh", 
                        sprintf("cluster_mask_zstat_%s_meanGcor.nii.gz", scan))
out_file    <- file.path(mdir, cdir_name, "easythresh", "thresh_fstat_meanGcor.nii.gz")
pfile    <- file.path(mdir, cdir_name, "easythresh", sprintf("thresh_zstat_%s_meanGcor.nii.gz", scan))

print(file.exists(fperm_file))
print(file.exists(mask_file))
print(file.exists(clust_file))


#' ## F-Statistics

#' Read in the fperms matrix
fperms <- attach.big.matrix(fperm_file)

#' Select the 1st row
fstats <- fperms[1,]


#' ## Cluster Mask

#' Read in mask
mask <- read.mask(mask_file)

#' Read in clusters
clusters <- read.nifti.image(clust_file)

#' Get masked clusters & binarize
clusters <- (clusters[mask]>0)*1

#' ## Corrected F-stat map

#' Multipy F-stat map by masked clusters
clust_fstats <- fstats * clusters

#' Save to volume
hdr <- read.nifti.header(mask_file)
write.nifti(clust_fstats, hdr, mask, outfile=out_file)
