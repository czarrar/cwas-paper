#!/usr/bin/env Rscript

# So we can see here that we need some code to take the formula, 
# subdists (data), and indices
# This function would then need to
# - generate the gower matrix from the subject distances
# - determine the superblocksize and blocksize (maybe defaults?)
# - went to autoset factors2perm
# - have the model already present in the function or maybe as a global
# all the other options I think I can set with some defaults
# then we can call the mdmr function
# We should check how well the output works when I have a vector...it seems like yes
# So the output would be to take only
# - the pvals or fstats

cat("Load\n")

library(connectir)
library(boot)

scan <- "short"

boot_mdmr <- function(formula, data, indices, sdist, factors2perm) {
    ###
    # Distances
    ###
    
    # We need to sample the distances based on the indices
    # This will also create a local copy of the big matrix
    cat("Subset of subjects in distances\n")
    sdist <- filter_subdist(sdist, subs=indices)
    
    # Now we can gowerify
    cat("Gowerify\n")
    gmat <- gower.subdist2(sdist)
    
    # Size
    nvoxs <- ncol(gmat)
    nsubs <- sqrt(nrow(gmat))
    nperms <- 4999
    nfactors <- 1
    
    
    ###
    # Calculate memory demands
    ###
    opts <- list(verbose=TRUE, memlimit=20, blocksize=0, superblocksize=0)
    opts <- get_mdmr_memlimit(opts, nsubs, nvoxs, nperms, nfactors)
    
    
    ###
    # Get the model ready
    ###
    
    cat("Subset of subjects in model\n")
    model <- data.frame(data[indices,])
    
    
    ###
    # Call MDMR
    ###
    
    ret <- mdmr(gmat, formula, model, nperms, factors2perm, 
                 superblocksize=opts$superblocksize, blocksize=opts$blocksize)
    
    ret$pvals[,] # or ret$fstats or qt(ret$pvals, Inf, lower.tail=FALSE)
}


###
# CWAS Bootstrapped
###

cat("Setup\n")

# Set parallel processing
nthreads <- 8
set_parallel_procs(1, nthreads, TRUE)

# Read in the distances
dpath <- file.path("/home2/data/Projects/CWAS/nki/cwas", scan, "compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/subdist_transform.desc")
#dpath <- "/home2/data/Projects/CWAS/nki/cwas/short/compcor_only_rois_random_k0800/subdist.desc"
sdist <- attach.big.matrix(dpath)

# Read in the model
mpath <- "/home2/data/Projects/CWAS/share/nki/subinfo/40_Set1_N104/subject_info_with_iq_and_gcors.csv"
model <- read.csv(mpath)
model <- subset(model, select=c("FSIQ", "Age", "Sex", sprintf("%s_meanFD", scan)))

# Set the formula
if (scan == "short") {
    f     <- ~ FSIQ + Age + Sex + short_meanFD
} else {
    f     <- ~ FSIQ + Age + Sex + medium_meanFD
}

# Number of subject to subsample
nsubs <- nrow(model)
nboot <- floor(nsubs*0.9)

## get subsample of the distances?
#sub.sdist <- sub.big.matrix(sdist, firstCol=1, lastCol=10, backingpath=dirname(dpath))

cat("Compute\n")

# Original
pvals0 <- boot_mdmr(f, model, 1:nsubs, sdist, "FSIQ")

# Iterate over samples
nsamples <- 500
pvals.mat <- sapply(1:nsamples, function(i) {
    boot_mdmr(f, model, sample(1:nsubs, nboot), sdist, "FSIQ")
})


###
# Summarize Bootstraps
###

# Now I want to get the proportion of significant bootstraps per voxel
# so I get p < 0.05 and collapse across bootstraps
prop_sig <- rowMeans(pvals.mat < 0.05)


###
# Save
###

odir  <- "/home/data/Projects/CWAS/nki/bootstrap"

# Nifti
mpath <- file.path("/home2/data/Projects/CWAS/nki/cwas", scan,  "compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/mask.nii.gz")
mask  <- read.mask(mpath)
hdr   <- read.nifti.header(mpath)
write.nifti(prop_sig, hdr, mask, outfile=file.path(odir, sprintf("prop_signif_%s.nii.gz", scan)), overwrite=T)
write.nifti(-log10(pvals0), hdr, mask, outfile=file.path(odir, sprintf("logp_signif_%s.nii.gz", scan)), overwrite=T)

# Everything
save(pvals0, pvals.mat, prop_sig, file=file.path(odir, sprintf("results_%s.rda", scan)))
