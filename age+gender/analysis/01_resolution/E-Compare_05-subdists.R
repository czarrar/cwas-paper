# This script will compare the similarity of each ROI-based distances to voxelwise

###
# 1. Setup
###

library(connectir)
library(ggplot2)
library(reshape)

basedir <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"

ks <- c(25,50,100,200,400,800,1600,3200,6400)
nk <- length(ks)

# Load subject distances
## for each ROI
roi.sdirs <- file.path(basedir, sprintf("rois_k%04i", ks))
roi.sfiles <- file.path(roi.sdirs, "subdist.desc")
roi.subdists <- lapply(roi.sfiles, attach.big.matrix)
## for voxelwise
vox.sdir <- file.path(basedir, "voxelwise")
vox.sfile <- file.path(vox.sdir, "subdist.desc")
vox.subdist <- attach.big.matrix(vox.sfile)
nvoxs <- ncol(vox.subdist)

# Number of subjects
nsubs <- sqrt(nrow(vox.subdist))

# Lower half of row indices
tmp <- matrix(1:nrow(vox.subdist), nsubs, nsubs)
row.inds <- which(lower.tri(tmp))
nr <- length(row.inds)

# Matrix to hold correlation between subject distances
odir <- file.path(basedir, "combined_rois+voxelwise")
sim.subdists <- big.matrix(nk, nvoxs, type="double", shared=TRUE, 
                            backingpath=odir, 
                            backingfile="compare_sdists_rois.bin", 
                            descriptorfile="compare_sdists_rois.desc")


###
# 2. Compute correlations
###

# This function combines a given voxel's distances across ROIs into a matrix
combine_roidists <- function(roi.subdists, col)
{
    bm.subdists <- big.matrix(nr, nk, type="double", shared=FALSE)
    for (i in 1:nk) {
        bedeepcopy(x=roi.subdists[[i]], x.rows=row.inds, x.cols=col, 
                   y=bm.subdists, y.cols=i)
    }
    return(bm.subdists)
}

# Calculate the correlation between each ROI-based distances with the 
# voxelwise distances for each voxel
l_ply(1:nvoxs, function(vi) {
    bm.subdists <- combine_roidists(roi.subdists, vi)
    ref.subdist <- deepcopy(vox.subdist, rows=row.inds, cols=vi)
    zs <- big_cor(x=bm.subdists, y=ref.subdist)
    bedeepcopy(x=zs, y=sim.subdists, y.cols=vi)
}, .progress="text")

# Remove the correlation between distances
rm(sim.subdists); gc(F,T)


###
# 3. Plot
###

# Re-load
ssdesc <- file.path(basedir, "combined_rois+voxelwise", 
                    "compare_sdists_rois.desc")
sim.subdists <- attach.big.matrix(ssdesc)

# Conform to data frame
smat <- sim.subdists[,]
dimnames(smat) <- list(rois=ks, voxels=1:ncol(smat))
df <- melt(smat)

# Plot
setwd("/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/combined_rois+voxelwise")
x11(width=10, height=6)
ggplot(df, aes(factor(rois), value)) + geom_violin() + 
    stat_summary(fun.y=mean, geom="point",fill="black", shape=21, size=3) + 
    theme(axis.text = element_text(face="bold", size=20), axis.title=element_blank())
ggsave("compare_subdists.png")
dev.off()
