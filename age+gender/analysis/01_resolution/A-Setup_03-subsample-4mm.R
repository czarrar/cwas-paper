#!/usr/bin/env Rscript

library(Rsge)

basedir <- "/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution"
roidir <- file.path(basedir, "rois")

###
# Subsample Functionals
###

# 1. input functional paths
infiles <- as.character(read.table("z_funcpaths.txt")[,1])

# 2. 4mm resolution brain (i.e., the master)
stdfile <- "/home2/data/PublicProgram/fsl-4.1.9/data/standard/MNI152_T1_4mm_brain.nii.gz"

# 3. command
cmd <- "3dresample -inset %s -master %s -rmode Linear -prefix %s"

# 4. execute
njobs <- length(infiles)
outfiles <- sge.parLapply(infiles, function(infile) {
    outfile <- file.path(dirname(infile), "functional_mni_4mm.nii.gz")
    if (file.exists(outfile))
        return(outfile)
    real_cmd <- sprintf(cmd, infile, stdfile, outfile)
    system(real_cmd)
    return(outfile)
}, function.savelist=ls(), njobs=njobs)

# 5. save
outfiles <- unlist(outfiles)
write.table(outfiles, file="z_funcpaths_4mm.txt", row.names=F, col.names=F)


###
# Create subject brain masks
###

cmd <- "fslmaths %s -abs -Tmin -bin %s"

maskfiles <- sge.parLapply(outfiles, function(infile) {
    maskfile <- file.path(dirname(dirname(infile)), 
                    "functional_brain_mask_to_standard_4mm.nii.gz")
    real_cmd <- sprintf(cmd, infile, maskfile)
    
    cat(real_cmd, "\n")
    system(real_cmd)
    
    return(maskfile)
}, function.savelist=ls(), njobs=njobs)
maskfiles <- unlist(maskfiles)


###
# Generate group mask
###

library(niftir)

# Use 4mm grey-matter mask as the init
fsldir <- "/home2/data/PublicProgram/fsl-4.1.9/data/standard"
overlap_mask <- read.nifti.image(file.path(fsldir, "MNI152_T1_GREY_4mm_25pc_mask.nii.gz"))
hdr <- read.nifti.header(file.path(fsldir, "MNI152_T1_GREY_4mm_25pc_mask.nii.gz"))

# Gather brain masks (compute overlap)
for (i in 1:length(maskfiles)) {
    mask <- read.nifti.image(maskfiles[i])
    overlap_mask <- mask * overlap_mask
}

# Save
write.nifti(overlap_mask, hdr, outfile="rois/mask_4mm.nii.gz", odt="int")

