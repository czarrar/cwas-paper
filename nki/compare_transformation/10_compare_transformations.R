###
# Setup
###

library(connectir)
library(boot)

# Set parallel processing
nthreads <- 8
set_parallel_procs(1, nthreads, TRUE)

# Read in the distances
dpath <- "/home2/data/Projects/CWAS/nki/cwas/short/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/subdist.desc"
sdist <- attach.big.matrix(dpath)

# Read in the model
mpath <- "/home2/data/Projects/CWAS/share/nki/subinfo/40_Set1_N104/subject_info_with_iq_and_gcors.csv"
model <- read.csv(mpath)
model <- subset(model, select=c("FSIQ", "Age", "Sex", "short_meanFD"))

# Set the formula
f     <- ~ FSIQ + Age + Sex + short_meanFD

## get subsample of the distances?
#sub.sdist <- sub.big.matrix(sdist, firstCol=1, lastCol=10, backingpath=dirname(dpath))

# We need to sample the distances based on the indices
# This will also create a local copy of the big matrix
cat("Subset of subjects in distances\n")

# Size
nvoxs <- ncol(sdist)
nsubs <- sqrt(nrow(sdist))
nperms <- 4999
nfactors <- 1
factors2perm <- "FSIQ"

# Calculate memory demands
opts <- list(verbose=TRUE, memlimit=20, blocksize=0, superblocksize=0)
opts <- get_mdmr_memlimit(opts, nsubs, nvoxs, nperms, nfactors)




###
# MDMR for regular distances (1-r)
###

# Copy distances by reference
sub.sdist <- sdist

# Now we can gowerify
cat("Gowerify\n")
gmat <- gower.subdist2(sub.sdist)

# MDMR
ret1 <- mdmr(gmat, f, model, nperms, factors2perm, 
             superblocksize=opts$superblocksize, blocksize=opts$blocksize)




###
# MDMR for transformed distances (sqrt(2*(1-r)))
###

# We need to sample the distances based on the indices
# This will also create a local copy of the big matrix
cat("Transform distances\n")
tmp       <- sqrt(2*sdist[,])
tmp[is.na(tmp)] <- 0
sub.sdist <- as.big.matrix(tmp)

# Now we can gowerify
cat("Gowerify\n")
gmat <- gower.subdist2(sub.sdist)

# MDMR
ret2 <- mdmr(gmat, f, model, nperms, factors2perm, 
             superblocksize=opts$superblocksize, blocksize=opts$blocksize, 
             list.perms=ret1$perms) # using the same permutations as ret1



###
# Save voxelwise results
###

p1 <- ret1$pvals[,]
p2 <- ret2$pvals[,]
sp1 <- p1*(p1<0.05)
sp2 <- p2*(p2<0.05)

mfile <- "/home2/data/Projects/CWAS/nki/cwas/short/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/mask.nii.gz"
mask <- read.mask(mfile)
hdr <- read.nifti.header(mfile)

write.nifti(-log10(p1), hdr, mask, outfile="nifti/iq_logp_no_transform.nii.gz")
write.nifti(-log10(p2), hdr, mask, outfile="nifti/iq_logp_yes_transform.nii.gz")
write.nifti(-log10(sp1), hdr, mask, outfile="nifti/iq_thresh_logp_no_transform.nii.gz")
write.nifti(-log10(sp2), hdr, mask, outfile="nifti/iq_thresh_logp_yes_transform.nii.gz")


## Compare

mean(abs(-log10(p1)-(-log10(p2))))

comp <- 1*(p1<0.05) + 2*(p2<0.05)

table(comp)
prop.table(table(comp))

cbind(p1,p2)[comp==1,]
cbind(p1,p2)[comp==2,]

