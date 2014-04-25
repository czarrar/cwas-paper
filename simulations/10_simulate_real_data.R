#!/usr/bin/env Rscript

#' In this script we once again try our hand at another simulation.
#' Our focus is finding the effectiveness of running MDMR across
#' different factors.

#' What are the steps here.
#' First I want to load the timeseries data.
#' Second, I want to compute the connectivity (for just one voxel with the rest of the brain).

#' Somewhat independent of the previous step, I can
#' generate the locations for the group effect to be added
#' The thing that I am struggling with here is that I want to 

#' Libraries
suppressPackageStartupMessages(library(niftir))
suppressPackageStartupMessages(library(connectir))
suppressPackageStartupMessages(library(plyr))

args        <- commandArgs(trailingOnly = TRUE)
k           <- as.numeric(args[1])
start_vox   <- as.numeric(args[2])
end_vox     <- as.numeric(args[3])
nthreads    <- as.numeric(args[4])

cat("k:", k, "\n")
cat("voxs:", start_vox, "-", end_vox, "\n")
cat("threads:", nthreads, "\n\n")

start.time <- proc.time()

set_parallel_procs(nthreads=nthreads, verbose=T)

cat("setup paths\n")
subdir  <- "/home2/data/Projects/CWAS/share/nki/subinfo/40_Set1_N104"
phenos  <- read.csv(file.path(subdir, "subject_info_with_iq_and_gcors.csv"))
phenos  <- subset(phenos, select=c("Age", "Sex", "FSIQ", "short_meanFD"))
fpaths  <- read.table(file.path(subdir, sprintf("short_compcor_rois_random_k%04i.txt", k)))
fpaths  <- as.character(fpaths[,1])

#' Let's first load all the data
cat("load data\n")
dats    <- llply(fpaths, function(f) {
    as.big.matrix(read.nifti.image(f))
}, .progress="text")
nvoxs   <- ncol(dats[[1]])
ntpts   <- nrow(dats[[1]])

if (is.null(start_vox)) start_vox <- 1
if (is.null(end_vox)) end_vox <- nvoxs

#' Let's write the code to compute MDMR for one voxel
#' We want to compute the connectivity pattern
cat("compute connectivity\n")
cmats   <- llply(dats, function(timeseries) {
    vbca2(timeseries, c(start_vox, end_vox), ztransform=TRUE)
}, .progress="text")

#sca.bmat    <- as.big.matrix(sca.mat)
#design      <- formula_to_bmat( ~ Age + Sex + FSIQ + short_meanFD, phenos)
#resid       <- qlm_residuals(sca.bmat, design)

cat("other setup\n")
nsubs    <- length(cmats)
grp      <- rep(c(0,1), each=nsubs/2)
grp      <- sample(grp)
design   <- data.frame(group=as.factor(grp))

effects  <- c(seq(0,0.5,by=0.05), seq(0.6,1,by=0.1))
nodes    <- round(c(0,0.05,0.1,0.25,0.5,1) * nvoxs)  # based on Zapala et al., 2012
opts     <- expand.grid(list(effect=effects, num_nodes_to_change=nodes))
opts$i   <- 1:nrow(opts)

voxs     <- start_vox:end_vox
vox_inds <- 1:length(voxs)

cat("distances and mdmr\n")
ret <- dlply(opts, .(effect, num_nodes_to_change), function(opt) {
    effect <- opt$effect
    num_nodes_to_change <- opt$num_nodes_to_change
    cat("i:", opt$i, "-", "effect:", effect, "-", "nodes:", num_nodes_to_change, "\n")
    
    ptm <- proc.time()
    
    #' Then regress out all other effects (columns in Age, Sex, FSIQ, short_meanFD)
    dmats    <- big.matrix(nsubs^2, length(voxs))
    glm.ps   <- big.matrix(nvoxs, length(voxs))
    cnodes   <- big.matrix(nvoxs, length(voxs), init=0)
    
    cat("compute connectivity and distances while regressing out other effects\n")
    l_ply(vox_inds, function(i) {
        vox <- voxs[i]
        
        # get residual subject maps
        sca.mat  <- t(sapply(cmats, function(cmat) cmat[i,]))
        res      <- lm(sca.mat ~ Age + Sex + FSIQ + short_meanFD, phenos)
        sub.maps <- res$residuals
        
        # scale
        sub.maps <- t(scale(t(sub.maps)))
        
        #' Add in the effect
        nodes_to_change <- sample(1:nvoxs, num_nodes_to_change)
        sub.maps[grp==1, nodes_to_change] <- sub.maps[grp==1, nodes_to_change] + effect
        cnodes[nodes_to_change,i] <- 1

        #' Compute distance
        dmat      <- dist(sub.maps, method="euclidean")
        dmats[,i] <- as.vector(as.matrix(dmat))
        
        #' MDMR
        # wait to do it later
        
        ##' Calculate GLM
        glm.res   <- lm(sub.maps ~ group, data=design)
        glm.sum   <- summary(glm.res)
        
        ps        <- sapply(glm.sum, function(z) z$coefficients[2,4])    # group effect significance
        ps[is.na(ps)] <- 0
        glm.ps[,i]<- as.numeric(ps)
        
        #' Clean up
        rm(sca.mat, res, sub.maps, dmat, glm.res, glm.sum)
    }, .progress="text")

    #' gower center
    cat("gower centering\n")
    gmats <- gower.subdist2(dmats, verbose=F)

    #' then call MDMR
    cat("mdmr\n")
    mdmr.res <- mdmr(gmats, ~ group, design)
    
    #' summarize glm
    cat("summarize glm\n")
    glm.pos <- colSums(glm.ps[,] < 0.05)
    glm.tp  <- sapply(vox_inds, function(i) {
        sum(glm.ps[cnodes[,i]==1,i] < 0.05)
    })
    glm.fp  <- glm.pos - glm.tp
    
    #' other stuff
    cat("compile\n")
    res <- list(
        i = opt$i, 
        effect = effect, 
        num_nodes_to_change = num_nodes_to_change, 
        mdmr = mdmr.res$pvals[,], 
        glm = glm.pos, 
        glm.tp = glm.tp, 
        glm.fp = glm.fp
    )
    
    #' clean up
    rm(dmats, gmats, glm.ps)
    
    cat("done\n")
    res$time <- proc.time() - ptm
    print(res$time)
    
    cat("\n")
    
    res
})


cat("saving\n")
outdir  <- sprintf("/home2/data/Projects/CWAS/simulations/k%04i", k)
outfile <- file.path(outdir, sprintf("voxs_%04i-%04i.rda", start_vox, end_vox))
save(ret, file=outfile)

cat("really done now\n")
elapsed <- proc.time() - start.time
print(elapsed)














# NOTE USED
# Assumes a multiple regression model
calc.rsquared <- function(z) {
    rdf <- z$df.residual
    r <- z$residuals
    f <- z$fitted.values
    
    # R^2
    if (attr(z$terms, "intercept")) {
        f.demean <- apply(f, 2, function(ff) ff - mean(ff))
        mss <- colSums(f.demean^2)
        #mss <- colSums((f - mean(f))^2)
    } else {
        mss <- colSums(f^2)
        #mss <- sum(f^2)
    }
    rss <- colSums(r^2)
    #rss <- sum(r^2)
    r.squared <- mss/(mss+rss)

    # Adjust R^2
    Qr <- qr(z)
    n <- NROW(Qr$qr)
    if (attr(z$terms, "intercept")) {
        df.int <- 1L
    } else {
        df.int <- 0L
    }
    adj.r.squared <- 1 - (1 - r.squared) * ((n - df.int)/rdf)
    
    list(r.squared=r.squared, adj.r.squared=adj.r.squared)
}
