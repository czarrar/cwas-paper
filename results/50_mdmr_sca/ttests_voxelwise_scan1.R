#!/usr/bin/env Rscript

###
# SETUP
###

cat("Setup\n")

library(plyr)
suppressPackageStartupMessages(library(niftir))

base        <- "/home/data/Projects/CWAS"
indir       <- file.path(base, "nki/sca_voxelwise_scan1/30_sca")
odir        <- file.path(base, "results/50_mdmr_sca")


###
# LOAD
###

cat("Load\n")

# Load the data
df          <- read.csv(file.path(indir, "rois_glm+mdmr.csv"))
df.scan1    <- subset(df, scan=="short")
df.scan2    <- subset(df, scan=="medium")

# Setup the pairs of ROI types to compare
roi_types   <- c("maxima", "significant", "not-significant", "minima")
comp_rois   <- expand.grid(list(x=roi_types, y=roi_types))
comp_rois   <- comp_rois[comp_rois$x != comp_rois$y,]
comp_rois   <- cbind(index=1:nrow(comp_rois), comp_rois)


###
# COMPARE
###

cat("Compare\n")

# Compare Scan 1
comp.scan1  <- ddply(comp_rois, .(index), function(row) {
    name1   <- as.character(row$x)
    name2   <- as.character(row$y)
    res     <- t.test(df.scan1$sca[df.scan1$label==name1], df.scan1$sca[df.scan1$label==name2])
    c(x=name1, y=name2, round(res$statistic, 4), round(res$parameter, 4), p=res$p.value)
})
o <- c(which(comp.scan1$x == "maxima"), which(comp.scan1$x == "significant"), which(comp.scan1$x == "not-significant"), which(comp.scan1$x == "minima"))
comp.scan1 <- comp.scan1[o,]
comp.scan1$sig <- (as.numeric(comp.scan1$p) < 0.05) * 1
comp.scan1$p <- sprintf("%.4e", as.numeric(comp.scan1$p))

# Compare Scan 2
comp.scan2  <- ddply(comp_rois, .(index), function(row) {
    name1   <- as.character(row$x)
    name2   <- as.character(row$y)
    res     <- t.test(df.scan2$sca[df.scan2$label==name1], df.scan2$sca[df.scan2$label==name2])
    c(x=name1, y=name2, round(res$statistic, 4), round(res$parameter, 4), p=res$p.value)
})
o <- c(which(comp.scan2$x == "maxima"), which(comp.scan2$x == "significant"), which(comp.scan2$x == "not-significant"), which(comp.scan2$x == "minima"))
comp.scan2 <- comp.scan2[o,]
comp.scan2$sig <- (as.numeric(comp.scan2$p) < 0.05) * 1
comp.scan2$p <- sprintf("%.4e", as.numeric(comp.scan2$p))


###
# SAVE
###

cat("Save\n")

comp <- cbind(
    scan=rep(c("Scan 1", "Scan 2"), each=nrow(comp.scan1)), 
    rbind(comp.scan1[,-1], comp.scan2[,-1])
)
print(comp)

write.csv(comp, file=file.path(odir, "ttests_voxelwise_scan1.csv"))
