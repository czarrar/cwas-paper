#!/usr/bin/env Rscript

# extract's the time-series from the brain-image
vcat <- function(msg, ...) cat(sprintf(msg, ...), "\n")


####


vcat("\nRead in user args")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) stop("\nusage: 32_extract_ts.R func-file ts-file num-threads")

func.file <- as.character(args[1])
ts.file   <- as.character(args[2])
nthreads  <- as.numeric(args[3])

Sys.setenv(OMP_NUM_THREADS=nthreads)


####


vcat("\nRead input filenames and create/save output filenames")

func.mask  <- file.path(dirname(dirname(func.file)), 
                         "functional_brain_mask_to_standard.nii.gz")
sca.dir    <- file.path(dirname(func.file), "sca")
sca.file   <- file.path(sca.dir, "peaks100_2mm.nii.gz")


####


vcat("\nChecking input/output files")
    
if (!file.exists(func.file) || !file.exists(ts.file) || !file.exists(func.mask)) {
    vcat("...input doesn't exist")
    next
}
    
if (file.exists(sca.file)) {
    vcat("...output already exists (removing)")
    file.remove(sca.file)
    #next
}


####


vcat("\nGenerating SCA map(s)")

raw.cmd <- "3dTcorr1D -pearson -mask %s -float -prefix %s %s %s"
    
dir.create(dirname(sca.file), FALSE)
cmd <- sprintf(raw.cmd, func.mask, sca.file, func.file, ts.file)
vcat(cmd)
ret <- system(cmd)
print(ret)
