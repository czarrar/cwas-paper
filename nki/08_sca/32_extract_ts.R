#!/usr/bin/env Rscript

# extract's the time-series from the brain-image
vcat <- function(msg, ...) cat(sprintf(msg, ...), "\n")

####


vcat("\nRead in user args")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("\nusage: 32_extract_ts.R [1 | 2 | 3]\n1=short, 2=medium, 3=long")

i <- as.numeric(args[1])

scans <- c("short", "medium", "long")
sets  <- c("40_Set1_N104", "40_Set1_N104", "40_Set2_N92")

scan <- scans[i]
set  <- sets[i]


####


vcat("\nSet paths/settings")

strategy <- "compcor"

basedir   <- "/home2/data/Projects/CWAS"
subdir    <- file.path(basedir, "share/nki/subinfo", set)
func.list <- file.path(subdir, sprintf("%s_%s_funcpaths.txt", scan, strategy))
ts.list   <- file.path(subdir, sprintf("%s_%s_ts_peaks100_2mm.txt", scan, strategy))
roi.file  <- file.path(basedir, "nki/sca/seeds/rois_2mm.nii.gz")


####


vcat("\nRead input filenames and create/save output filenames")

func.files  <- as.character(read.table(func.list)[,1])
ts.dirs     <- file.path(dirname(func.files), "ts")
ts.files    <- file.path(ts.dirs, "peaks100_2mm.1d")

write.table(ts.files, row.names=F, col.names=F, file=ts.list)


####


vcat("\nLooping through ")

raw.cmd <- "3dROIstats -mask %s -quiet %s > %s"

for (i in 1:length(func.files)) {
    func.file <- func.files[i]
    ts.file   <- ts.files[i]
    
    if (file.exists(ts.file)) {
        file.remove(ts.file)
        #vcat("...output %s already exists", ts.file)
        #next
    }
    
    dir.create(dirname(ts.file), FALSE)
    cmd       <- sprintf(raw.cmd, roi.file, func.file, ts.file)
    vcat(cmd)
    ret       <- system(cmd)
}
