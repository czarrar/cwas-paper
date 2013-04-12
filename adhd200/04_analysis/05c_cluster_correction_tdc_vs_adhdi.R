# This script will run cluster correction for the MDMR Results

## Libraries/Functions/Basics

library(connectir)
library(plyr)
source("y_inline_connectir.R")
basedir <- "/home2/data/Projects/CWAS"

# Convert roi-level data to be voxelwise
rois_to_voxelwise <- cxxfunction( signature(sA = "object", sRow = "numeric", sRoiInds='List', sNvoxs = "numeric"), 
' 
  try{
    BM_TO_ARMA_ONCE(sA, A)
    double row = DOUBLE_DATA(sRow)[0] - 1;
    Rcpp::List list_roi_inds(sRoiInds);
    double nvoxs = DOUBLE_DATA(sNvoxs)[0];
    
    arma::vec voxs(nvoxs);
    for (size_t i = 0; i < A.n_cols; ++i) {
        SEXP s_roi_inds = list_roi_inds[i];
        Rcpp::NumericVector roi_inds(s_roi_inds);
        int ninds = roi_inds.size();
        for (int j = 0; j < ninds; ++j)
            voxs[roi_inds[j]-1] = A(row,i);
    }
    
    return Rcpp::wrap( voxs );
  } catch( std::exception &ex ) {
    forward_exception_to_r( ex );
  } catch(...) { 
    ::Rf_error( "c++ exception (unknown reason)" ); 
  }
  return R_NilValue; // -Wall
', plugin = "connectir")


## Terms and Factors

study <- "adhd200"
terms <- "group"
factors <- terms
nfactors <- length(factors)
group <- "tdc_vs_adhdi"


## ROIs

# Paths
roi.dir <- file.path(basedir, "share", study, "rois")
mask.file <- file.path(roi.dir, "mask_gray_4mm.nii.gz")
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
sdist.dir <- file.path(basedir, study, "cwas/rois_random_k3200")
mdmr.dir <- file.path(sdist.dir, sprintf("perms02k_%s_gender+age+iq+meanFD.mdmr", group))
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
sdist.dir <- file.path(basedir, study, "cwas/rois_random_k3200")
mdmr.dir <- file.path(sdist.dir, sprintf("%s_gender+age+iq+meanFD.mdmr", group))
fperms.files <- file.path(mdmr.dir, sprintf("fperms_%s.desc", terms))
pval.file <- file.path(mdmr.dir, "pvals.desc")

# Fperms
list.fperms <- lapply(fperms.files, attach.big.matrix)
nperms <- nrow(list.fperms[[1]])


## Clusterize - TDC vs ADHD-I

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
list.clust.vals <- lapply(fstats_for_pvals[,fi], function(vox.thresh) 
                            cluster.table(vox.fstats, vox.thresh, hdr$dim, mask))

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

# Save the permutations
save(perms.clust.sizes, file=file.path(mdmr.dir, sprintf("ref_perms_clust_sizes_%s.rda", factors[fi])))


