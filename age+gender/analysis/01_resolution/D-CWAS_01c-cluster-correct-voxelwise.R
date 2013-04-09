#!/usr/bin/env Revoscript

# Cluster corrects MDMR results

library(connectir)
library(Rsge)

basedir <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"

vthr <- 0.05    # voxel-threshold
cthr <- 0.05    # cluster-threshold

nforks <- 4
nthreads <- 2
parallel <- nforks > 1
sge.options(sge.user.options = sprintf("-S /bin/bash -pe mpi_smp %i", nthreads*nforks))

# MDMR Dirs
mdmr.dir <- file.path(basedir, "voxelwise", "age+gender_with-meanFD_15k.mdmr")

# F-Stats
fsfiles <- list.files(mdmr.dir, pattern='^fperms_.*.desc', full.names=T)
fsfiles <- unlist(fsfiles)
njobs <- length(fsfiles)

# 

clusts <- sge.parLapply(fsfiles, function(fsfile) {
    set_parallel_procs(nforks, nthreads, force=TRUE)
    
    # Needed Paths
    mdmr.dir <- dirname(fsfile)
    sdist.dir <- dirname(mdmr.dir)
    maskfile <- file.path(sdist.dir, "mask.nii.gz")
    oname <- sub("fperms_", "", basename(fsfile))
    oname <- sub(".desc", "", oname)
    
    # Cluster
    clust <- clust_mdmr.correct_wrapper(mdmr.dir, oname, 
                                maskfile, fsfile, vox.thresh=vthr, 
                                clust.thresh=cthr, clust.type="mass", 
                                parallel=parallel)
    
    return(clust)
}, packages=c("connectir"), function.savelist=ls(), njobs=njobs)

