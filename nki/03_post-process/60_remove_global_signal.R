#!/usr/bin/env Rscript

# For each subject, this script will
# 1. read in the time-series data
# 2. extract the global signal
# 3. save the global signal
# 4. regress out the global signal
# 5. save the new GSR corrected functional

suppressPackageStartupMessages(library(connectir))
library(biganalytics)
library(tools)


# Read in arg
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
    msg <- paste(
        "usage: 60_remove_global_signal.R scan", 
        "scan: short, medium, or long", 
        sep="\n"
    )
    stop(msg)
}
scan <- as.character(args[1])

if (!(scan %in% c("short", "medium", "long"))) {
    stop("incorrect argument")
} else {
    cat(sprintf("Running scan: %s\n", scan))
}

subdir  <- "/home2/data/Projects/CWAS/share/nki/subinfo/40_Set1_N104"
pathsfile <- file.path(subdir, sprintf("%s_compcor_funcpaths_4mm_fwhm08.txt", scan))
funcfiles <- as.character(read.table(pathsfile)[,])

# Main function where all the magic happens
remove_global_signal <- function(funcfile, overwrite=F) {
    # 0. Background
    cat("...background\n")
    funcname <- sub(".nii.gz", "", basename(funcfile))
    funcdir  <- dirname(funcfile)
    maskfile <- file.path(dirname(funcdir), "functional_brain_mask_to_standard_4mm.nii.gz")
    tsdir    <- file.path(funcdir, "ts")
    gsrts    <- file.path(tsdir, "global.1d")
    gsrfile  <- file.path(funcdir, sprintf("%s_global.nii.gz", funcname))
    
    if (file.exists(gsrfile)) {
        if (overwrite) {
            cat("...overwriting existing file\n")
            file.remove(gsrfile)
        } else {
            cat("...skipping since it already exists\n")
        }
    }
    
    # 1. Read in the time-series data
    cat("...read\n")
    func <- read.big.nifti4d(funcfile)
    mask <- read.mask(maskfile)
    func_masked <- do.mask(func, mask)
    rm(func)

    # 2. Extract the global signal
    cat("...extract\n")
    gsr_ts <- rowMeans(func_masked[,])

    # 3. Save global
    cat("...save global ts\n")
    write.table(gsr_ts, row.names=F, col.names=F, quote=F, file=gsrts)

    # 4. Regress out global
    cat("...regress out global\n")
    X <- cbind(rep(1,length(gsr_ts)), gsr_ts)
    X <- as.big.matrix(X)
    resids <- qlm_residuals(func_masked, X)

    # 5. Save new global corrected file
    cat("...save new file\n")
    resids <- as.big.nifti4d(resids, func_masked@header, func_masked@mask)
    resids@header$fname <- gsrfile; resids@header$iname <- gsrfile
    write.nifti(resids, outfile=gsrfile)    
}

for (funcfile in funcfiles) {
    cat(sprintf("Running: %s\n", funcfile))
    remove_global_signal(funcfile)
}
