
library(connectir)

# Paths
basedir <- "/home2/data/Projects/CWAS"
indir <- file.path(basedir, "share/age+gender/analysis/01_resolution")
outdir <- file.path(basedir, "age+gender/01_resolution/cwas")
sdir <- file.path(outdir, "rois_to_rois_k1600")


###
# A. DISTANCES
###

load('called_options.rda')
opts <- saved_opts$opts

get_mask <- function(infiles, mask=NULL) {
    if (is.null(mask)) {
        hdr <- read.nifti.header(infiles[[1]])
        if (length(hdr$dim) == 2) {
            nvoxs <- hdr$dim[2]
        } else {
            nvoxs <- prod(hdr$dim[-length(hdr$dim)])
        }
        mask <- rep(TRUE, nvoxs)
    } else {
        mask <- read.mask(mask)
    }
      
    return(mask)
}

# Functional paths
infiles <- file.path(indir, "z_rois_k1600.txt")
infiles <- as.character(read.table(infiles)[,1])

# Mask
mask <- get_mask(infiles)

# Functional ROIs
reader <- gen_big_reader("nifti2d")
funclist <- load_and_mask_func_data2(infiles, reader, mask=mask, verbose=TRUE)

# Memory
nsubs <- length(infiles)
nvoxs <- sum(mask)
ntpts <- nrow(funclist[[1]])
opts <- get_subdist_memlimit(opts, nsubs, nvoxs, ntpts, nvoxs)

# Distance output
dists_list <- create_subdist(sdir, infiles, mask, NULL, NULL, opts)

# Compute distances
checks <- compute_subdist_wrapper(funclist, dists_list, 
                                  opts$blocksize, opts$superblocksize, 
                                  design_mat=opts$regress, verbose=1, 
                                  ztransform=opts$ztransform, method="pearson")


###
# B. MDMR
###

# General (SGE)
G.file <- file.path(sdir, "subdist_gower.desc")
G <- attach.big.matrix(G.file)

model <- read.csv("z_details.csv")
formula <- ~ age + sex + mean_FD
factors2perm <- c("age", "sex")

nvoxs <- ncol(G)
nperms <- 14999
save.fperms <- TRUE

nforks <- 4; nthreads <- 2; njobs <- 12
set_parallel_procs(2, 2, force=TRUE)
sge.info <- list(njobs=njobs, nforks=nforks, nthreads=nthreads, ignore.proc.error=T)

blocksize <- round((nperms+1)/nforks)
superblocksize <- round(nvoxs/njobs)


# General (NO SGE)
G.file <- file.path(sdir, "subdist_gower.desc")
G <- attach.big.matrix(G.file)

model <- read.csv("z_details.csv")
formula <- ~ age + sex + mean_FD
factors2perm <- c("age", "sex")

nvoxs <- ncol(G)
nperms <- 14999
save.fperms <- TRUE

nforks <- 1; nthreads <- 20
set_parallel_procs(nforks, nthreads, force=TRUE)
sge.info <- NULL

blocksize <- round((nperms+1)/nforks)
superblocksize <- round(nvoxs/10)


# Standard
mdmr.dir <- file.path(sdir, "age+sex_with-motion_15k_rhs.mdmr")
dir.create(mdmr.dir)

G.file <- file.path(sdir, "subdist_gower.desc")
G <- attach.big.matrix(G.file)

ret.mdmr <- mdmr(G, formula, model, nperms, factors2perm, G.path=sdir, 
                 fperms.path=mdmr.dir, save.fperms=save.fperms, 
                 superblocksize=superblocksize, blocksize=blocksize, 
                 sge.info=sge.info, permute="rhs")

vcat(verbose, "Saving stuff")
save_mdmr.modelinfo(mdmr.dir, ret.mdmr$modelinfo)
factor.names <- names(attr(ret.mdmr$modelinfo$qrhs, "factors2perm"))
save_mdmr.permutations(mdmr.dir, ret.mdmr$perms, factor.names)


# Old
mdmr.dir <- file.path(sdir, "age+sex_with-motion_15k_hat.mdmr")
dir.create(mdmr.dir)

G.file <- file.path(sdir, "subdist_gower.desc")
G <- attach.big.matrix(G.file)

ret.mdmr <- mdmr(G, formula, model, nperms, factors2perm, G.path=sdir, 
                 fperms.path=mdmr.dir, save.fperms=save.fperms, 
                 superblocksize=superblocksize, blocksize=blocksize, 
                 sge.info=sge.info, permute="hat")

vcat(verbose, "Saving stuff")
save_mdmr.modelinfo(mdmr.dir, ret.mdmr$modelinfo)
factor.names <- names(attr(ret.mdmr$modelinfo$qrhs, "factors2perm"))
save_mdmr.permutations(mdmr.dir, ret.mdmr$perms, factor.names)


# Old with Covariates
mdmr.dir <- file.path(sdir, "age+sex_with-motion_15k_hat_with_covars.mdmr")
dir.create(mdmr.dir)

G.file <- file.path(sdir, "subdist_gower.desc")
G <- attach.big.matrix(G.file)

ret.mdmr <- mdmr(G, formula, model, nperms, factors2perm, G.path=sdir, 
                 fperms.path=mdmr.dir, save.fperms=save.fperms, 
                 superblocksize=superblocksize, blocksize=blocksize, 
                 sge.info=sge.info, permute="hat_with_covariates")

vcat(verbose, "Saving stuff")
save_mdmr.modelinfo(mdmr.dir, ret.mdmr$modelinfo)
factor.names <- names(attr(ret.mdmr$modelinfo$qrhs, "factors2perm"))
save_mdmr.permutations(mdmr.dir, ret.mdmr$perms, factor.names)



###
# C. Comparison
###

mdmr.dirs <- file.path(sdir, sprintf("age+sex_with-motion_15k_%s.mdmr", 
                        c("rhs", "hat", "hat_with_covars")))
pvals.files <- file.path(mdmr.dirs, "pvals.desc")

list.pvals <- lapply(pvals.files, attach.big.matrix)
