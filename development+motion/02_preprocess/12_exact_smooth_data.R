#!/usr/bin/env Rscript

# Read in arg
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
    msg <- paste(
        "usage: 12_exact_smooth_data.R resolution fwhm", 
        "resolution: integer resolution of resampled data", 
        sep="\n"
    )
    stop(msg)
}
res  <- as.integer(args[1])
fwhm <- as.integer(args[2])

suppressPackageStartupMessages(library(connectir))
library(tools)


###
# General
###

# Paths
basedir <- "/home2/data/Projects/CWAS/share/development+motion"
subinfo <- file.path(basedir, "subinfo")



###
# Do IT!
###

vcat(T, "resolution: %i", res)

# input functional paths
if (res == 2) {
  flist     <- file.path(subinfo, "02_funcpaths.txt")
} else {
  flist     <- file.path(subinfo, sprintf("02_funcpaths_%imm.txt", res))
}
raw <- read.table(flist)[,1]
infiles <- as.character(raw)
infiles <- sub("/home/", "/home2/", infiles)
  
# output file path
prefix <- file_path_sans_ext(file_path_sans_ext(flist))
out_flist <- sprintf("%s_fwhm%02i.txt", prefix, fwhm)
  
# command
cmd <- "3dBlurToFWHM -input %s -mask %s -FWHM %i -prefix %s"

# loop through
outfiles <- sapply(infiles, function(infile) {
    #vcat(T, "...%s", infile)
    maskfile <- file.path(dirname(dirname(infile)), 
                  sprintf("functional_brain_mask_to_standard_%imm.nii.gz", res))
    prefix <- file_path_sans_ext(file_path_sans_ext(infile))
    outfile <- sprintf("%s_fwhm%02i.nii.gz", prefix, fwhm)

    if (file.exists(outfile)) {
        vcat(T, "exists: %s", outfile)
    } else {
        real_cmd <- sprintf(cmd, infile, maskfile, fwhm, outfile)
        cat(real_cmd, "\n")
        system(real_cmd)
    }

    return(outfile)    
})

vcat(T, "...saving file list")
write.table(outfiles, file=out_flist, row.names=F, col.names=F)
