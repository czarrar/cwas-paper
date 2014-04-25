#!/usr/env/bin Rscript

#' This script will load all the 800 pacellation and voxelwise results for the following
#' datasets: development, ADHD, L-DOPA, and IQ (scans 1 and 2).
#' 
#' It then will example the following metrics:
#' 1. Percent of significant voxelwise results
#' 2. Correlation with each other
#' 3. Percent overlap with voxelwise results
#' 4. Dice
#' 5. Spearman Correlation

# CHECK THAT THIS FILE WAS SAVED

#' # Setup
#' This is just gets all the paths

#+ setup-libraries
suppressPackageStartupMessages(library(niftir))
library(plyr)

#+ setup-functions
dice <- function(a,b) (2 * sum(a&b))/(sum(a) + sum(b))

#+ setup-paths
base <- "/home2/data/Projects/CWAS"
studies <- c("development", "adhd", "ldopa", "iq_scan1", "iq_scan2")
nstudies <- length(studies)
odir <- file.path(base, ...)

#' Input files.
#+ setup-files
vox.mdmr.files <- c(
    development = "development+motion/cwas/compcor_kvoxs_smoothed/age+motion_sex+tr.mdmr/cluster_correct_v05_c05/easythresh/zstat_age.nii.gz", 
    adhd = "adhd200_rerun/cwas/compcor_kvoxs_fwhm08/adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr/cluster_correct_v05_c05/easythresh/zstat_diagnosis.nii.gz", 
    ldopa = "ldopa/cwas/compcor_kvoxs_smoothed/ldopa_subjects+meanFD.mdmr/cluster_correct_v05_c05/easythresh/zstat_conditions.nii.gz", 
    iq_scan1 = "nki/cwas/short/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz", 
    iq_scan2 = "nki/cwas/medium/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz"
)
roi.mdmr.files <- c(
    development = "development+motion/cwas/rois_random_k0800_only/age+motion_sex+tr.mdmr/cluster_correct_v05_c05/easythresh/zstat_age.nii.gz", 
    adhd = "adhd200_rerun/cwas/compcor_rois_random_k0800_only/adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr/cluster_correct_v05_c05/easythresh/zstat_diagnosis.nii.gz", 
    ldopa = "ldopa/cwas/rois_random_k0800_only/ldopa_subjects+meanFD.mdmr/cluster_correct_v05_c05/easythresh/zstat_conditions.nii.gz", 
    iq_scan1 = "nki/cwas/short/compcor_only_rois_random_k0800/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz", 
    iq_scan2 = "nki/cwas/medium/compcor_only_rois_random_k0800/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz"
)

vox.mdmr.files <- file.path(base, vox.mdmr.files)
roi.mdmr.files <- file.path(base, roi.mdmr.files)

if (!all(file.exists(vox.mdmr.files))) stop("voxelwise files don't all exist")
if (!all(file.exists(roi.mdmr.files))) stop("parcellation files don't all exist")

#' ## Load Niftis
#' Load the data both unthresholded and thresholded
#+ setup-load
load_easythresh <- function(f, thresh=FALSE, mask=NULL) {
    if (is.null(mask)) {
        dn <- dirname
        m <- file.path(dn(dn(f)), "mask.nii.gz")
        if (!file.exists(m)) m <- file.path(dn(dn(dn(dn(f)))), "mask.nii.gz")
        mask <- read.mask(m)
    }
    
    # Since the input is assumed to be the unthresholded zstat file
    # this will simply rename it to get the thresh in there
    if (thresh) {
        path <- dirname(f)
        fname <- basename(f)
        f <- file.path(path, sprintf("thresh_%s", fname))
    }
    
    read.nifti.image(f)[mask]
}

# Unthresholded Data
vox.mdmr.raw <- lapply(vox.mdmr.files, load_easythresh)
roi.mdmr.raw <- lapply(roi.mdmr.files, load_easythresh)

# Thresholded Data
vox.mdmr.thr <- lapply(vox.mdmr.files, load_easythresh, thresh=TRUE)
roi.mdmr.thr <- lapply(roi.mdmr.files, load_easythresh, thresh=TRUE)

# Manually load ADHD using vox and parcel overlap
# and fix this error
mask.vox <- read.mask(file.path(base, "adhd200_rerun/cwas/compcor_kvoxs_fwhm08/mask.nii.gz"))
mask.roi <- read.mask(file.path(base, "adhd200_rerun/cwas/compcor_rois_random_k0800_only/adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr/cluster_correct_v05_c05/mask.nii.gz"))
mask.ove <- mask.vox & mask.roi
vox.mdmr.raw[[2]] <- load_easythresh(vox.mdmr.files[2], mask=mask.ove)
roi.mdmr.raw[[2]] <- load_easythresh(roi.mdmr.files[2], mask=mask.ove)
vox.mdmr.thr[[2]] <- load_easythresh(vox.mdmr.files[2], thresh=TRUE, mask=mask.ove)
roi.mdmr.thr[[2]] <- load_easythresh(roi.mdmr.files[2], thresh=TRUE, mask=mask.ove)


###
# Metrics
###

#' # Main Metrics
#'
#' Below are the main measures of interest to understand if the results
#' are fairly similar.
#'
#' 1. Percent overlap with voxelwise results
#' 2. Dice
#' 3. Spearman Correlation
#+ metrics-main
metrics.main <- data.frame(
    studies = studies, 
    percent = sapply(1:nstudies, function(i) {
        r <- roi.mdmr.thr[[i]]>0
        v <- vox.mdmr.thr[[i]]>0
        (sum(v&r)/sum(v))*100
    }), 
    dice = sapply(1:nstudies, function(i) {
        r <- roi.mdmr.thr[[i]]>0
        v <- vox.mdmr.thr[[i]]>0
        dice(r,v)
    }), 
    spearman = sapply(1:nstudies, function(i) {
        r <- roi.mdmr.raw[[i]]
        v <- vox.mdmr.raw[[i]]
        cor(r,v,method="s")
    })
)

#' # Other Metrics
#'
#' These are more out of interest. We might want to know the number of significant results.
#' And possibly less desired but we might want to know any change in specificity
#'
#' 1. Percent of significant voxelwise results
#+ metrics-nsig
metrics.others <- data.frame(
    studies = rep(studies, 2), 
    resolution = c(rep(c("voxelwise", "parcellation"), each=nstudies)), 
    percent = c(
        sapply(vox.mdmr.thr, function(x) mean(x>0)), 
        sapply(roi.mdmr.thr, function(x) mean(x>0))
    )*100
)

#' # Save
write.table(metrics.main, file=file.path(odir, ...))
write.table(metrics.others, file=file.path(odir, ...))
