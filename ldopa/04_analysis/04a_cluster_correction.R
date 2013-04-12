# This script will run cluster correction for the MDMR Results

## Libraries/Functions/Basics

library(connectir)
library(plyr)
source("y_inline_connectir.R")
basedir <- "/home2/data/Projects/CWAS"

## Terms and Factors

terms <- c("conditions")
factors <- c("drug")
nfactors <- length(factors)


## ROIs

# Paths
roi.dir <- file.path(basedir, "share/ldopa/rois")
mask.file <- file.path(roi.dir, "mask_for_ldopa_gray_4mm.nii.gz")
roi.file <- file.path(roi.dir, "rois_random_k3200.nii.gz")

# Mask
hdr <- read.nifti.header(mask.file)
mask <- read.mask(mask.file)
nvoxs <- sum(mask)

# ROIs
rois <- read.nifti.image(roi.file)[mask]
urois <- sort(unique(rois))
urois <- urois[urois!=0]
nrois <- length(urois)
rois.inds <- lapply(urois, function(ur) which(rois==ur))


## Load Fstats and Pvals for 2k Permutations

# Paths
sdist.dir <- file.path(basedir, "ldopa/cwas/rois_random_k3200")
mdmr.dir <- file.path(sdist.dir, "perms02k_ldopa_subjects+meanFD.mdmr")
fperms.files <- file.path(mdmr.dir, sprintf("fperms_%s.desc", terms))
pval.file <- file.path(mdmr.dir, "pvals.desc")

# Fperms
list.fperms <- lapply(fperms.files, attach.big.matrix)
nperms <- nrow(list.fperms[[1]])

# Pseudo-F Stats
Fmat <- sapply(list.fperms, function(fperms) fperms[1,])
rm(list.fperms) # don't really need the fperms

# Pmatrix of pvals
Pmat <- attach.big.matrix(pval.file)


## Get Fstats for Given P-Values

# Different thresholds to use
thrs <- -log10(c(0.05, 0.01, 0.005, 0.001))

# Do It!
fstats_for_pvals <- sapply(1:nfactors, function(i) {
    df <- data.frame(fstats=Fmat[,i], log.pvals=-log10(Pmat[,i]))
    model <- lm(fstats ~ log.pvals, data=df)
    res <- predict(model, data.frame(log.pvals=thrs))
    return(res)
})
rownames(fstats_for_pvals) <- round(thrs, 2)
colnames(fstats_for_pvals) <- factors


## Load Fstats for 15k Permutations

# Paths
sdist.dir <- file.path(basedir, "ldopa/cwas/rois_random_k3200")
mdmr.dir <- file.path(sdist.dir, "ldopa_subjects+meanFD.mdmr")
fperms.files <- file.path(mdmr.dir, sprintf("fperms_%s.desc", terms))
pval.file <- file.path(mdmr.dir, "pvals.desc")

# Fperms
list.fperms <- lapply(fperms.files, attach.big.matrix)
nperms <- nrow(list.fperms[[1]])


## Clusterize

fi <- 1

# Get cluster size across permutations and voxel-level thresholds
perms.clust.sizes <- laply(1:nperms, function(i) {
    sapply(fstats_for_pvals[,fi], function(vox.thresh) {
        img <- rois_to_voxelwise(list.fperms[[fi]], as.double(i), rois.inds, as.double(nvoxs))
        ct <- cluster.table(img, vox.thresh, hdr$dim, mask)
        return(ct$max.size)
    })
}, .progress="text")

# Cluster information for original data
vox.fstats <- rois_to_voxelwise(list.fperms[[fi]], as.double(1), rois.inds, as.double(nvoxs))
orig.clust.tables <- lapply(fstats_for_pvals[,fi], function(vox.thresh) {
    ct <- cluster.table(vox.fstats, vox.thresh, hdr$dim, mask)
})
orig.clust.sizes <- lapply(orig.clust.tables, function(ct) ct$size)
orig.clusts <- lapply(orig.clust.tables, function(ct) ct$clust)

# Cluster size significance
## since p < 0.05 is the only significant one, use that
orig.clust.sig <- sapply(orig.clust.sizes, function(ocs) {
    sapply(ocs, function(s) sum(s<perms.clust.sizes[,1])/nperms)
})

# Get significant clusters in voxelwise
clust <- orig.clusts[[1]][mask]
w.clusts <- which(rev(orig.clust.sig[[1]]<0.05))
clust.keep <- clust*0    # empty vector
for (i in 1:length(w.clusts)) clust.keep[clust==w.clusts[i]] <- 1
    
# Correct p-values
vox.pvals <- rois_to_voxelwise(as.big.matrix(t(Pmat[,,drop=F])), as.double(fi), rois.inds, as.double(nvoxs))
corr.pvals <- vox.pvals[,1] * clust.keep
corr.logp <- -log10(vox.pvals[,1]) * clust.keep
print(range(corr.logp[clust.keep==1]))

# Save
corr.logp.file <- file.path(mdmr.dir, sprintf("clust_logp_%s.nii.gz", factors[fi]))
write.nifti(corr.logp, hdr, mask, outfile=corr.logp.file)

# Save the permutations for later reference
save(perms.clust.sizes, file=file.path(mdmr.dir, sprintf("ref_perms_clust_sizes_%s.rda", factors[fi])))
