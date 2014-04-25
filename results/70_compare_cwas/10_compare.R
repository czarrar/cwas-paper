#!/usr/bin/env Rscript

# Here I will compare the various CWAS maps
# IQ scan 1, IQ scan 2, age (development), motion, adhd, and ldopa

suppressPackageStartupMessages(library(niftir))
library(corrplot)
library(RColorBrewer)


###
# Setup Paths
###

base <- "/home2/data/Projects/CWAS"
partial_paths <- list(
    adhd = "adhd200_rerun/cwas/compcor_kvoxs_fwhm08/adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr/cluster_correct_v05_c05/easythresh/thresh_zstat_diagnosis.nii.gz", 
    dev = "development+motion/cwas/compcor_kvoxs_smoothed/age+motion_sex+tr.mdmr/cluster_correct_v05_c05/easythresh/thresh_zstat_age.nii.gz", 
    motion = "development+motion/cwas/compcor_kvoxs_smoothed/age+motion_sex+tr.mdmr/cluster_correct_v05_c05/easythresh/thresh_zstat_mean_FD.nii.gz", 
    ldopa = "ldopa/cwas/compcor_kvoxs_smoothed/ldopa_subjects+meanFD.mdmr/cluster_correct_v05_c05/easythresh/thresh_zstat_conditions.nii.gz", 
    iq1 = "nki/cwas/short/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh/thresh_zstat_FSIQ.nii.gz", 
    iq2 = "nki/cwas/medium/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh/thresh_zstat_FSIQ.nii.gz"
)

cwas_paths <- file.path(base, partial_paths)
names(cwas_paths) <- names(partial_paths)

mask_paths <- file.path(dirname(dirname(dirname(dirname(cwas_paths)))), "mask.nii.gz")

n <- length(mask_paths)

odir <- file.path(base, "results/70_compare_cwas")
dir.create(odir)


###
# Load Masks and Create Composite Mask
###

masks <- sapply(mask_paths, read.mask)
mask  <- apply(masks, 1, all)


###
# Load the Data
###

mdmr.data <- sapply(cwas_paths, function(p) read.nifti.image(p)[mask])


###
# Correlate
###

# Compute the correlation
rs <- cor(mdmr.data, method="s")
diag(rs) <- 0
print(rs)

###
# Plot
###

x11()
cols <- c(rep("white", 20), brewer.pal(9, "YlOrRd"), rep("white", 18))
corrplot.mixed(rs, upper="shade", diag='n', col=cols, 
               cl.lim=c(-0.1,0.2), cl.length=12, addshade="all")
dev.copy(jpeg, filename=file.path(odir, "10_compare_plot.jpeg"))
dev.off()
