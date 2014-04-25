#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(connectir))

# Paths
base    <- "/home2/data/Projects/CWAS"
odir    <- file.path(base, "results/40_mdmr_glm")
dir.create(odir)

# Scans
scans   <- c("short", "medium")

# Mask
mask    <- read.mask(file.path(base, "nki/rois/mask_gray_4mm.nii.gz"))
nvoxs   <- sum(mask)

# GLM
sdirs   <- file.path(base, sprintf("nki/glm/%s_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/summary", scans))
gfiles  <- file.path(sdirs, "uwt_iq.nii.gz")
glms    <- sapply(gfiles, function(f) read.nifti.image(f)[mask])
glms    <- (glms/nvoxs)*100
colnames(glms) <- scans

# MDMR
sdirs   <- file.path(base, sprintf("nki/cwas/%s/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08", scans))
mdirs   <- file.path(sdirs, "iq_age+sex+meanFD.mdmr")
mfiles  <- file.path(mdirs, "cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz")
mdmrs   <- sapply(mfiles, function(f) read.nifti.image(f)[mask])
mdmrs   <- -log10(pt(mdmrs, Inf, lower.tail=F))
colnames(mdmrs) <- scans

# Create the dataframes
df.short    <- data.frame(
    mdmr    = mdmrs[,1], 
    glm     = glms[,1]
)
df.medium   <- data.frame(
    mdmr    = mdmrs[,2], 
    glm     = glms[,2]
)

# Compute correlation
scan1 <- cor(df.short$mdmr, df.short$glm, method="s")
scan2 <- cor(df.medium$mdmr, df.medium$glm, method="s")

# Compile
df <- data.frame(
    scan = c("Scan 1", "Scan 2"), 
    spearman = c(scan1, scan2)
)
print(df)

# Save
write.table(df, file=file.path(odir, "10_scan_correlations.txt"))

# Compute Regression
lm1 <- summary(lm(df.short$glm ~ df.short$mdmr))
lm2 <- summary(lm(df.medium$glm ~ df.medium$mdmr))
