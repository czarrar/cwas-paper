#!/home2/data/PublicProgram/R/bin/Rscript --vanilla

# This script will extract the time-series for each of the 380 ROIs

library(Rsge)
library(niftir)

# Paths to 4D Functional Images
paths.discovery <- as.character(read.table("../subinfo/04_discovery_funcpaths.txt")[,1])
paths.replication <- as.character(read.table("../subinfo/04_replication_funcpaths.txt")[,1])
paths <- c(paths.discovery, paths.replication)
paths <- gsub("/home/", "/home2/", paths)

# ROIs/Mask
rois <- read.nifti.image("rois_380.nii.gz")
mask <- rois>0
rois <- rois[mask]
urois <- sort(unique(rois))

# Extract Time-Series
roi_paths <- sge.parSapply(paths, function(func_path) {
    roi_path <- sub("functional_mni.nii.gz", "rois380.1D", func_path)
    func <- read.big.nifti4d(func_path)
    func_masked <- do.mask(func, mask)
    roi_ts <- sapply(urois, function(ui) rowMeans(func_masked[,rois==ui]))
    write.table(roi_ts, file=roi_path, quote=F, row.names=F, col.names=F)
    roi_ts
}, njobs=48, packages=c("niftir"), function.savelist=ls())
roi_paths <- gsub("functional_mni.nii.gz", "rois380.1D", paths)

