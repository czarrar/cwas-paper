#!/usr/bin/env Rscript

# Read in arg
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
    msg <- paste(
        "usage: 44_check_smooth.R resolution", 
        "resolution: integer resolution of resampled data", 
        sep="\n"
    )
    stop(msg)
}
res <- as.integer(args[1])


suppressPackageStartupMessages(library(connectir))
library(tools)


###
# General
###

# Paths
basedir <- "/home2/data/Projects/CWAS/share/ldopa"
subinfo <- file.path(basedir, "subinfo")


###
# Unsmoothed data
###

vcat(T, "resolution: %i", res)

# input functional paths
if (res == 2) {
  flist     <- file.path(subinfo, "02_all_funcpaths.txt")
  out_fwhm  <- file.path(subinfo, "04_all_fwhm.txt")
} else {
  flist     <- file.path(subinfo, sprintf("02_all_funcpaths_%imm.txt", res))
  out_fwhm  <- file.path(subinfo, sprintf("04_all_fwhm_%imm.txt", res))
}
raw <- read.table(flist)[,1]
infiles <- as.character(raw)
infiles <- sub("/home/", "/home2/", infiles)

# command
cmd <- "3dFWHMx -arith -mask %s -input %s"

# loop through
fwhm.mat <- sapply(infiles, function(infile) {
#vcat(T, "...%s", infile)
maskfile <- file.path(dirname(dirname(infile)), 
              sprintf("functional_brain_mask_to_standard_%imm.nii.gz", res))

real_cmd <- sprintf(cmd, maskfile, infile)
cat(real_cmd, "\n")
cmd_output <- system(real_cmd, intern=TRUE)
fwhms <- as.numeric(strsplit(sub("^[ ]", "", cmd_output), "[ ]+")[[1]])
print(fwhms)

return(fwhms)
})

vcat(T, "...saving file list")
write.table(fwhm.mat, file=out_fwhm, row.names=F, col.names=F)


####
## Smoothed data
####
#
#vcat(T, "resolution: %i", res)
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


####
## FWHM for FWHM smoothed data
####
#
#vcat(T, "resolution: %i", res)
#
#for (si in 1:length(scans)) {
#  # input functional paths
#  if (res == 2) {
#      flist <- file.path(subinfo, scan_folder[si], 
#                         sprintf("%s_%s_funcpaths_fwhm08.txt", scans[si], strategy))
#      out_fwhm <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_fwhm_fwhm08.txt", 
#                            scans[si], strategy))
#  } else {
#      flist <- file.path(subinfo, scan_folder[si], 
#                         sprintf("%s_%s_funcpaths_%imm_fwhm08.txt", scans[si], strategy, res))
#      out_fwhm <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_fwhm_%imm_fwhm08.txt", 
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
