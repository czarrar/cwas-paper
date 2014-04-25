#!/usr/bin/env Rscript

#' This script checks that the ROIs extracted appear reasonable.
#' Meaning that the center and average MDMR values closely match 
#' those from the extracted image.

#' For this comparison, I'll first resample the ROIs into 4mm space
#' from 2mm space. I could also do the reverse but I imagine it would
#' be the same.

suppressPackageStartupMessages(library(niftir))
library(plyr)

#+ paths
base    <- "/home2/data/Projects/CWAS"
df_file <- file.path(base, "nki/sca2/seeds/rois_all_info.csv")
roi_file2 <- file.path(base, "nki/sca2/seeds/rois_2mm.nii.gz")
roi_file4 <- file.path(base, "nki/sca2/seeds/rois_4mm.nii.gz")
std_file  <- file.path(base, "nki/rois/standard_4mm.nii.gz")
sdist_dir <- file.path(base, "nki/cwas/medium/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08")
mask_file <- file.path(sdist_dir, "mask.nii.gz")
cwas_file <- file.path(sdist_dir, "iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz")

#+ resample
cmd <- sprintf("3dresample -inset %s -master %s -prefix %s", roi_file2, std_file, roi_file4)
cat(cmd, "\n")
system(cmd)

#+ load
df      <- read.csv(df_file)[,-1]
mask    <- read.mask(mask_file)
rois    <- read.nifti.image(roi_file4)[mask]
cwas    <- read.nifti.image(cwas_file)[mask]

#+ rois
urois <- sort(unique(rois[rois!=0]))

#' Get the center and average MDMR ROI value, amongst other things
#' corresponding ROI values
#+ new-roi-vals
new_df <- ddply(df, .(val), function(x) {
    w    <- rois == x$val
    inds <- which(w)
    m    <- which.min(abs(cwas[inds] - x$stat))
    data.frame(
        label = x$label, 
        val = x$val, 
        nvox = sum(w), 
        orig.vox = m, 
        original = x$stat, 
        center = cwas[inds][m], 
        average = mean(cwas[inds]), 
        max = max(cwas[inds]), 
        min = min(cwas[inds])
    )
})
new_df$label <- factor(new_df$label, 
                    levels=c("maxima", "significant", "not-significant", "minima"))

#' Check the original and center values are all the same.
#+ check-center
stop( any(round(new_df$original - new_df$center, 3) != 0) )

#' See the difference between the average and original values
#' as well as the relationship of the MDMR value within each
#' group.
#+ check-average
print(round(new_df$original - new_df$average, 3))

#' In each ROI group, let's see the change in the MDMR value
#+ check-group-change
print(tapply(round(new_df$original - new_df$average, 3), new_df$label, mean))

#' In each ROI group, let's also see what the average MDMR value
#' is for the whole ROI vs just the peak voxel.
#+ check-group-ave
# original
print(tapply(new_df$original, new_df$label, mean))
# average
print(tapply(new_df$average, new_df$label, mean))

#' Let's quickly explore the range of MDMR values within each group
#+ check-range
# min
print(ddply(new_df, .(label), colwise(min)))
# max
print(ddply(new_df, .(label), colwise(max)))

#' These results appear to suggest that using the ROIs will on average decrease any
#' perceived differences between the different regions.
