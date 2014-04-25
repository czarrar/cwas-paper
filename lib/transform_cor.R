#!/usr/bin/env Rscript

# What we want here is to take the original subject distances (1-r)
# then transform to be a metric (sqrt(2*(1-r)))
# and resave.
# We take these new distances
# and redo the gower centering
# and resave.


## Arguments

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3) {
    cat("./transform_cor.R distances-descriptor memlimit nthreads\n")
    sys.exit()
} else {
    sdist_path  <- args[1]
    memlimit    <- as.numeric(args[2])
    nthreads    <- as.numeric(args[3])
}


## Transform

transform_sdist <- function(sdist_path, memlimit, nthreads) {
    library(connectir)
    set_parallel_procs(1, nthreads, TRUE)

    print(sdist_path)
    print(memlimit)
    print(nthreads)

    
    ###
    # Distances
    ###

    cat("Distances\n")

    old_sdist   <- attach.big.matrix(sdist_path)

    base        <- dirname(sdist_path)
    nsubs       <- sqrt(nrow(old_sdist))
    nvoxs       <- ncol(old_sdist)

    # I am not sure about the memory load (hope it's fine)
    tmp         <- sqrt(2*old_sdist[,])
    tmp[is.na(tmp)] <- 0
    new_sdist   <- as.big.matrix(tmp, 
                                backingpath=base, 
                                backingfile="subdist_transform.bin", 
                                descriptorfile="subdist_transform.desc")
    rm(old_sdist); rm(tmp); gc()


    ###
    # Gower Centering
    ###

    cat("Gowerify\n")
    
    opts <- list(verbose=TRUE, memlimit=memlimit, blocksize=0, superblocksize=0)
    opts <- get_subdist_memlimit(opts, nsubs, nvoxs, rep(100, nsubs), nvoxs)

    cat("...removing prior gower matrix\n")
    file.remove(file.path(base, "subdist_gower.bin"))
    file.remove(file.path(base, "subdist_gower.desc"))

    cat("...compute gower business\n")
    gdist       <- gower.subdist2(new_sdist, 
                                    blocksize=opts$blocksize, 
                                    backingpath=base, 
                                    backingfile="subdist_gower.bin", 
                                    descriptorfile="subdist_gower.desc")

    cat("...clean\n")
    rm(gdist); gc()
}

transform_sdist(sdist_path, memlimit, nthreads)
