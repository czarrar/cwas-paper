# This script will generate the mask for the age+sex two group analyses

library(niftir)
library(Rsge)
basedir <- "/home2/data/Projects/CWAS/share/age+gender"

# Get standard gray matter mask
grey.file <- "/home2/data/PublicProgram/fsl-4.1.9/data/standard/MNI152_T1_GREY_4mm_25pc_mask.nii.gz"
gray.mask <- read.mask(grey.file)
hdr <- read.nifti.header(grey.file)

# Get data frame
df <- read.csv(file.path(basedir, "subinfo/04_all_df.csv"))

# This part generates the mask for each subject
# and returns the list of mask files
# (note this runs on gelert)
cmd <- "fslmaths %s -abs -Tmin -bin %s"
njobs <- nrow(df)
maskfiles <- sge.parLapply(as.character(df$outdir), function(outdir) {
    funcfile <- file.path(outdir, "func", "bandpass_freqs_0.01.0.1", "functional_mni_4mm.nii.gz")
    maskfile <- file.path(outdir, "func", "functional_brain_mask_to_standard_4mm.nii.gz")
    real_cmd <- sprintf(cmd, funcfile, maskfile)
    
    cat(real_cmd, "\n")
    system(real_cmd)
    
    return(maskfile)
}, function.savelist=ls(), njobs=njobs)
maskfiles <- unlist(maskfiles)

# Generate group mask
mask <- gray.mask * 1
for (maskfile in maskfiles)
    mask <- mask * read.mask(maskfile)
    

# Save file
file.copy(grey.file, file.path(basedir, "rois", "gray_4mm.nii.gz"))
write.nifti(mask, hdr, outfile=file.path(basedir, "rois", "mask_for_age+sex_gray_4mm.nii.gz"), overwrite=T)
