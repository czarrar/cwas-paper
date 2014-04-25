#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(connectir))
library(plyr)

# Paths
base    <- "/home2/data/Projects/CWAS"
odir    <- file.path(base, "results/40_mdmr_glm")
dir.create(odir)

# Scans
scans   <- c("short", "medium")

# Mask
mask    <- read.mask(file.path(base, "nki/rois/mask_gray_4mm.nii.gz"))
nvoxs   <- sum(mask)


###
# Mean Connectivity
###

# GLM
sdirs   <- file.path(base, sprintf("nki/glm/old_%s_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/summary", scans))
gfiles  <- file.path(sdirs, "uwt_iq.nii.gz")
glms    <- sapply(gfiles, function(f) read.nifti.image(f)[mask])
glms0   <- (glms/nvoxs)*100
colnames(glms0) <- scans

# MDMR
sdirs   <- file.path(base, sprintf("nki/cwas/%s/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08", scans))
mdirs   <- file.path(sdirs, "iq_age+sex+meanFD+meanGcor.mdmr")
mfiles  <- file.path(mdirs, "cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz")
mdmrs   <- sapply(mfiles, function(f) read.nifti.image(f)[mask])
mdmrs0  <- -log10(pt(mdmrs, Inf, lower.tail=F))
colnames(mdmrs0) <- scans


###
# NO Mean Connectivity
###

# GLM
sdirs   <- file.path(base, sprintf("nki/glm/%s_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/summary", scans))
gfiles  <- file.path(sdirs, "uwt_iq.nii.gz")
glms    <- sapply(gfiles, function(f) read.nifti.image(f)[mask])
glms1   <- (glms/nvoxs)*100
colnames(glms1) <- scans

# MDMR
sdirs   <- file.path(base, sprintf("nki/cwas/%s/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08", scans))
mdirs   <- file.path(sdirs, "iq_age+sex+meanFD.mdmr")
mfiles  <- file.path(mdirs, "cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz")
mdmrs   <- sapply(mfiles, function(f) read.nifti.image(f)[mask])
mdmrs1  <- -log10(pt(mdmrs, Inf, lower.tail=F))
colnames(mdmrs1) <- scans


# Create the dataframes
df  <- data.frame(
    measure = factor(rep(c("mdmr", "glm"), each=nvoxs*2)), 
    scan    = factor(rep(rep(c("short", "long"), each=nvoxs), 2)), 
    mean    = c(as.vector(mdmrs0), as.vector(glms0)), 
    nomean  = c(as.vector(mdmrs1), as.vector(glms1))
)


###
# Similarity
###

cat("\n\nSimilarity\n")

# Compute correlation
sim <- ddply(df, .(measure, scan), function(x) cor(x$mean, x$nomean, method="s"))
print(sim)

# Save
write.table(sim, file=file.path(odir, "40_similarity_wwo_mean_connectivity.txt"))


###
# Overlap
###

cat("\n\nOverlap\n")

# Compute dice
dice <- function(a,b) (2*sum(a&b))/(sum(a)+sum(b))
dice_percentile <- function(perc, a, b) {
    athr <- quantile(a, perc)
    bthr <- quantile(b, perc)
    dice(a>athr, b>bthr)
}

percs <- c(0.85, 0.9, 0.95)
overlaps <- ddply(df, .(measure, scan), function(x) {
    ret <- sapply(percs, dice_percentile, x$mean, x$nomean)
    names(ret) <- percs
    ret
})
print(overlaps)

# Save
write.table(df, file=file.path(odir, "40_overlap_wwo_mean_connectivity.txt"))
