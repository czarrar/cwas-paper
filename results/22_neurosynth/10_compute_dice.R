#!/usr/bin/env Rscript


###
# SETUP
###

suppressPackageStartupMessages(library(connectir))

# Paths
base    <- "/home2/data/Projects/CWAS"
odir    <- file.path(base, "results/22_neurosynth")
dir.create(odir)

# Scans
scans   <- c("short", "medium")


###
# LOAD
###

# Mask
mask    <- read.mask(file.path(base, "nki/rois/mask_gray_2mm.nii.gz"))
nvoxs   <- sum(mask)

# Neurosynth
nsdir   <- file.path(base, "neurosynth/neurosynth/intelligence_reasoning_wm")
nsfile  <- file.path(nsdir, "_pAgF_z_FDR_0.05.nii.gz")
ns      <- read.nifti.image(nsfile)[mask]

# MDMR
sdirs   <- file.path(base, sprintf("nki/cwas/%s/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08", scans))
mdirs   <- file.path(sdirs, "iq_age+sex+meanFD.mdmr")
mfiles  <- file.path(mdirs, "cluster_correct_v05_c05/easythresh/thresh_zstat_FSIQ.nii.gz")
## resample file to be in 2mm space like neurosynth
m2files <- file.path(odir, sprintf("thresh_zstat_FSIQ_2mm_%s.nii.gz", scans))
for (i in 1:2) {
    cmd     <- sprintf("3dresample -inset %s -master %s -prefix %s", 
                        mfiles[i], nsfile, m2files[i])
    cat(cmd, "\n")
    system(cmd)
}
## read in resampled data
mdmrs   <- sapply(m2files, function(f) read.nifti.image(f)[mask])
colnames(mdmrs) <- scans


###
# Compare
###

dice <- function(a,b) (2*sum(a&b))/(sum(a)+sum(b))

dice.scans <- c(
    scan1 = dice(ns>0, mdmrs[,1]>0), 
    scan2 = dice(ns>0, mdmrs[,2]>0)
)

write.table(dice.scans, file=file.path(odir, "dice.txt"))