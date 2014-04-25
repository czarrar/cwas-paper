#!/usr/bin/env Rscript

# This script will resample the 2mm data into Xmm for analyses
# does this across the three scans: short, medium, long

suppressPackageStartupMessages(library(connectir))

# Read in arg
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
    msg <- paste(
        "usage: 22_subsample_to_Xmm.R strategy resolution", 
        "strategy: compcor or global", 
        "resolution: integer resolution of resampled data", 
        sep="\n"
    )
    stop(msg)
}
strategy <- as.character(args[1])
res <- as.integer(args[2])

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

# Standard
fsldir <- "/home2/data/PublicProgram/fsl-4.1.9"
stdfile <- file.path(
    fsldir, 
    sprintf("data/standard/MNI152_T1_%imm_brain.nii.gz", res)
)
if (!file.exists(stdfile)) stop("standard/master file doesn't exist")


###
# Do IT!
###

vcat(T, "strategy: %s; resolution: %i", strategy, res)

for (si in 1:length(scans)) {
  # 1. input functional paths
  flist <- file.path(subinfo, scan_folder[si], 
                     sprintf("%s_%s_funcpaths.txt", scans[si], strategy))
  raw <- read.table(flist)[,1]
  infiles <- as.character(raw)
  infiles <- sub("/home/", "/home2/", infiles)
  
  # 2. standard resolution brain (i.e., the master)
  
  # 3. command
  cmd <- "3dresample -inset %s -master %s -rmode Linear -prefix %s"
  
  # outfiles <- file.path(dirname(infiles), "functional_mni_4mm.nii.gz")
  
  for (infile in infiles) {
    #vcat(T, "...%s", infile)
    outfile <- file.path(dirname(infile), sprintf("functional_mni_%imm.nii.gz", res))
    if (file.exists(outfile)) {
        vcat(T, "exists: %s", outfile)
    } else {
        real_cmd <- sprintf(cmd, infile, stdfile, outfile)
        cat(real_cmd, "\n")
        system(real_cmd)
    }
  }
}
