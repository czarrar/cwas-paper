# This script will mask the Craddock 1000 ROIs to ensure that all subjects have voxels with these values
library(niftir)

mask <- read.nifti.image("mask_for_age+sex.nii.gz")
rois <- read.nifti.image("../../../rois/rois_1k_3mm.nii.gz")

new_rois <- rois * mask
new_mask <- mask * (rois>0)

tvals <- table(new_rois[new_mask==1])
keep_vals <- as.numeric(names(tvals[tvals>25]))

new_mask2 <- new_rois %in% keep_vals
new_rois2 <- new_rois * new_mask2

uvals <- sort(unique(new_rois2[new_mask2]))
new_rois3 <- new_rois2
for (i in 1:length(uvals)) {
    u <- uvals[i]
    new_rois3[new_rois2==u] <- i
}

hdr <- read.nifti.header("mask_for_age+sex.nii.gz")
write.nifti(new_rois3, hdr, outfile="rois_380.nii.gz")
