#!/usr/bin/env R

###
# Below is the SGE Version
###

library(Rsge)
njobs <- 48

basedir <- "/home2/data/Projects/CWAS/share/age+gender"
subinfo <- file.path(basedir, "subinfo")

# 1. input functional paths
raw <- read.table(file.path(subinfo, "04_all_funcpaths.txt"))[,1]
infiles <- as.character(raw)
infiles <- sub("/home/", "/home2/", infiles)

# 2. 4mm resolution brain (i.e., the master)
stdfile <- "/home2/data/PublicProgram/fsl-4.1.9/data/standard/MNI152_T1_4mm_brain.nii.gz"

# 3. command
cmd <- "3dresample -inset %s -master %s -rmode Linear -prefix %s"

# outfiles <- file.path(dirname(infiles), "functional_mni_4mm.nii.gz")

res <- sge.parLapply(infiles, function(infile) {
    outfile <- file.path(dirname(infile), "functional_mni_4mm.nii.gz")
    if (file.exists(outfile))
        file.remove(outfile)
    real_cmd <- sprintf(cmd, infile, stdfile, outfile)
    system(real_cmd)
}, function.savelist=ls(), njobs=njobs)


###
# Below is the regular version
###

basedir <- "/home2/data/Projects/CWAS/share/age+gender"
subinfo <- file.path(basedir, "subinfo")

# 1. input functional paths
raw <- read.table(file.path(subinfo, "04_all_funcpaths.txt"))[,1]
infiles <- as.character(raw)
infiles <- sub("/home/", "/home2/", infiles)

# 2. 4mm resolution brain (i.e., the master)
stdfile <- "/home2/data/PublicProgram/fsl-4.1.9/data/standard/MNI152_T1_4mm_brain.nii.gz"

# 3. command
cmd <- "3dresample -inset %s -master %s -rmode Linear -prefix %s"

# outfiles <- file.path(dirname(infiles), "functional_mni_4mm.nii.gz")

for (infile in infiles) {
    outfile <- file.path(dirname(infile), "functional_mni_4mm.nii.gz")
    if (file.exists(outfile))
        file.remove(outfile)
    real_cmd <- sprintf(cmd, infile, stdfile, outfile)
    
    cat(real_cmd, "\n")
    system(real_cmd)
}


###
# Below is the regular version to generate a mask
###


# Generate the mask

cmd <- "fslmaths %s -abs -Tmin -bin %s"

for (infile in infiles) {
    maskfile <- file.path(dirname(dirname(infile)), 
                    "functional_brain_mask_to_standard_4mm.nii.gz")
    real_cmd <- sprintf(cmd, infile, maskfile)
    
    cat(real_cmd, "\n")
    system(real_cmd)
}
