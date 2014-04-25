#!/usr/bin/env Rscript

library(niftir)
library(ggplot2)


# Goal: To gather all the p-values (uncorrected and corrected) into a matrix in a meaningful way

# 1. gather names of paths
# 2. gather matrix of unsmoothed vs smoothed with all the rois and voxelwise data
# 3. do same for uncorrected and corrected

####
# Setup
####

base  <- "/home2/data/Projects/CWAS/nki/cwas"
scans <- c("short", "medium")

ks <- c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400)
str_ks <- sprintf("rois_random_k%04i", ks)
voxels <- c("kvoxs_to_kvoxs", "kvoxs_smoothed_to_kvoxs")
#voxels <- c("kvoxs_to_kvoxs")

outdir <- "/home2/data/Projects/CWAS/figures/sfig_roi_comparison"

mdmr_name <- "iq_age+sex+meanFD.mdmr"

# mask
mask_file <- "/home/data/Projects/CWAS/nki/rois/mask_gray_4mm.nii.gz"
mask <- read.mask(mask_file)

#' MDMR Directories
unsmoothed_mdmr <- ldply(scans, function(scan) {
    paths <- file.path(base, scan, sprintf("compcor_%s", c(str_ks, voxels)), mdmr_name)
    n <- length(paths)
    data.frame(
        k         = c(ks, sum(mask), sum(mask)), 
#        k         = c(ks, sum(mask)), 
        scan      = rep(scan, n), 
        corrected = rep("no", n), 
        ref.smooth= rep(c("no", "yes"), c(n-1, 1)), 
        smoothed  = rep("no", n), 
        paths     = paths
    )
})
smoothed_mdmr <- ldply(scans, function(scan) {
    paths <- file.path(base, scan, sprintf("compcor_%s_smoothed", c(str_ks, voxels)), mdmr_name)
    n <- length(paths)
    data.frame(
        k         = c(ks, sum(mask), sum(mask)), 
#        k         = c(ks, sum(mask)), 
        scan      = rep(scan, n), 
        ref.smooth= rep(c("no", "yes"), c(n-1, 1)), 
        corrected = rep("yes", n), 
        smoothed  = rep("yes", n), 
        paths     = paths
    )
})
mdmr_dirs <- rbind(unsmoothed_mdmr, smoothed_mdmr)

#' Uncorrected P-Values
uncorrected <- mdmr_dirs
uncorrected$paths <- file.path(uncorrected$paths, "cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz")
uncorrected$corrected <- "no"

#' GRF Corrected P-Values
grf.corrected <- mdmr_dirs
grf.corrected$paths <- file.path(mdmr_dirs$paths, "cluster_correct_v05_c05/easythresh/thresh_zstat_FSIQ.nii.gz")
grf.corrected$corrected <- "GRF"

#' Permuted Corrected P-Values
perm.corrected <- mdmr_dirs
perm.corrected$paths <- file.path(mdmr_dirs$paths, "cluster_correct_v05_c05/clust_logp_FSIQ.nii.gz")
perm.corrected$corrected <- "permutation"

#' Combine
df <- rbind(uncorrected, grf.corrected, perm.corrected)
df$corrected <- as.factor(df$corrected)

#' Subject Distances Paths
df$subpaths <- dirname(dirname(dirname(dirname(df$paths))))

df <- cbind(index=1:nrow(df), df)


####
# Read
####

res <- daply(df, .(index), function(sdf) {
    sapply(sdf$paths, function(f) read.nifti.image(f)[mask])
}, .progress="text")
res <- t(res)


####
# Summarize
####

# Power
res.df <- subset(df, select=c("index", "k", "scan", "corrected", "smoothed", "ref.smooth"))
res.df$power <- colMeans(res>1.65)

# Similarity across scans
inds <- cbind(short=res.df$index[res.df$scan=="short"], medium=res.df$index[res.df$scan=="medium"])
## pearson
sim  <- apply(inds, 1, function(row) cor(res[,row[1]], res[,row[2]], method="s"))
res.df$similarity[as.vector(inds)] <- rep(sim, 2)
## dice
dice <- function(x,y,thr=1.65) {
  tx <- x > thr
  ty <- y > thr
  (2*sum(tx&ty))/(sum(tx)+sum(ty))
}
sim  <- apply(inds, 1, function(row) dice(res[,row[1]], res[,row[2]]))
res.df$dice[as.vector(inds)] <- rep(sim, 2)


####
# ?
####

# Focus
# 1. only on the permutation corrected scan
# 2. only on the non-smoothed ref data
# 3. average across scans
sdf0 <- subset(res.df, corrected == 'GRF' & ref.smooth == 'no')
sdf1 <- ddply(sdf0, .(k, smoothed), function(sdf) {
  rdf <- sdf[1,]
  rdf$scan <- "combined"
  rdf$power <- mean(sdf$power)
  rdf$similarity <- mean(sdf$similarity)
  rdf$dice <- mean(rdf$dice)
  return(rdf)
}) 
sdf <- sdf1

all.ks <- c(ks, sum(mask))
str.ks <- c(ks, sprintf("%i\n(voxs)", sum(mask)))

p <- ggplot(sdf, aes(x=log(k), y=power*100, linetype=smoothed)) + 
  geom_point() + 
  geom_line() + 
  xlab("Number of Parcellations") + 
  ylab("Percent of Significant Voxels") + 
  scale_x_continuous(breaks=log(all.ks), labels=str.ks)
plot(p)
ggsave(file.path(outdir, "B_GRF_power.png"))

p <- ggplot(sdf, aes(x=log(k), y=dice, linetype=smoothed)) + 
  geom_point() + 
  geom_line() + 
  xlab("Number of Parcellations") + 
  ylab("Overlap Between Scans (dice)") + 
  scale_x_continuous(breaks=log(all.ks), labels=str.ks)
plot(p)
ggsave(file.path(outdir, "B_GRF_overlap_between_scans.png"))


####
# ?
####

# Focus
# 1. only on the unsmoothed scan
# 2. average across scans
sdf0 <- subset(res.df, smoothed == 'no' & ref.smooth == 'no')
sdf1 <- ddply(sdf0, .(k, corrected), function(sdf) {
  rdf <- sdf[1,]
  rdf$scan <- "combined"
  rdf$power <- mean(sdf$power)
  rdf$similarity <- mean(sdf$similarity)
  rdf$dice <- mean(sdf$dice)
  return(rdf)
}) 
sdf <- sdf1

all.ks <- c(ks, sum(mask))
str.ks <- c(ks, sprintf("%i\n(voxs)", sum(mask)))

p <- ggplot(sdf, aes(x=log(k), y=power*100, color=corrected)) + 
  geom_point() + 
  geom_line() + 
  xlab("Number of Parcellations") + 
  ylab("Percent of Significant Voxels") + 
  scale_x_continuous(breaks=log(all.ks), labels=str.ks)
plot(p)
ggsave(file.path(outdir, "C_nosmooth_power.png"))

p <- ggplot(sdf, aes(x=log(k), y=dice, color=corrected)) + 
  geom_point() + 
  geom_line() + 
  xlab("Number of Parcellations") + 
  ylab("Overlap Between Scans (dice)") + 
  scale_x_continuous(breaks=log(all.ks), labels=str.ks)
plot(p)
ggsave(file.path(outdir, "C_nosmooth_overlap_between_scans.png"))



####
# ?
####

# Focus
# 1. only on the voxelwise data
# 2. only with permutation corrected data 
# 3. average across scans
sdf0 <- subset(res.df, k == sum(mask) & corrected == "GRF")
sdf1 <- ddply(sdf0, .(k, smoothed, ref.smooth), function(sdf) {
  rdf <- sdf[1,]
  rdf$scan <- "combined"
  rdf$power <- mean(sdf$power)
  rdf$similarity <- mean(sdf$similarity)
  rdf$dice <- mean(sdf$dice)
  return(rdf)
}) 
sdf <- sdf1

p <- ggplot(sdf, aes(x=ref.smooth, y=power*100, fill=smoothed)) + 
  geom_bar(stat="identity", position="dodge") + 
  xlab("Smoothing of Seed Voxel") + 
  ylab("Percent of Significant Voxels")
plot(p)
ggsave(file.path(outdir, "D_voxelwise_power.png"))

p <- ggplot(sdf, aes(x=ref.smooth, y=dice, fill=smoothed)) + 
  geom_bar(stat="identity", position="dodge") + 
  xlab("Smoothing of Seed Voxel") + 
  ylab("Overlap Between Scans (dice)")
plot(p)
ggsave(file.path(outdir, "D_voxelwise_overlap_between_scans.png"))


