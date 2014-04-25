#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(connectir))
library(tools)


# Read in arg
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
    msg <- paste(
        "usage: 44_check_smooth.R strategy resolution", 
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


###
# Unsmoothed data
###

#vcat(T, "strategy: %s; resolution: %i", strategy, res)
#
#for (si in 1:length(scans)) {
#  # input functional paths
#  if (res == 2) {
#      flist <- file.path(subinfo, scan_folder[si], 
#                         sprintf("%s_%s_funcpaths.txt", scans[si], strategy))
#      out_fwhm <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_fwhm.txt", 
#                            scans[si], strategy))
#  } else {
#      flist <- file.path(subinfo, scan_folder[si], 
#                         sprintf("%s_%s_funcpaths_%imm.txt", scans[si], strategy, res))
#      out_fwhm <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_fwhm_%imm.txt", 
#                            scans[si], strategy, res))
#  }
#  raw <- read.table(flist)[,1]
#  infiles <- as.character(raw)
#  infiles <- sub("/home/", "/home2/", infiles)
#  
#  # command
#  cmd <- "3dFWHMx -mask %s -input %s"
#  
#  # loop through
#  fwhm.mat <- sapply(infiles, function(infile) {
#    #vcat(T, "...%s", infile)
#    maskfile <- file.path(dirname(dirname(infile)), 
#                  sprintf("functional_brain_mask_to_standard_%imm.nii.gz", res))
#    
#    real_cmd <- sprintf(cmd, maskfile, infile)
#    cat(real_cmd, "\n")
#    cmd_output <- system(real_cmd, intern=TRUE)
#    fwhms <- as.numeric(strsplit(sub("^[ ]", "", cmd_output), "[ ]+")[[1]])
#    
#    return(fwhms)
#  })
#  
#  vcat(T, "...saving file list")
#  write.table(fwhm.mat, file=out_fwhm, row.names=F, col.names=F)
#}
#
#
####
## Smoothed data
####
#
#vcat(T, "strategy: %s; resolution: %i", strategy, res)
#
#for (si in 1:length(scans)) {
#  # input functional paths
#  if (res == 2) {
#      flist <- file.path(subinfo, scan_folder[si], 
#                         sprintf("%s_%s_funcpaths_smoothed.txt", scans[si], strategy))
#      out_fwhm <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_fwhm_smoothed.txt", 
#                            scans[si], strategy))
#  } else {
#      flist <- file.path(subinfo, scan_folder[si], 
#                         sprintf("%s_%s_funcpaths_%imm_smoothed.txt", scans[si], strategy, res))
#      out_fwhm <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_fwhm_%imm_smoothed.txt", 
#                            scans[si], strategy, res))
#  }
#  raw <- read.table(flist)[,1]
#  infiles <- as.character(raw)
#  infiles <- sub("/home/", "/home2/", infiles)
#  
#  # command
#  cmd <- "3dFWHMx -mask %s -input %s"
#  
#  # loop through
#  fwhm.mat <- sapply(infiles, function(infile) {
#    #vcat(T, "...%s", infile)
#    maskfile <- file.path(dirname(dirname(infile)), 
#                  sprintf("functional_brain_mask_to_standard_%imm.nii.gz", res))
#    
#    real_cmd <- sprintf(cmd, maskfile, infile)
#    cat(real_cmd, "\n")
#    cmd_output <- system(real_cmd, intern=TRUE)
#    fwhms <- as.numeric(strsplit(sub("^[ ]", "", cmd_output), "[ ]+")[[1]])
#    
#    return(fwhms)
#  })
#  
#  vcat(T, "...saving file list")
#  write.table(fwhm.mat, file=out_fwhm, row.names=F, col.names=F)
#}


###
# FWHM for FWHM smoothed data
###

vcat(T, "strategy: %s; resolution: %i", strategy, res)

for (si in 1:length(scans)) {
  # input functional paths
  if (res == 2) {
      flist <- file.path(subinfo, scan_folder[si], 
                         sprintf("%s_%s_funcpaths_fwhm08.txt", scans[si], strategy))
      out_fwhm <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_fwhm_fwhm08.txt", 
                            scans[si], strategy))
  } else {
      flist <- file.path(subinfo, scan_folder[si], 
                         sprintf("%s_%s_funcpaths_%imm_fwhm08.txt", scans[si], strategy, res))
      out_fwhm <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_fwhm_%imm_fwhm08.txt", 
                            scans[si], strategy, res))
  }
  raw <- read.table(flist)[,1]
  infiles <- as.character(raw)
  infiles <- sub("/home/", "/home2/", infiles)
  
  # command
  cmd <- "3dFWHMx -mask %s -input %s"
  
  # loop through
  fwhm.mat <- sapply(infiles, function(infile) {
    #vcat(T, "...%s", infile)
    maskfile <- file.path(dirname(dirname(infile)), 
                  sprintf("functional_brain_mask_to_standard_%imm.nii.gz", res))
    
    real_cmd <- sprintf(cmd, maskfile, infile)
    cat(real_cmd, "\n")
    cmd_output <- system(real_cmd, intern=TRUE)
    fwhms <- as.numeric(strsplit(sub("^[ ]", "", cmd_output), "[ ]+")[[1]])
    
    return(fwhms)
  })
  
  vcat(T, "...saving file list")
  write.table(fwhm.mat, file=out_fwhm, row.names=F, col.names=F)
}
