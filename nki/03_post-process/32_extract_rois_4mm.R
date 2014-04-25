#!/usr/bin/env Rscript

# This script will extract the time-series from each of the ROI sets


###
# Setup
###

library(connectir)
library(tools)

# Paths
basedir <- "/home2/data/Projects/CWAS/share/nki"
subinfo <- file.path(basedir, "subinfo")

# Scan stuff
scans <- c("short", "medium", "long")
scan_folder <- c("40_Set1_N104", "40_Set1_N104", "40_Set2_N92")

# Other
strategies <- c("compcor", "global")

# ROI stuff
rbase <- "/home2/data/Projects/CWAS/nki/rois"
mask_file <- file.path(rbase, "mask_gray_4mm.nii.gz")
ks <- c(25,50,100,200,400,800,1600,3200,6400)
#ks <- c(3200)
roi_files <- file.path(rbase, sprintf("rois_random_k%04i.nii.gz", ks))

set_parallel_procs(nforks=1, nthreads=4)


###
# ROI Extraction (Random) with compcor
###

strategy <- "compcor"
vcat(T, strategy)

for (si in 1:length(scans)) {
    # Paths to functionals
    fn <- file.path(subinfo, scan_folder[si], 
                    sprintf("%s_%s_funcpaths_4mm.txt", scans[si], strategy))
    func_files <- read.table(fn)[,1]
    func_files <- as.character(func_files)
    
    # Go through ROIs
    for (roi_file in roi_files) {
        vcat(T, "ROI: %s", roi_file)
        roi_base <- file_path_sans_ext(file_path_sans_ext(basename(roi_file)))
        out_files <- sapply(func_files, function(func_file) {
            out_file <- file.path(dirname(func_file), 
                                  paste(roi_base, ".nii.gz", sep=""))
            if (!file.exists(out_file)) {
                roi_mean_wrapper(func_file, roi_file, mask_file, out_file)
            }
            return(out_file)
        })
        out_files <- unlist(out_files)
        
        ofile <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_%s.txt", scans[si], strategy, roi_base))
        write.table(out_files, file=ofile, row.names=F, col.names=F)
    }
}



####
## ROI Extraction (Random) with global
####
#
#strategy <- "global"
#vcat(T, strategy)
#
#for (si in 1:length(scans)) {
#    # Paths to functionals
#    fn <- file.path(subinfo, scan_folder[si], 
#                    sprintf("%s_%s_funcpaths.txt", scans[si], strategy))
#    func_files <- read.table(fn)[,1]
#    func_files <- as.character(func_files)
#    
#    # Go through ROIs
#    for (roi_file in roi_files) {
#        vcat(T, "ROI: %s", roi_file)
#        roi_base <- file_path_sans_ext(file_path_sans_ext(basename(roi_file)))
#        out_files <- sapply(func_files, function(func_file) {
#            out_file <- file.path(dirname(func_file), paste(roi_base, ".nii.gz", sep=""))
#            roi_mean_wrapper(func_file, roi_file, mask_file, out_file)
#            return(out_file)
#        })
#        out_files <- unlist(out_files)
#        
#        ofile <- file.path(subinfo, scan_folder[si], sprintf("%s_%s_%s.txt", scans[si], strategy, roi_base))
#        write.table(out_files, file=ofile, row.names=F, col.names=F)
#    }
#}



