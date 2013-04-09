"""
For a given parcellation level:

    For a given fold:
    
        Read in the pvalues
"""

library(connectir)

base <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"
ks <- c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400)
folds <- 1:10
factors <- c("age", "sex")

sdir <- file.path(base, sprintf("rois_random_k%04i", ks[1]))
mdir <- file.path(sdir, "partial_mdmrs", sprintf("fold%02i_age+gender_with-meanFD_15k.mdmr", folds[1]))
pfiles <- file.path(mdir, sprintf("one_minus_pvals_%s.nii.gz", factors))

log.pvals <- sapply(pfiles, function(f) read.nifti.image())
