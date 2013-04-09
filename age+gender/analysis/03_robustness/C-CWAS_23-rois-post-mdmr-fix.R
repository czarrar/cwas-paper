"""
This script will produce the voxelwise maps 
that MDMR was unable to output due to a bug.
"""

###
# Setup
###

library(connectir)

# Data Info
samples <- c("discovery", "replication")
factors <- c("age", "sex")


####
## K1600
####
#
## Paths
#base <- "/home/data/Projects/CWAS/age+gender/03_robustness/cwas"
#sdirs <- file.path(base, sprintf("%s_rois_random_k1600", samples))
#mdirs <- file.path(sdirs, "age+gender_15k.mdmr")
#pfiles <- file.path(mdirs, "pvals.desc")
#roifile <- "rois/rois_random_k1600.nii.gz"
#
## ROI/Mask
#rois <- as.vector(read.nifti.image(roifile))
#mask <- rois!=0
#hdr <- read.nifti.header(roifile)
#urois <- sort(unique(rois[mask]))
#nrois <- length(urois)
#
## Loop through the samples (pvals)
#for (pi in 1:length(pfiles)) {
#    vcat(T, "Pfile #%i", pi)
#    
#    pvals <- attach.big.matrix(pfiles[pi])
#    fdrvals <- apply(pvals, 2, p.adjust, method="fdr")
#    
#    # Loop through each factor (columns in pvals)
#    for (fi in 1:length(factors)) {
#        vcat(T, "...factor %s", factors[fi])
#        
#        # P-values
#        ofile <- file.path(mdirs[pi], sprintf("logp_%s.nii.gz", factors[fi]))
#        onifti <- rois[mask]*0
#        for (ri in 1:nrois) {
#            w <- rois[mask]==urois[ri]
#            onifti[w] <- pvals[ri,fi]
#        }
#        onifti <- -log10(onifti)
#        write.nifti(onifti, hdr, mask, outfile=ofile)
#        
#        # FDR values
#        ofile <- file.path(mdirs[pi], sprintf("fdr_logp_%s.nii.gz", factors[fi]))
#        onifti <- rois[mask]*0
#        for (ri in 1:nrois) {
#            w <- rois[mask]==urois[ri]
#            onifti[w] <- fdrvals[ri,fi]
#        }
#        onifti <- -log10(onifti)
#        write.nifti(onifti, hdr, mask, outfile=ofile)
#    }
#}


###
# K3200
###

# Paths
base <- "/home/data/Projects/CWAS/age+gender/03_robustness/cwas"
sdirs <- file.path(base, sprintf("%s_rois_random_k3200", samples))
mdirs <- file.path(sdirs, "age+gender_15k.mdmr")
pfiles <- file.path(mdirs, "pvals.desc")
roifile <- "rois/rois_random_k3200.nii.gz"

# ROI/Mask
rois <- as.vector(read.nifti.image(roifile))
mask <- rois!=0
hdr <- read.nifti.header(roifile)
urois <- sort(unique(rois[mask]))
nrois <- length(urois)

# Loop through the samples (pvals)
for (pi in 1:length(pfiles)) {
    vcat(T, "Pfile #%i", pi)
    
    pvals <- attach.big.matrix(pfiles[pi])
    fdrvals <- apply(pvals, 2, p.adjust, method="fdr")
    
    # Loop through each factor (columns in pvals)
    for (fi in 1:length(factors)) {
        vcat(T, "...factor %s", factors[fi])
        
        # P-values
        ofile <- file.path(mdirs[pi], sprintf("logp_%s.nii.gz", factors[fi]))
        onifti <- rois[mask]*0
        for (ri in 1:nrois) {
            w <- rois[mask]==urois[ri]
            onifti[w] <- pvals[ri,fi]
        }
        onifti <- -log10(onifti)
        write.nifti(onifti, hdr, mask, outfile=ofile)
        
        # FDR values
        ofile <- file.path(mdirs[pi], sprintf("fdr_logp_%s.nii.gz", factors[fi]))
        onifti <- rois[mask]*0
        for (ri in 1:nrois) {
            w <- rois[mask]==urois[ri]
            onifti[w] <- fdrvals[ri,fi]
        }
        onifti <- -log10(onifti)
        write.nifti(onifti, hdr, mask, outfile=ofile)
    }
}
