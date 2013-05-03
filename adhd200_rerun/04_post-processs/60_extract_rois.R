#!/usr/bin/env Rscript

# This script will extract the time-series from each of the ROI sets


###
# Setup
###

library(connectir)

vcat(T, "CompCor")

rbase <- "/home2/data/Projects/CWAS/adhd200_rerun/rois"
mask_file <- file.path(rbase, "mask_gray_4mm.nii.gz")

#ks <- c(25,50,100,200,400,800,1600,3200)
ks <- c(3200)

sbase <- "/home2/data/Projects/CWAS/share/adhd200_rerun/subinfo"
func_files <- as.character(read.table(file.path(sbase, "30_compcor_funcpaths_4mm.txt"))[,1])

set_parallel_procs(nforks=1, nthreads=4)


###
# ROI Extraction (Random)
###

library(tools)

#roi_files <- file.path(rbase, sprintf("rois_random_k%04i.nii.gz", ks))
#
#for (roi_file in roi_files) {
#    cat(sprintf("ROI: %s\n", roi_file))
#    roi_base <- file_path_sans_ext(file_path_sans_ext(basename(roi_file)))
#    out_files <- sapply(func_files, function(func_file) {
#        out_file <- file.path(dirname(func_file), paste(roi_base, ".nii.gz", sep=""))
#        roi_mean_wrapper(func_file, roi_file, mask_file, out_file)
#        return(out_file)
#    })
#    out_files <- unlist(out_files)
#    ofile <- paste("z_compcor_", roi_base, ".txt", sep="")
#    write.table(out_files, file=ofile, row.names=F, col.names=F)
#}



###
# Setup
###

vcat(T, "Global")

func_files <- as.character(read.table(file.path(sbase, "30_global_funcpaths_4mm.txt"))[,1])


###
# ROI Extraction (Random)
###

library(tools)

roi_files <- file.path(rbase, sprintf("rois_random_k%04i.nii.gz", ks))

for (roi_file in roi_files) {
    cat(sprintf("ROI: %s\n", roi_file))
    roi_base <- file_path_sans_ext(file_path_sans_ext(basename(roi_file)))
    out_files <- sapply(func_files, function(func_file) {
        out_file <- file.path(dirname(func_file), paste(roi_base, ".nii.gz", sep=""))
        roi_mean_wrapper(func_file, roi_file, mask_file, out_file)
        return(out_file)
    })
    out_files <- unlist(out_files)
    ofile <- paste("z_global_", roi_base, ".txt", sep="")
    write.table(out_files, file=ofile, row.names=F, col.names=F)
}

