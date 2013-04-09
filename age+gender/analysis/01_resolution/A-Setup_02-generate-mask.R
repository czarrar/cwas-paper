###
# This script simply generates the group mask
###

library(niftir)

# Subject Info
df <- read.csv("z_details.csv")

# Setup files (3mm)
mask_paths <- file.path(df$outdir, "func/functional_brain_mask_to_standard.nii.gz")
fsldir <- "/home2/data/PublicProgram/fsl-4.1.9/data/standard"
overlap_mask <- read.nifti.image(file.path(fsldir, "MNI152_T1_GREY_3mm_25pc_mask.nii.gz"))
hdr <- read.nifti.header(file.path(fsldir, "MNI152_T1_GREY_3mm_25pc_mask.nii.gz"))

# Gather brain masks (compute overlap)
for (i in 1:length(mask_paths)) {
    mask <- read.nifti.image(mask_paths[i])
    overlap_mask <- mask * overlap_mask
}

# Save
write.nifti(overlap_mask, hdr, outfile="rois/mask.nii.gz", overwrite=TRUE)


#library(plyr)
#mask <- read.mask(file.path(fsldir, "MNI152_T1_GREY_3mm_25pc_mask.nii.gz"))
#all_masks <- laply(mask_paths, function(mask_path) {
#    read.nifti.image(mask_path)[mask]
#}, .progress="text")
#write.nifti(t(all_masks), hdr, mask, outfile="rois/all_masks.nii.gz", odt="int")
