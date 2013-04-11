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
list.clust.vals <- lapply(fstats_for_pvals[,fi], function(vox.thresh) 
                            cluster.table(vox.fstats, vox.thresh, hdr$dim, mask))

# Save output as nifti
# TODO
