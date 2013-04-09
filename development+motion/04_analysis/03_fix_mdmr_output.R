#!/usr/bin/env Rscript

# This script formats the output from MDMR into nifti
# as well as correct for multiple comparisons using FDR

library(connectir)


## Input Paths

basedir <- "/home2/data/Projects/CWAS"

sdists <- c("cwas/rois_random_k3200", "cwas_regress_motion/rois_random_k3200")
mdmrs <- c("age+motion_sex+tr.mdmr", "age_sex+tr.mdmr")
mdmr_factors <- list(c("age", "mean_FD"), c("age"))

for (sdist in sdists) {
    for (mi in 1:length(mdmrs)) {
        mdmr <- mdmrs[mi]
        factors <- mdmr_factors[[mi]]
        nfactors <- length(factors)
        
        vcat(T, "%s : %s", sdist, mdmr)
        
        sdist.dir <- file.path(basedir, sprintf("development+motion/%s", sdist))
        mdmr.dir <- file.path(sdist.dir, mdmr)
        roi.dir <- file.path(basedir, "share/development+motion/rois")

        mask.file <- file.path(sdist.dir, "mask2.nii.gz")
        roi.file <- file.path(roi.dir, "rois_random_k3200.nii.gz")
        pval.file <- file.path(mdmr.dir, "pvals.desc")


        ## Inputs

        # Mask
        hdr <- read.nifti.header(mask.file)
        mask <- read.mask(mask.file)

        # ROIs
        rois <- read.nifti.image(roi.file)[mask]
        urois <- sort(unique(rois))
        urois <- urois[urois!=0]

        # Pmatrix of pvals
        Pmat <- attach.big.matrix(pval.file)


        ## Output paths
        pvals.files <- file.path(mdmr.dir, sprintf("log_pvals_%s.nii.gz", factors))
        fdr.pvals.files <- file.path(mdmr.dir, sprintf("log_fdr_pvals_%s.nii.gz", factors))


        ## Format/Correct

        for (fi in 1:nfactors) {
            vcat(T, "Factor %s", factors[fi])
    
            # P-values for factor and correct
            pvals <- Pmat[,fi]
            fdr.pvals <- p.adjust(pvals, "fdr")
    
            # Setup voxelwise
            pvals_voxelwise <- vector("numeric", sum(mask))
            fdr.pvals_voxelwise <- vector("numeric", sum(mask))
    
            # Convert roi => voxelwise
            for (i in 1:length(urois)) {
                pvals_voxelwise[rois==urois[i]] <- -log10(pvals[i])
                fdr.pvals_voxelwise[rois==urois[i]] <- -log10(fdr.pvals[i])
            }
    
            # Save
            write.nifti(pvals_voxelwise, hdr, mask, 
                        outfile=pvals.files[fi], overwrite=T)
            write.nifti(fdr.pvals_voxelwise, hdr, mask, 
                        outfile=fdr.pvals.files[fi], overwrite=T)
        }
        
    }
}

