zdist <- function(mat, method="cor") {
    switch(method, 
        cor = 1 - corr(mat), 
        stop("Unsupported method for zdist")
    )
}

vcat <- function(verbose, msg, ..., newline=TRUE) {
    if (verbose) {
        cat(sprintf(msg, ...))
        if (newline) cat("\n")
    }
}

vstop <- function(msg, ...) stop(sprintf(msg, ...))

vsystem <- function(verbose, cmd, ...) {
    vcat(verbose, cmd, ...)
    ret <- system(sprintf(cmd, ...))
    if (ret != 0)
        stop("command failed")
}

set_parallel_procs <- function(nforks=1, nthreads=1, verbose=FALSE) {
    is.installed <- function(mypkg) is.element(mypkg, installed.packages()[,1]) 
  
    vcat(verbose, "Setting %i parallel forks", nforks)
    suppressPackageStartupMessages(library("doMC"))
    registerDoMC()
    nprocs <- getDoParWorkers()
    if (nforks > nprocs) {
        vstop("# of forks %i is greater than the actual # of processors (%i)", 
              nforks, nprocs)
    }
    options(cores=nforks)
    
    vcat(verbose, "Setting %i threads for matrix algebra operations", 
         nthreads)
    #nprocs <- omp_get_max_threads()
    if (nthreads > nprocs) {
        vstop("# of threads %i is greater than the actual # of processors (%i)", 
              nthreads, nprocs)
    }
    
    if (existsFunction("setMKLthreads", where=topenv(.GlobalEnv))) {
        vcat(verbose, "...using Intel's MKL")
        setMKLthreads(nthreads)
    } else if (is.installed("blasctl")) {
        # cover all our blases
        vcat(verbose, "...using GOTOBLAS or Other")
        suppressPackageStartupMessages(library("blasctl"))
        if (existsFunction("blas_set_num_threads", where=topenv(.GlobalEnv)))
        blas_set_num_threads(nthreads)
        omp_set_num_threads(nthreads)
    } else {
        vcat(verbose, "...NOT using any multithreading BLAS library")
    }
    
    # Not sure if these env vars matter?
    Sys.setenv(OMP_NUM_THREADS=nthreads)
    Sys.setenv(GOTO_NUM_THREADS=nthreads)
    Sys.setenv(MKL_NUM_THREADS=nthreads)
    Sys.setenv(OMP_DYNAMIC=TRUE)
    Sys.setenv(MKL_DYNAMIC=TRUE)
    
    invisible(TRUE)
}
