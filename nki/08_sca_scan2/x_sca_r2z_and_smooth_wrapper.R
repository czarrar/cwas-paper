#!/usr/bin/env Rscript

# extract's the time-series from the brain-image
vcat <- function(msg, ...) cat(sprintf(msg, ...), "\n")

Sys.setenv(OMP_NUM_THREADS=6)


####


vcat("\nRead in user args")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) 
    stop("\nusage: 37...R [1 | 2 | 3] [fwhm]\n1=short, 2=medium, 3=long")

i <- as.integer(args[1])
fwhm <- as.integer(args[2])

scans <- c("short", "medium", "long")
sets  <- c("40_Set1_N104", "40_Set1_N104", "40_Set2_N92")

scan <- scans[i]
set  <- sets[i]

# library for parallel processing
library(fork)
library(plyr)
ncores <- 6


####


vcat("\nSet paths/settings")

strategy <- "compcor"

basedir   <- "/home2/data/Projects/CWAS"
subdir    <- file.path(basedir, "share/nki/subinfo", set)
func.list <- file.path(subdir, sprintf("%s_%s_funcpaths.txt", scan, strategy))
ts.list   <- file.path(subdir, sprintf("%s_%s_ts_peaks84_2mm.txt", scan, strategy))
sca.list  <- file.path(subdir, sprintf("%s_%s_sca_peaks84_2mm.txt", scan, strategy))


####


vcat("\nRead input filenames and create/save output filenames")

func.files  <- as.character(read.table(func.list)[,1])
ts.files    <- as.character(read.table(ts.list)[,1])
func.masks  <- file.path(dirname(dirname(func.files)), 
                         "functional_brain_mask_to_standard.nii.gz")
sca.dirs    <- file.path(dirname(func.files), "sca")
sca.files   <- file.path(sca.dirs, "peaks84_2mm.nii.gz")


if (!all(file.exists(func.masks))) stop("not all func masks exist")


####


vcat("\nLooping through ")

df <- data.frame(
    index   = 1:length(func.files), 
    procs   = scut(1:length(func.files), ncors), 
    mask    = func.masks,
    sca     = sca.files
)

d_ply(df, .(procs), function(sdf) {
    run_cmds <- function() {
        d_ply(sdf, .(index), function(row) {
            func.mask <- row$mask
            sca.file  <- row$sca
            log.file  <- file.path(dir.name(sca.file), "peaks84_r2z_and_smooth.log")
            
            if (!file.exists(func.mask) || !file.exists(sca.file)) {
                vcat("...input doesn't exist")
                next
            }
            
            raw.cmd     <- "./36_sca_r2z_and_smooth.py %s %s %s > %s"
            cmd         <- sprintf(raw.cmd, sca.file, func.mask, fwhm, log.file)
            vcat(cmd)
            system(cmd)
            vcat("----")
        })
    }
    vcat("running proc %i", sdf$procs[1])
    pid <- fork(run_cmds)
    print(wait(pid))
})
