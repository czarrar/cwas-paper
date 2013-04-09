# This script will extract the time-series from the ROI sets defined in 01_resolution


###
# Setup
###

library(Rsge)
library(tools)

tmpdf <- read.csv("subinfo/04_all_df.csv")
njobs <- nrow(tmpdf)    # number of jobs = number of subjects
nthreads <- 1
nforks <- 100

rbase <- "/home2/data/Projects/CWAS/share/age+gender/analysis/03_robustness/rois"
mask_file <- file.path(rbase, "mask_for_age+sex_gray_4mm.nii.gz")

ks <- c(25,50,100,200,400,800,1600,3200)

func_files <- as.character(read.table("subinfo/04_all_funcpaths_4mm.txt")[,1])



###
# ROI Extraction (Random)
###

roi_files <- file.path(rbase, sprintf("rois_random_k%04i.nii.gz", ks))

for (roi_file in roi_files) {
    
    cat(sprintf("ROI: %s\n", roi_file))
    
    # Get the name of the ROI
    roi_base <- file_path_sans_ext(file_path_sans_ext(basename(roi_file)))
    
    # Loop through functionals
    
    ## to output nifti object
    out_files <- sge.parLapply(func_files, function(func_file) {
        set_parallel_procs(1, 1)
        out_file <- file.path(dirname(func_file), paste(roi_base, ".nii.gz", sep=""))
        roi_mean_wrapper(func_file, roi_file, mask_file, out_file)
        return(out_file)
    }, packages=c("connectir"), function.savelist=ls(), njobs=njobs)
    out_files <- unlist(out_files)
    ofile <- paste("z_", roi_base, "_nifti.txt", sep="")
    write.table(out_files, file=ofile, row.names=F, col.names=F)
    
    ### to output text object
    #out_files <- sge.parLapply(out_files, function(in_file) {
    #    img <- read.nifti.image(in_file)
    #    set_parallel_procs(1, 1)
    #    out_file <- file.path(dirname(func_file), paste(roi_base, ".1D", sep=""))
    #    roi_mean_wrapper(func_file, roi_file, mask_file, out_file)
    #    return(out_file)
    #}, packages=c("connectir"), function.savelist=ls(), njobs=njobs)
    #out_files <- unlist(out_files)
    #ofile <- paste("z_", roi_base, "_1D.txt", sep="")
    #write.table(out_files, file=ofile, row.names=F, col.names=F)
    
}


