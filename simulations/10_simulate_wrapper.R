#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(niftir))
suppressPackageStartupMessages(library(connectir))


vcat        <- function(msg, ...) cat(sprintf(msg, ...), "\n")

njobs       <- 60
nthreads    <- 4
#k           <- 200
#k           <- 800
k           <- 1600

# Get the total number of voxels
subdir  <- "/home2/data/Projects/CWAS/share/nki/subinfo/40_Set1_N104"
fpaths  <- read.table(file.path(subdir, sprintf("short_compcor_rois_random_k%04i.txt", k)))
fpaths  <- as.character(fpaths[,1])
dat     <- read.nifti.image(fpaths[1])

nsubs   <- length(fpaths)
nvoxs   <- ncol(dat)
ntpts   <- nrow(dat)
nperms  <- 5000

# How to divide the jobs
vox.inds <- niftir.split.indices(1, nvoxs, length.out=njobs)

# Check Memory limits
## Subject Distances
opts <- list(verbose=T, blocksize=0, superblocksize=0, memlimit=8)
opts <- get_subdist_memlimit(opts, nsubs, nvoxs, ntpts)
if (opts$blocksize != nvoxs & opts$superblocksize != nvoxs) stop("will exceed memory limit for distances")
## MDMR
opts <- list(verbose=T, blocksize=0, superblocksize=0, memlimit=8)
opts <- get_mdmr_memlimit(opts, nsubs, nvoxs, nperms, nfactors=1)
if (opts$blocksize != nperms & opts$superblocksize != nvoxs) stop("will exceed memory limit for mdmr")
## We good?
cat("memory will be good\n")

# Directories
dir.create("qsub_logs", showWarnings=FALSE)
dir.create("qsub_scripts", showWarnings=FALSE)
dir.create(sprintf("/home2/data/Projects/CWAS/simulations/k%04i", k))

for (i in 1:vox.inds$n) {
    start.vox   <- vox.inds$starts[i]
    end.vox     <- vox.inds$ends[i]
    
    # Paths
    log.file    <- sprintf('qsub_logs/simulate_k%04i_%04i-%04i.log', k, start.vox, end.vox)
    script.file <- sprintf('qsub_scripts/simulate_k%04i_%04i-%04i.bash', k, start.vox, end.vox)

    # Write script
    cmd         <- sprintf("./10_simulate_real_data.R %i %i %i %i", k, start.vox, end.vox, nthreads)
    sfile       <- "#!/usr/bash\n"
    sfile       <- paste(sfile, cmd, sep="\n")
    cat(sfile, "\n", file=script.file)

    # Call
    qcmd        <- sprintf("qsub -S /bin/bash -pe mpi %i -V -cwd -o %s -j y %s", nthreads, log.file, script.file)
    vcat(qcmd)
    system(qcmd)
}

