# This script combines the multiple repeat voxelwise MDMRs done in 01_resolution

# 1. Setup
# 2. Copy design etc files
# 3. Combine fstats
# 4. Calculate pvalues from combined fstats
# 5. Combine permutation indices


###
# Setup
###

library(connectir)

subdir <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/voxelwise"
mdmrdirs <- Sys.glob(file.path(subdir, "age+gender_with-meanFD_*k_rhs*.mdmr"))
mdmrdirs <- mdmrdirs[-grep("combined", mdmrdirs)]

mask <- read.mask(file.path(subdir, "mask.nii.gz"))
nvoxs <- sum(mask)

factors <- c("age", "sex")
outmdmr <- file.path(subdir, "age+gender_with-meanFD_50k_rhs_combined.mdmr")
dir.create(outmdmr)

copy.fnames <- c(list.files(mdmrdirs[1], pattern="*.txt", full.names=T), 
                 list.files(mdmrdirs[1], pattern="*.2D", full.names=T), 
                 list.files(mdmrdirs[1], pattern="*.rda", full.names=T))


###
# Copy Files
###

vcat(T, "Copying files")
file.copy(copy.fnames, outmdmr)


###
# Combine and copy Fstats
###

vcat(T, "Fstats")
for (factor in factors) {
    vcat(T, "..factor: %s", factor)
    
    # Setup input
    descfiles <- file.path(mdmrdirs, sprintf("fperms_%s.desc", factor))
    fperms <- sapply(descfiles, attach.big.matrix)
    
    # Setup output
    outfperm <- big.matrix(50000, nvoxs, 
                           backingpath=outmdmr, 
                           backingfile=sprintf("fperms_%s.bin", factor), 
                           descriptorfile=sprintf("fperms_%s.desc", factor))
    
    # 1st 15,000 permutations
    curi <- 1
    first_end <- nrow(fperms[[curi]])
    s.outfperm <- sub.big.matrix(outfperm, firstRow=1, lastRow=first_end, 
                                 backingpath=outmdmr)
    deepcopy(fperms[[curi]], y=s.outfperm)
    fperms[[curi]] <- free.memory(fperms[[curi]], backingpath=mdmrdirs[[curi]])
    flush(s.outfperm); rm(s.outfperm)
    outfperm <- free.memory(outfperm, backingpath=outmdmr)
    invisible(gc(F,T))
    
    # 2nd 15,000 permutations
    curi <- 2
    second_end <- first_end + nrow(fperms[[curi]]) - 1
    s.outfperm <- sub.big.matrix(outfperm, firstRow=first_end+1, lastRow=second_end, backingpath=outmdmr)
    deepcopy(fperms[[curi]], rows=2:nrow(fperms[[curi]]), y=s.outfperm)
    fperms[[curi]] <- free.memory(fperms[[curi]], backingpath=mdmrdirs[[curi]])
    flush(s.outfperm); rm(s.outfperm); outfperm <- free.memory(outfperm, backingpath=outmdmr)
    invisible(gc(F,T))
    
    # 3rd 15,000 permutations
    curi <- 3
    third_end <- second_end + nrow(fperms[[curi]]) - 1
    s.outfperm <- sub.big.matrix(outfperm, firstRow=second_end+1, lastRow=third_end, 
                                 backingpath=outmdmr)
    deepcopy(fperms[[curi]], rows=2:nrow(fperms[[curi]]), y=s.outfperm)
    fperms[[curi]] <- free.memory(fperms[[curi]], backingpath=mdmrdirs[[curi]])
    flush(s.outfperm); rm(s.outfperm)
    outfperm <- free.memory(outfperm, backingpath=outmdmr)
    invisible(gc(F,T))
    
    rm(fperms, outfperm); invisible(gc(F,T))
}


###
# Calculate new p-values
###

vcat(T, "P-Values")

# Read in Fstats
descs <- file.path(outmdmr, sprintf("fperms_%s.desc", factors))
Fperms <- sapply(descs, attach.big.matrix)

# Calculate Pvals
pvals <- mdmr.fstats_to_pvals(Fperms)

# Save Pvals
Pmat <- big.matrix(nvoxs, length(factors), 
                   backingpath=outmdmr, 
                   backingfile="pvals.bin", 
                   descriptorfile="pvals.desc")
Pmat[,] <- pvals
rm(Pmat, pvals); gc()


###
# Combine and save permutation indices
###

vcat(T, "Permutation Indices")

for (factor in factors) {
    vcat(T, "..factor: %s", factor)
    
    # Setup input
    descfiles <- file.path(mdmrdirs, sprintf("perms_%s.desc", factor))
    list.perms <- lapply(descfiles, attach.big.matrix)
    nobs <- nrow(list.perms[[1]])
    
    # Setup output
    outperms <- big.matrix(nobs, 50000, 
                           backingpath=outmdmr, 
                           backingfile=sprintf("perms_%s.bin", factor), 
                           descriptorfile=sprintf("perms_%s.desc", factor))
    
    # 1st 15,000 permutations
    curi <- 1
    first_end <- ncol(list.perms[[curi]])
    s.outperms <- sub.big.matrix(outperms, firstCol=1, lastCol=first_end, 
                                 backingpath=outmdmr)
    deepcopy(list.perms[[curi]], y=s.outperms)
    list.perms[[curi]] <- free.memory(list.perms[[curi]], 
                                      backingpath=mdmrdirs[[curi]])
    flush(s.outperms); rm(s.outperms)
    outperms <- free.memory(outperms, backingpath=outmdmr)
    invisible(gc(F,T))
    
    # 2nd 15,000 permutations
    curi <- 2
    second_end <- first_end + ncol(list.perms[[curi]]) - 1
    s.outperms <- sub.big.matrix(outperms, firstCol=first_end+1, lastCol=second_end, 
                                 backingpath=outmdmr)
    deepcopy(list.perms[[curi]], cols=2:ncol(list.perms[[curi]]), y=s.outperms)
    list.perms[[curi]] <- free.memory(list.perms[[curi]], 
                                      backingpath=mdmrdirs[[curi]])
    flush(s.outperms); rm(s.outperms)
    outperms <- free.memory(outperms, backingpath=outmdmr)
    invisible(gc(F,T))
    
    # 3rd 15,000 permutations
    curi <- 3
    third_end <- second_end + ncol(list.perms[[curi]]) - 1
    s.outperms <- sub.big.matrix(outperms, firstCol=second_end+1, lastCol=third_end, 
                                 backingpath=outmdmr)
    deepcopy(list.perms[[curi]], cols=2:ncol(list.perms[[curi]]), y=s.outperms)
    list.perms[[curi]] <- free.memory(list.perms[[curi]], 
                                      backingpath=mdmrdirs[[curi]])
    flush(s.outperms); rm(s.outperms)
    outperms <- free.memory(outperms, backingpath=outmdmr)
    invisible(gc(F,T))
    
    rm(list.perms, outperms); invisible(gc(F,T))
}



