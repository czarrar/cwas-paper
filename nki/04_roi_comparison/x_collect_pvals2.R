#!/usr/bin/env Rscript

library(niftir)
library(ggplot2)

# This looks through the only ROIs


# Goal: To gather all the p-values (uncorrected and corrected) into a matrix in a meaningful way

# 1. gather names of paths
# 2. gather matrix of unsmoothed vs smoothed with all the rois and voxelwise data
# 3. do same for uncorrected and corrected

####
# Setup
####

base  <- "/home2/data/Projects/CWAS/nki/cwas"
scans <- c("short", "medium")

# mask
mask_file <- "/home/data/Projects/CWAS/nki/rois/mask_gray_4mm.nii.gz"
mask <- read.mask(mask_file)

outdir <- "/home2/data/Projects/CWAS/figures/sfig_roi_comparison"
if (!file.exists(outdir)) dir.create(outdir)

ks <- c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400)
str_ks1 <- sprintf("only_rois_random_k%04i", ks)
str_ks2 <- sprintf("rois_random_k%04i", ks)
voxels <- "kvoxs_smoothed_to_kvoxs"
all_ks <- c(str_ks1, str_ks2, voxels)

mdmr_name <- "iq_age+sex+meanFD.mdmr"

#' MDMR Directories
mdmr_dirs <- ldply(scans, function(scan) {
  paths <- file.path(base, scan, sprintf("compcor_%s", all_ks), mdmr_name)
  n <- length(paths)
  data.frame(
    seed.k    = c(ks, ks, sum(mask)), 
    target.k  = c(ks, rep(sum(mask), length(ks)+1)), 
    scan      = rep(scan, n), 
    corrected = rep("no", n), 
    paths     = paths
  )
})

#' Uncorrected P-Values
uncorrected <- mdmr_dirs
uncorrected$paths <- file.path(mdmr_dirs$paths, "cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz")
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
res.df <- subset(df, select=c("index", "seed.k", "target.k", "scan", "corrected"))
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

# Similarity to the last (voxelwise scan)
dice_to_ref <- daply(df, .(index), function(sdf) {
    rindex <- sdf$index
    cindex <- subset(df, seed.k==sum(mask) & target.k==sum(mask) & scan==sdf$scan & corrected==sdf$corrected)$index
    dice(res[,rindex], res[,cindex])
})
sim_to_ref <- daply(df, .(index), function(sdf) {
    rindex <- sdf$index
    cindex <- subset(df, seed.k==sum(mask) & target.k==sum(mask) & scan==sdf$scan & corrected==sdf$corrected)$index
    sum((res[,rindex] > 1.65) & (res[,cindex] > 1.65))/(sum(res[,cindex] > 1.65))
})
res.df$dice2ref <- dice_to_ref
res.df$sim2ref  <- sim_to_ref


####
# ?
####

# Focus
# 1. only on the permutation corrected scan
# 3. average across scans
sdf0 <- subset(res.df, corrected == 'GRF')
sdf1 <- ddply(sdf0, .(seed.k, target.k), function(sdf) {
  rdf <- sdf[1,]
  rdf$scan <- "combined"
  rdf$power <- mean(sdf$power)
  rdf$similarity <- mean(sdf$similarity)
  rdf$dice <- mean(rdf$dice)
  rdf$dice2ref <- mean(rdf$dice2ref)
  rdf$sim2ref <- mean(rdf$sim2ref)
  return(rdf)
}) 
sdf <- sdf1

all.ks <- c(ks, sum(mask))
str.ks <- c(ks, sprintf("%i\n(smoothed voxels)", sum(mask)))

ssdf <- subset(sdf, seed.k==target.k | sum(seed.k)==sum(mask))
write.table(ssdf, file=file.path(outdir, "0_dataframe.txt"))

p <- ggplot(ssdf, aes(x=log(seed.k), y=power*100)) + 
  geom_point() + 
  geom_line() + 
  xlab("Number of Parcellations") + 
  ylab("Percent of Significant Voxels") + 
  scale_x_continuous(breaks=log(all.ks), labels=str.ks)
plot(p)
ggsave(file.path(outdir, "A_only_rois_power.png"))

p <- ggplot(ssdf, aes(x=log(seed.k), y=dice)) + 
  geom_point() + 
  geom_line() + 
  xlab("Number of Parcellations") + 
  ylab("Overlap Between Scans (dice)") + 
  scale_x_continuous(breaks=log(all.ks), labels=str.ks)
plot(p)
ggsave(file.path(outdir, "B_only_rois_overlap_between_scans.png"))

p <- ggplot(ssdf, aes(x=log(seed.k), y=dice2ref)) + 
    geom_point() + 
    geom_line() + 
    xlab("Number of Parcellations") + 
    ylab("Dice Overlap with Voxelwise") + 
    scale_x_continuous(breaks=log(all.ks), labels=str.ks)
plot(p)
ggsave(file.path(outdir, "C_only_rois_overlap_with_voxelwise_dice.png"))

p <- ggplot(ssdf, aes(x=log(seed.k), y=sim2ref)) + 
    geom_point() + 
    geom_line() + 
    xlab("Number of Parcellations") + 
    ylab("Percent Overlap with Voxelwise") + 
    scale_x_continuous(breaks=log(all.ks), labels=str.ks)
plot(p)
ggsave(file.path(outdir, "D_only_rois_overlap_with_voxelwise_percent.png"))
