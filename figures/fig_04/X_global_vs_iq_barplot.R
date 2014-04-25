#!/usr/bin/env Rscript

library(niftir)
library(ggplot2)

basedir <- "/home2/data/Projects/CWAS/nki/cwas"
strategy <- "compcor"
scans <- c("short", "medium")

# Distance Directory
kstr <- "kvoxs_fwhm08_to_kvoxs_fwhm08"
dirname <- sprintf("%s_%s", strategy, kstr)
distdirs <- file.path(basedir, scans, dirname)

# MDMR Directories
iq.name <- "iq_age+sex+meanFD+meanGcor.mdmr"
gl.name <- "meanGcor_iq+age+sex+meanFD.mdmr"
cname <- "cluster_correct_v05_c05"
iq.factor <- "FSIQ"
gl.factor <- "*_meanGcor"

# MDMR Directories
iq.mdmr <- file.path(distdirs, iq.name)
gl.mdmr <- file.path(distdirs, gl.name)

# Significance Files
iq.pfiles <- Sys.glob(file.path(iq.mdmr, cname, "easythresh", sprintf("thresh_zstat_%s.nii.gz", iq.factor)))
gl.pfiles <- Sys.glob(file.path(gl.mdmr, cname, "easythresh", sprintf("thresh_zstat_%s.nii.gz", gl.factor)))

# Mask File
mask_files <- file.path(distdirs, "mask.nii.gz")

# Output prefixes
obase <- "/home2/data/Projects/CWAS/figures"
odir <- file.path(obase, "fig_04")
if (!file.exists(odir)) dir.create(odir)

# Compute summary
res <- sapply(1:length(scans), function(i) {
    mask    <- read.mask(mask_files[i])
    global  <- read.nifti.image(gl.pfiles[i])[mask]
    iq      <- read.nifti.image(iq.pfiles[i])[mask]
    c(
        sig = mean(global[iq>0]),
        nosig = mean(global[iq==0])
    )
})
colnames(res) <- scans

print(res)
