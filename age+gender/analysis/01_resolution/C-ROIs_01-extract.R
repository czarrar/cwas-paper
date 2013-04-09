# This script will extract the time-series from each of the ROI sets

###
# Setup
###

library(Rsge)
library(tools)

tmpdf <- read.csv("z_details.csv")
njobs <- nrow(tmpdf)    # number of jobs = number of subjects
nthreads <- 1
nforks <- 100

rbase <- "/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution/rois"
mask_file <- file.path(rbase, "mask_4mm.nii.gz")

ks <- c(25,50,100,200,400,800,1600,3200,6400)

func_files <- as.character(read.table("z_funcpaths_4mm.txt")[,1])


####
## ROI Extraction (Derived)
####
#
#roi_files <- file.path(rbase, sprintf("rois_k%04i.nii.gz", ks))
#
#for (roi_file in roi_files) {
#    cat(sprintf("ROI: %s\n", roi_file))
#    roi_base <- file_path_sans_ext(file_path_sans_ext(basename(roi_file)))
#    out_files <- sge.parLapply(func_files, function(func_file) {
#        set_parallel_procs(1, 1)
#        out_file <- file.path(dirname(func_file), paste(roi_base, ".nii.gz", sep=""))
#        roi_mean_wrapper(func_file, roi_file, mask_file, out_file)
#        return(out_file)
#    }, packages=c("connectir"), function.savelist=ls(), njobs=njobs)
#    out_files <- unlist(out_files)
#    ofile <- paste("z_", roi_base, ".txt", sep="")
#    write.table(out_files, file=ofile, row.names=F, col.names=F)
#}


###
# ROI Extraction (Random)
###

roi_files <- file.path(rbase, sprintf("rois_random_k%04i.nii.gz", ks))

for (roi_file in roi_files) {
    cat(sprintf("ROI: %s\n", roi_file))
    roi_base <- file_path_sans_ext(file_path_sans_ext(basename(roi_file)))
    out_files <- sge.parLapply(func_files, function(func_file) {
        set_parallel_procs(1, 1)
        out_file <- file.path(dirname(func_file), paste(roi_base, ".nii.gz", sep=""))
        roi_mean_wrapper(func_file, roi_file, mask_file, out_file)
        return(out_file)
    }, packages=c("connectir"), function.savelist=ls(), njobs=njobs)
    out_files <- unlist(out_files)
    ofile <- paste("z_", roi_base, ".txt", sep="")
    write.table(out_files, file=ofile, row.names=F, col.names=F)
}

