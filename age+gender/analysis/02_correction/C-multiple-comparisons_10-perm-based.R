# This script will calculate the p-values for the age/gender CWAS
# and correct for multiple comparisons via cluster-based permutation test.
#
# Note that in order to do this correction the number of permutations is split in half


###
# Setup
###

library(connectir)

sdist.dir <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/voxelwise"
mdmr.dir <- file.path(sdist.dir, "age+gender_with-meanFD_50k_rhs_combined.mdmr")
factors <- c("age", "sex")

mask <- read.mask(file.path(sdist.dir, "mask.nii.gz"))
hdr <- read.nifti.header(file.path(sdist.dir, "mask.nii.gz"))
nvoxs <- sum(mask)

fpfiles <- file.path(mdmr.dir, sprintf("fperms_%s.desc", factors))
list.Fperms <- lapply(fpfiles, attach.big.matrix)
nperms <- nrow(list.Fperms[[1]])

vox.thresh <- 0.001
clust.thresh <- 0.05


###
# Approach 1 - Split Half
###

# The p-value is calculated for half of the original/permuted Fstats
# the other half of the permuted Fstats are used to form the null distribution

fi <- 1

# 1. Get Fstats for specific factor
Fperms <- list.Fperms[[fi]]

### For first half

# 2. Create a sub matrix to hold half of fstats
#    start off by having first half and vary the first row
half.Fperms <- deepcopy(Fperms, rows=1:(nperms/2))

# 3. Calculate p-values using the Fstats of the original data
#    and the second half of the permutations as the reference
inds <- c(1, ((nperms/2)+2):nperms)
pvals.mat <- laply(inds, function(i) {
    bedeepcopy(Fperms, x.rows=i, y=half.Fperms, y.rows=1)
    .Call("mdmr_fstats_to_pvals", half.Fperms, package="connectir")
}, .progress="text")
# pvals.mat should be nperms x nvoxs
## Clear memory
Fperms <- free.memory(Fperms, backingpath=dirname(fpfiles[fi]))
list.Fperms[[fi]] <- Fperms

# 4. Get cluster masses/sizes
clust_vals <- clust_mdmr.values(pvals.mat, mask, hdr$dim, vox.thresh, verbose=T, parallel=F)

# 5. Get cluster p-values
ref_details <- cluster.table(1-pvals.mat[1,], 1-vox.thresh, hdr$dim, mask)
ref_details <- clust_mdmr.pvalues(clust_vals, ref_details, "size")

# 6. Get clusters on brain image
clust <- clust_mdmr.clusterize(ref_details, mask, clust.thresh)

# 7. Get percent of significant voxels per permutation
percent_significant <- rowMeans(pvals.mat < 0.05)

# 8. Save/clean
approach1 <- list(
    clust_vals = clust_vals, 
    ref_details = ref_details, 
    clust = clust, 
    percent_sig = percent_significant
)
rm(pvals.mat, clust_vals, ref_details, clust, percent_significant); gc(F,T)

### For second half

# 2. Create a sub matrix to hold half of fstats
#    start off by having second half and vary the first row
half.Fperms <- deepcopy(Fperms, rows=(nperms/2+1):nperms)

# 3. Calculate p-values using the Fstats of the original data
#    and the first half of the permutations as the reference
inds <- c(1:(nperms/2))
pvals.mat <- laply(inds, function(i) {
    bedeepcopy(Fperms, x.rows=i, y=half.Fperms, y.rows=1)
    .Call("mdmr_fstats_to_pvals", half.Fperms, package="connectir")
}, .progress="text")
# pvals.mat should be nperms x nvoxs
Fperms <- free.memory(Fperms, backingpath=dirname(fpfiles[fi]))
list.Fperms[[fi]] <- Fperms

# 4. Get cluster masses/sizes
clust_vals <- clust_mdmr.values(pvals.mat, mask, hdr$dim, vox.thresh, verbose=T, parallel=F)

# 5. Get cluster p-values
ref_details <- cluster.table(1-pvals.mat[1,], 1-vox.thresh, hdr$dim, mask)
ref_details <- clust_mdmr.pvalues(clust_vals, ref_details, "size")

# 6. Get clusters on brain image
clust <- clust_mdmr.clusterize(ref_details, mask, clust.thresh)

# 7. Get percent of significant voxels per permutation
percent_significant <- rowMeans(pvals.mat < 0.05)

# 8. Save/clean
approach1 <- list(
    clust_vals = clust_vals, 
    ref_details = ref_details, 
    clust = clust, 
    percent_sig = percent_significant
)
rm(pvals.mat, clust_vals, ref_details, clust, percent_significant); gc(F,T)


###
# Approach 2 - 
###

