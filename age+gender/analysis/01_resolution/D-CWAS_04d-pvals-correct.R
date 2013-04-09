# This script runs multiple comparisons correction (FDR)
# on the output of the ROI -> Voxel results.

###
# Setup
###

library(connectir)

basedir <- "/home2/data/Projects/CWAS"

# Subject Directories
sdirs <- Sys.glob(file.path(basedir, "age+gender/01_resolution/cwas/rois-to-voxel_*"))

# Brain Mask
msdir <- file.path(basedir, "age+gender/01_resolution/cwas/rois_k0025")
mask.file <- file.path(msdir, "mask.nii.gz")
mask <- read.mask(mask.file)
hdr <- read.nifti.header(mask.file)

# MDMR Directories
mdirs <- file.path(sdirs, "age+gender_with-meanFD_15k_rhs.mdmr")

# ROIs
roidir <- file.path(basedir, "share/age+gender/analysis/01_resolution/rois")
roi.files <- Sys.glob(file.path(roidir, "rois_*.nii.gz"))
list.rois <- lapply(roi.files, function(f) {
    nii <- read.nifti.image(f)
    nii[mask]
})
nrois <- length(list.rois)

# Pvalues
pvals.descs <- file.path(mdirs, "pvals.desc")
list.pvals <- lapply(pvals.descs, attach.big.matrix)

# Factors
factors <- c("age", "sex")
nfactors <- length(factors)

# Output filenames
list.opfiles <- lapply(mdirs, function(mdir) 
                    file.path(mdir, sprintf("log_pvals_fdr_%s.nii.gz", factors)))
list.ozfiles <- lapply(mdirs, function(mdir) 
                    file.path(mdir, sprintf("zstats_fdr_%s.nii.gz", factors)))

###
# The good stuff
###

# Loop through each ROI and save p-values as 3D nifti
for (ri in 1:nrois) {
    vcat(T, "ROI: #%i", ri)
    
    # ROIs
    rois <- list.rois[[ri]]
    urois <- sort(unique(rois))
    urois <- urois[urois!=0]
    
    # Pvalues for ROI set
    Pmat <- list.pvals[[ri]]
    if (length(urois) != nrow(Pmat))
        stop("Incorrect number of unique ROIs")
    
    for (fi in 1:nfactors) {
        vcat(T, "...factor %s", factors[fi])
        
        # Specific pvalues for factors
        pvals <- p.adjust(Pmat[,fi], "fdr")
        pvals_per_voxel <- vector("numeric", sum(mask))
        zstats_per_voxel <- vector("numeric", sum(mask))
        
        # Loop through each ROI and copy it's p-value
        for (i in 1:length(urois)) {
            pvals_per_voxel[rois==urois[i]] <- -log10(pvals[i])
            zstats_per_voxel[rois==urois[i]] <- qt(pvals[i], Inf, lower.tail=F)
        }
        
        # Save
        write.nifti(pvals_per_voxel, hdr, mask, 
                    outfile=list.opfiles[[ri]][[fi]], overwrite=T)
        write.nifti(zstats_per_voxel, hdr, mask, 
                    outfile=list.ozfiles[[ri]][[fi]], overwrite=T)
    }
}

