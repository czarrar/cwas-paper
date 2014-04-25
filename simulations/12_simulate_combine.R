#!/usr/bin/env Rscript


###
# Setup
###

cat("Setup\n")

suppressPackageStartupMessages(library(niftir))
suppressPackageStartupMessages(library(connectir))

vcat    <- function(msg, ...) cat(sprintf(msg, ...), "\n")

k       <- 1600
indir   <- sprintf("/home2/data/Projects/CWAS/simulations/k%04i", k)
files   <- list.files(indir, pattern="rda$", full.names=T)
n       <- length(files)

# Get the total number of voxels
subdir  <- "/home2/data/Projects/CWAS/share/nki/subinfo/40_Set1_N104"
fpaths  <- read.table(file.path(subdir, sprintf("short_compcor_rois_random_k%04i.txt", k)))
fpaths  <- as.character(fpaths[,1])
dat     <- read.nifti.image(fpaths[1])
nvoxs   <- ncol(dat)
rm(dat)

# Load only the first set of voxels for info purposes
load(files[1])
p       <- length(ret)

# Beginning/Ending of Voxel Blocks
start.voxs  <- as.numeric(substr(basename(files), 6, 9))
end.voxs    <- as.numeric(substr(basename(files), 11, 14))

# For saving
obase       <- "/home2/data/Projects/CWAS/simulations/results"
oprefix     <- file.path(obase, sprintf("k%04i", k))
oprefix0    <- sprintf("k%04i", k)
dir.create(obase, showWarnings=F)


###
# Data Frame with Basics
###

# Setup information about our two factors
# - effect sizes
# - number of nodes changed

cat("Data Frame\n")

opts    <- data.frame(
    i = rep(0,p), 
    effect = rep(0,p), 
    num_nodes_to_change = rep(0,p)
)

for (i in 1:p) {
    opts$i[i] <- ret[[i]]$i
    opts$effect[i] <- ret[[i]]$effect
    opts$num_nodes_to_change[i] <- ret[[i]]$num_nodes_to_change
}

write.csv(opts, file=paste(oprefix, "_opts.csv", sep=""))


###
# Matrices for Data
###

cat("Matrices\n")

mdmr    <- big.matrix(nvoxs, p, backingpath=obase, backingfile=paste(oprefix0, "_mdmr.bin", sep=""), descriptorfile=paste(oprefix0, "_mdmr.desc", sep=""))
glm     <- big.matrix(nvoxs, p, backingpath=obase, backingfile=paste(oprefix0, "_glm.bin", sep=""), descriptorfile=paste(oprefix0, "_glm.desc", sep=""))
glm.tp  <- big.matrix(nvoxs, p, backingpath=obase, backingfile=paste(oprefix0, "_glm_tp.bin", sep=""), descriptorfile=paste(oprefix0, "_glm_tp.desc", sep=""))
glm.fp  <- big.matrix(nvoxs, p, backingpath=obase, backingfile=paste(oprefix0, "_glm_fp.bin", sep=""), descriptorfile=paste(oprefix0, "_glm_fp.desc", sep=""))

l_ply(1:n, function(i) {
    s <- start.voxs[i]; e <- end.voxs[i]
    cat(i, "/", n, ", voxs:", s, "-", e, "\n")
    load(files[i])  # load file
    
    l_ply(1:p, function(j) {
        mdmr[s:e,j]     <- ret[[j]]$mdmr
        glm[s:e,j]      <- ret[[j]]$glm
        glm.tp[s:e,j]   <- ret[[j]]$glm.tp
        glm.fp[s:e,j]   <- ret[[j]]$glm.fp
    }, .progress="text")
})


