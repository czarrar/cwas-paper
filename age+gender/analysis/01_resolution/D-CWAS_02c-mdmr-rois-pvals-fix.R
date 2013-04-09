# This script attempts to fix a problem when initially running D-CWAS_02b-mdmr-rois.bash
# it isn't really relevant anymore and is kept here for historic purposes

library(connectir)

basedir <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"
setwd(basedir)

sdirs <- list.files(path=basedir, pattern="rois_k[0-9]+$", full.names=T)
sdirs <- sdirs[1:(length(sdirs)-1)]
mdirs <- file.path(sdirs, "age+gender_with-meanFD_15k_rhs.mdmr")

factors <- c("age", "sex")
nfactors <- length(factors)

for (mdir in mdirs) {
    cat("MDMR Directory", mdir, "\n")
    
    # Load F-Stats
    list.Fperms <- lapply(1:nfactors, function(fi) {
        factor <- factors[fi]    
        desc.file <- file.path(mdir, sprintf("fperms_%s.desc", factor))
        Fperms <- attach.big.matrix(desc.file)
        Fperms
    })
    
    # Load Pvals
    pvals.file <- file.path(mdir, "pvals.desc")
    Pvals <- attach.big.matrix(pvals.file)
    
    # Calculate and save pvals
    Pvals[,] <- mdmr.fstats_to_pvals(list.Fperms)
    
    # Save pvals and zstats as nifti
    sdir <- dirname(mdir)
    save_mdmr.pvals_and_zstats(sdir, mdir, Pvals, 1:nrow(Pvals), factors)
    
    flush(Pvals); rm(Pvals, list.Fperms); invisible(gc(F,T))
}