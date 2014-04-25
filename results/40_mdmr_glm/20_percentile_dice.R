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

# Compute dice
dice <- function(a,b) (2*sum(a&b))/(sum(a)+sum(b))
dice_percentile <- function(perc, a, b) {
    athr <- quantile(a, perc)
    bthr <- quantile(b, perc)
    dice(a>athr, b>bthr)
}

percs <- c(0.85, 0.9, 0.95)
scan1 <- sapply(percs, dice_percentile, df.short$mdmr, df.short$glm)
scan2 <- sapply(percs, dice_percentile, df.medium$mdmr, df.medium$glm)

# Compile
df <- data.frame(
    scan        = rep(c("Scan 1", "Scan 2"), each=3), 
    percentile  = rep(percs*100, 2), 
    dice        = c(scan1, scan2)
)
print(df)

# Save
write.table(df, file=file.path(odir, "20_percentile_dice.txt"))
