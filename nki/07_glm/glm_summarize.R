#!/usr/bin/env Rscript

#### Command-Line:
## usage: glm_summarize.R regressors.txt mask.nii.gz rois.nii.gz name_1 tvals_1.desc ... name_N tvals_N.desc output_dir
## arguments:
# regressors
# mask
# rois
# name(s) of tval matrices
# list of tvals descriptor files
# output directory


# An empty function for Comments
Comment <- function(`@Comments`) {invisible()}

Comment("
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
")


### Read in user arguments

args = commandArgs(trailingOnly = TRUE)

if (length(args) < 5)
    stop("must have at least 5 arguments: regressors mask tvals output-dir")

ev_file <- args[1]
mask_file <- args[2]
tval_names <- args[seq(3, length(args)-1, by=2)]
tval_files <- args[seq(4, length(args)-1, by=2)]
output_dir <- args[length(args)]


### Summarize!

library(connectir)

## Read in data
vcat(T, "Reading in data")

evs <- read.table(ev_file)
mask <- read.mask(mask_file)
hdr <- read.nifti.header(mask_file)
list.tvals <- lapply(tval_files, attach.big.matrix)
names(list.tvals) <- tval_names


## Other Variables

nobs <- nrow(evs)
pthr <- 0.05/2
zthr <- qt(pthr, Inf, lower.tail=F)


## Standardize and Summarize and Save
vcat(T, "Standardize, summarize, and save")

for (i in 1:length(list.tvals)) {
    vcat(T, "iter %i", i)
    
    ## Standardize Results
    vcat(T, "...standardize")
    
    tvals <- list.tvals[[i]]
    abs.tvals <- abs(tvals[,])
    
    pvals <- pt(abs.tvals, nobs, lower.tail=F)
    #fdr.pvals <- p.adjust(pvals, "fdr")
    #fdr.pvals <- matrix(fdr.pvals, nrow(pvals), ncol(pvals))
    
    zvals <- qt(pvals, Inf, lower.tail=F)
    #fdr.zvals <- qt(fdr.pvals, Inf, lower.tail=F)
    
    
    ## Summarize
    vcat(T, "...summarize")

    # Weighted Sums
    wt <- list()
    wt$zvals <- colSums(zvals)
    #wt$fdr.zvals <- colSums(fdr.zvals)

    # UnWeighted (Thresholded) Sums
    uwt <- list()
    uwt$zvals <- colSums(zvals > zthr)
    #uwt$fdr.zvals <- colSums(fdr.zvals > zthr)
    
    
    ## Save
    vcat(T, "...save")
    
    name <- tval_names[i]
    
    # output
    dir.create(output_dir, FALSE)

    # As RDA
    save(wt, uwt, file=file.path(output_dir, sprintf("both_%s.rda", name)))

    # As NIFTI
    ofile <- file.path(output_dir, sprintf("wt_%s.nii.gz", name))
    write.nifti(wt$zvals, hdr, mask, outfile=ofile)
    
    ofile <- file.path(output_dir, sprintf("uwt_%s.nii.gz", name))
    write.nifti(uwt$zvals, hdr, mask, outfile=ofile)
}

