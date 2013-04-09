#!/usr/bin/env R

####
## Below is the SGE Version
####
#
#library(Rsge)
#njobs <- 48
#
#basedir <- "/home2/data/Projects/CWAS/share/development+motion"
#subinfo <- file.path(basedir, "subinfo")
#
## 1. input functional paths
#raw <- read.table(file.path(subinfo, "02_funcpaths.txt"))[,1]
#infiles <- as.character(raw)
#infiles <- sub("/home/", "/home2/", infiles)
#
## 2. 4mm resolution brain (i.e., the master)
#stdfile <- "/home2/data/PublicProgram/fsl-4.1.9/data/standard/MNI152_T1_4mm_brain.nii.gz"
#
## 3. command
#cmd <- "3dresample -inset %s -master %s -rmode Linear -prefix %s"
#
## outfiles <- file.path(dirname(infiles), "functional_mni_4mm.nii.gz")
#
#res <- sge.parLapply(infiles, function(infile) {
#    outfile <- file.path(dirname(infile), "functional_mni_4mm.nii.gz")
#    if (file.exists(outfile))
#        file.remove(outfile)
#    real_cmd <- sprintf(cmd, infile, stdfile, outfile)
#    system(real_cmd)
#}, function.savelist=ls(), njobs=njobs)


###
# Below is the regular version
###

basedir <- "/home2/data/Projects/CWAS/share/development+motion"
subinfo <- file.path(basedir, "subinfo")

# 1. input functional paths
raw <- read.table(file.path(subinfo, "02_funcpaths.txt"))[,1]
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


