#!/usr/bin/env Rscript

# This script will generate tablish plots to display the number of significant
# findings within each of the seven Yeo brain networks.


###
# Setup

library(niftir)

# General Variables
base        <- "/home2/data/Projects/CWAS"
studies     <- c("development+motion", "adhd200_rerun", "ldopa")

# Input Paths
interm      <- "cwas/compcor_kvoxs_smoothed"
clterm      <- "cluster_correct_v05_c05/easythresh"
mdmr_paths  <- c(
    file.path(base, "development+motion", interm, "age+motion_sex+tr.mdmr"), 
    file.path(base, "adhd200_rerun", interm, "adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr"), 
    file.path(base, "ldopa", interm, "ldopa_subjects+meanFD.mdmr")
)
logp_paths  <- c(
    file.path(mdmr_paths[1], clterm, "thresh_zstat_age.nii.gz"), 
    file.path(mdmr_paths[2], clterm, "thresh_zstat_diagnosis.nii.gz"), 
    file.path(mdmr_paths[3], clterm, "thresh_zstat_conditions.nii.gz")
)
mask_paths  <- file.path(dirname(mdmr_paths), "mask.nii.gz")

# Output Path
outdir      <- file.path(base, "results/60_app_cwas")

# ROI directory
roidir      <- file.path(base, "nki", "rois")

# 1 = visual network
# 2 = somatomotor network
# 3 = dorsal attention
# 4 = ventral attention
# 5 = limbic
# 6 = fronto-parietal
# 7 = default network
labels <- c("visual", "somatomotor", "dorsal attention", "ventral attention", 
            "limbic", "fronto-parietal", "default")

###


###
# Read

logps <- sapply(1:length(studies), function(i) {
    logp_path <- logp_paths[i]
    mask_path <- mask_paths[i]
    
    mask    <- read.mask(mask_path)
    logp    <- read.nifti.image(logp_path)[mask]
    
    return(logp)
})

rois <- sapply(1:length(studies), function(i) {
    logp_path <- logp_paths[i]
    mask_path <- mask_paths[i]
    
    mask    <- read.mask(mask_path)
    rois    <- read.nifti.image(file.path(roidir, "all_7networks_4mm.nii.gz"))[mask]
    
    return(rois)
})

r <- unlist(rois)
urois <- sort(unique(r[r!=0]))

names(logps) <- studies
names(rois) <- studies

###


###
# Summarize

res <- sapply(1:length(studies), function(i) {
    sapply(1:length(urois), function(j) {
        mean(logps[[i]][rois[[i]]==urois[j]]>0)
    })
})
colnames(res) <- studies
rownames(res) <- labels

# for each study, get an order of the network size
rank_order <- apply(res, 2, function(x) names(sort(x, decreasing=T)))

###

###
# Save

write.table(round(res*100), file=file.path(outdir, "10_network_percent_byarea.txt"))
write.table(rank_order, file=file.path(outdir, "20_network_rank_order.txt"))

print(round(res*100))
print(rank_order)

###
