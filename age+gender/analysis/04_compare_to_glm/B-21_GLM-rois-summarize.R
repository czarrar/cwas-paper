"""
This script summarizes the GLM results by taking the sum of the absolute t-values as well as the number of significant t-values per voxel.

Prologue to Story:
    Vicky has discovered CWAS and wants to validate it.
    She travels to the land of univariates to compare her multivariate results.
    Here she submits her data to the Temple of Linear Regression.
    --------------
    Data Monologue:
        Her data are functional connectivity measures
        between parcellation units and brain voxels
    --------------
    For each connection, she wants to know which god is relevant
    is it the god of Age or the god of Sex/Gender
    If a god is relevant for a connection, 
    she will make a sacrifice for that god
    The temple folk give her back significance estimates for each connection
    indicating how well age or sex predict the connection values
    aka she has 2 t-value matrices for the relation to age and to sex
"""

library(connectir)

# Function to convert ROI results to be voxelwise
# note: this will be masked voxelwise results
rois_to_voxels <- function(rois, roi.data) {
    vox.data <- vector("numeric", length(rois))
    urois <- sort(unique(rois))
    
    for (i in 1:length(urois)) {
        ur <- urois[i]
        vox.data[rois==ur] <- roi.data[i]
    }
    
    return(vox.data)
}

# Different samples
samples <- c("discovery", "replication")


# Script Directory
scriptdir <- "/home2/data/Projects/CWAS/share/age+gender/analysis/04_compare_to_glm/rois"

# Directory with many results
resdir <- "/home2/data/Projects/CWAS/age+gender/04_compare_to_glm/glm"

###
# Summary Measures
###
for (sample in samples) {
    
    cat("Sample:", sample, "\n")
    
    
    ###
    # Path Setup - Specific
    ###

    # GLM Directory
    glmdir <- file.path(resdir, sprintf("%s_rois_random_k3200", sample))
    setwd(glmdir)

    # Path to inputs
    evs_file <- "model_evs.txt"
    mask_file <- "mask2.nii.gz"
    tvals_age_file <- "tvals_01.desc"
    tvals_sex_file <- "tvals_03.desc"
    roi_file <- file.path(scriptdir, "rois_random_k3200.nii.gz")
    
    
    ###
    # Some Inputs
    ###

    # Read in Stuff
    evs <- read.table(evs_file)
    mask <- read.mask(mask_file)
    hdr <- read.nifti.header(mask_file)
    rois <- read.nifti.image(roi_file)[mask]
    tvals.age <- attach.big.matrix(tvals_age_file)
    tvals.sex <- attach.big.matrix(tvals_sex_file)

    # Other Stuff
    nobs <- nrow(evs)
    pthr <- 0.05/2
    zthr <- qt(pthr, Inf, lower.tail=F)
    
    ###
    # Standardize Results
    ###
    
    # Absolutize T-Values
    abs.tvals.age <- abs(tvals.age[,])
    abs.tvals.sex <- abs(tvals.sex[,])
    
    # Convert to p-values
    pvals.age <- pt(abs.tvals.age, nobs, lower.tail=F)
    pvals.sex <- pt(abs.tvals.sex, nobs, lower.tail=F)

    # FDR correct p-values
    fdr.pvals.age <- p.adjust(pvals.age, "fdr")
    fdr.pvals.sex <- p.adjust(pvals.sex, "fdr")
    ## vector to matrix
    fdr.pvals.age <- matrix(fdr.pvals.age, nrow(pvals.age), ncol(pvals.age))
    fdr.pvals.sex <- matrix(fdr.pvals.sex, nrow(pvals.sex), ncol(pvals.sex))

    # Convert uncorrected to z-values
    zvals.age <- qt(pvals.age, Inf, lower.tail=F)
    zvals.sex <- qt(pvals.sex, Inf, lower.tail=F)

    # Convert corrected to z-values
    fdr.zvals.age <- qt(fdr.pvals.age, Inf, lower.tail=F)
    fdr.zvals.sex <- qt(fdr.pvals.sex, Inf, lower.tail=F)
    
    
    ###
    # Summarize Results
    ###

    # Weighted Sums
    wt <- list()
    wt$age <- colSums(zvals.age)
    wt$sex <- colSums(zvals.sex)
    wt$fdr.age <- colSums(fdr.zvals.age)
    wt$fdr.sex <- colSums(fdr.zvals.sex)

    # UnWeighted (Thresholded) Sums
    uwt <- list()
    uwt$age <- colSums(zvals.age > zthr)
    uwt$sex <- colSums(zvals.sex > zthr)
    uwt$fdr.age <- colSums(fdr.zvals.age > zthr)
    uwt$fdr.sex <- colSums(fdr.zvals.sex > zthr)
    
    
    ###
    # Save
    ###

    # As RDA
    save(wt, uwt, file="summary/all_sums.rda")

    # As NIFTI
    #names <- c("age", "sex", "fdr.age", "fdr.sex")
    names <- c("age", "sex")
    for (name in names) {
        vcat(T, "Name: %s", name)
    
        ofile <- sprintf("summary/wt_%s.nii.gz", sub("[.]", "_", name))
        img <- rois_to_voxels(rois, wt[[name]])
        write.nifti(img, hdr, mask, outfile=ofile)
    
        ofile <- sprintf("summary/uwt_%s.nii.gz", sub("[.]", "_", name))
        img <- rois_to_voxels(rois, uwt[[name]])
        write.nifti(img, hdr, mask, outfile=ofile)
    }
    
}
