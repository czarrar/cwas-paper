# This script runs multiple comparisons correction (FDR)
# on the output of the ROI -> Voxel results.

###
# Setup
###

library(connectir)

basedir <- "/home2/data/Projects/CWAS"

# Subject Directories
sdir <- file.path(basedir, "age+gender/01_resolution/cwas/voxelwise")

# Brain Mask
mask.file <- file.path(sdir, "mask.nii.gz")
mask <- read.mask(mask.file)
hdr <- read.nifti.header(mask.file)

# MDMR Directories
mdir <- file.path(sdir, "age+gender_with-meanFD_15k_rhs.mdmr")

# Pvalues
desc <- file.path(mdir, "pvals.desc")
Pmat <- attach.big.matrix(desc)

# Factors
factors <- c("age", "sex")
nfactors <- length(factors)

# Output filenames
list.opfiles <- file.path(mdir, sprintf("log_pvals_fdr_%s.nii.gz", factors))
list.ozfiles <- file.path(mdir, sprintf("zstats_fdr_%s.nii.gz", factors))


###
# The good stuff
###

# Loop through each ROI and save p-values as 3D nifti

for (fi in 1:nfactors) {
    vcat(T, "...factor %s", factors[fi])
        
    # Specific pvalues for factors
    pvals <- p.adjust(Pmat[,fi], "fdr")
    logps <- -log10(pvals)
    zstats <- qt(pvals, Inf, lower.tail=F)
    
    # Save
    write.nifti(pvals, hdr, mask, 
                outfile=list.opfiles[fi], overwrite=T)
    write.nifti(zstats, hdr, mask, 
                outfile=list.ozfiles[fi], overwrite=T)
}
