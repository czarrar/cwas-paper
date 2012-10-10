zdist <- function(mat, method="cor") {
    switch(method, 
        cor = 1 - cor(mat), 
        stop("Unsupported method for zdist")
    )
}

constrain_rnorm <- function(n, mean = 0, sd = 1, min=--Inf, max=Inf, limit=5000) {
    vals <- rnorm(n, mean, sd)
    for (i in 1:limit) {
        bad <- vals<min | vals>max
        if (sum(bad) == 0) break
        vals[bad] <- rnorm(sum(bad), mean, sd)
    }
    if (i == limit)
        warning("constrain_rnorm didn't converge after ", limit, " loops")
    vals
}

###
# Match 2 different cluster memberships
###
# INPUT:
## template.m - ideal vector of cluster memberships
## comparison.m - vector of cluster memberships to match to ideal
## match.method - method in matchClasses (rowmax, greedy, exact)
match_cluster_memberships <- function(template.m, comparison.m, match.method="exact", iter=10) {
	library(e1071)
	num.regions = length(comparison.m)
	new.m = vector(mode="numeric", length=num.regions)

	if(length(unique(template.m)) != length(unique(comparison.m))) {
	
		return(matchUnequalClasses(template.m, comparison.m))
	
	} else {
		tab = table(template.m, comparison.m)
		conversion = matchClasses(tab, method=match.method, iter=iter)

		for (template.val in 1:num.regions) {
		    comparison.val = conversion[template.val]
			new.m[comparison.m==comparison.val] = template.val
		}
	
		return(new.m)
	}
}

matchUnequalClasses <- function(template.m, comparison.m) {
	tab = table(comparison.m, template.m)
	
	# Checks
	if(nrow(tab)<ncol(tab))
		stop("template.m must have less partitions than comparison.m")
	if(min(unique(template.m))!=1 | min(unique(comparison.m))!=1)
		stop("partitions template.m and comparison.m must start with 1")
		
	num.col = ncol(tab)
	
	for(i in 1:num.col) {
		which.leading = order(tab[,i], decreasing=TRUE)[1]
		if(which.leading!=i & which.leading>i) {
			tmp.m = comparison.m
			tmp.m[comparison.m==i] = which.leading
			tmp.m[comparison.m==which.leading] = i
			comparison.m = tmp.m
			tab = table(comparison.m, template.m)
		}
	}
	
	return(comparison.m)
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
    suppressPackageStartupMessages(library("doParallel"))
    cl <- makeForkCluster(nforks)
    registerDoParallel(cl)
#    suppressPackageStartupMessages(library("doMC"))
#    registerDoMC()
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
        if (existsFunction("blas_set_num_threads", where=topenv(.GlobalEnv))) {
            blas_set_num_threads(nthreads)
            omp_set_num_threads(nthreads)
        }
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
