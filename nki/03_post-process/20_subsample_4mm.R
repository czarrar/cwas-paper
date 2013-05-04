#!/usr/bin/env Rscript

# This script will resample the 2mm data into 4mm for analyses

library(connectir)


###
# General
###

# Paths
basedir <- "/home2/data/Projects/CWAS/share/nki"
subinfo <- file.path(basedir, "subinfo")

# Scan stuff
scans <- c("short", "medium", "long")
scan_folder <- c("40_Set1_N104", "40_Set1_N104", "40_Set2_N92")

# Other
strategies <- c("compcor", "global")


###
# COMPCOR LIFE
###

strategy <- "compcor"
vcat(T, strategy)

for (si in 1:length(scans)) {
  # 1. input functional paths
  flist <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_funcpaths.txt", scans[si], strategy))
  raw <- read.table(flist)[,1]
  infiles <- as.character(raw)
  infiles <- sub("/home/", "/home2/", infiles)
  
  # 2. 4mm resolution brain (i.e., the master)
  stdfile <- "/home2/data/PublicProgram/fsl-4.1.9/data/standard/MNI152_T1_4mm_brain.nii.gz"
  
  # 3. command
  cmd <- "3dresample -inset %s -master %s -rmode Linear -prefix %s"
  
  # outfiles <- file.path(dirname(infiles), "functional_mni_4mm.nii.gz")
  
  for (infile in infiles) {
    #vcat(T, "...%s", infile)
    outfile <- file.path(dirname(infile), "functional_mni_4mm.nii.gz")
    if (file.exists(outfile))
      file.remove(outfile)
    real_cmd <- sprintf(cmd, infile, stdfile, outfile)
    
    cat(real_cmd, "\n")
    system(real_cmd)
  }
}



####
## Below is the regular version (GLOBAL)
####
#
#strategy <- "global"
#vcat(T, strategy)
#
#for (si in 1:length(scans)) {
#  # 1. input functional paths
#  flist <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_funcpaths.txt", scans[si], strategy))
#  raw <- read.table(flist)[,1]
#  infiles <- as.character(raw)
#  infiles <- sub("/home/", "/home2/", infiles)
#  
#  # 2. 4mm resolution brain (i.e., the master)
#  stdfile <- "/home2/data/PublicProgram/fsl-4.1.9/data/standard/MNI152_T1_4mm_brain.nii.gz"
#  
#  # 3. command
#  cmd <- "3dresample -inset %s -master %s -rmode Linear -prefix %s"
#  
#  # outfiles <- file.path(dirname(infiles), "functional_mni_4mm.nii.gz")
#  
#  for (infile in infiles) {
#    #vcat(T, "...%s", infile)
#    outfile <- file.path(dirname(infile), "functional_mni_4mm.nii.gz")
#    if (file.exists(outfile))
#      file.remove(outfile)
#    real_cmd <- sprintf(cmd, infile, stdfile, outfile)
#    
#    cat(real_cmd, "\n")
#    system(real_cmd)
#  }
#}
