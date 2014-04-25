#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(connectir))
library(tools)


# Read in arg
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
    msg <- paste(
        "usage: 42_smooth_data.R strategy resolution fwhm", 
        "strategy: compcor or global", 
        "resolution: integer resolution of resampled data", 
        "fwhm: mm for smoothing", 
        sep="\n"
    )
    stop(msg)
}
strategy <- as.character(args[1])
res <- as.integer(args[2])
fwhm <- as.numeric(args[3])

# check
strategies <- c("compcor", "global")
if(!(strategy %in% strategies)) stop("invalid strategy")


###
# General
###

# Paths
basedir <- "/home2/data/Projects/CWAS/share/nki"
subinfo <- file.path(basedir, "subinfo")

# Scan stuff
scans <- c("short", "medium", "long")
scan_folder <- c("40_Set1_N104", "40_Set1_N104", "40_Set2_N92")


###
# Do IT!
###

vcat(T, "strategy: %s; resolution: %i", strategy, res)

for (si in 1:length(scans)) {
  # input functional paths
  if (res == 2) {
      flist <- file.path(subinfo, scan_folder[si], 
                         sprintf("%s_%s_funcpaths.txt", scans[si], strategy))
  } else {
      flist <- file.path(subinfo, scan_folder[si], 
                         sprintf("%s_%s_funcpaths_%imm.txt", scans[si], strategy, res))
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
}
