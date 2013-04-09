# This script compares the results of doing ROI => voxels
# to voxelwise => voxelwise

base <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"
library(niftir)
library(ggplot2)
library(epiR)

# Read in the mask
maskfile <- file.path(base, "voxelwise", "mask.nii.gz")
mask <- read.mask(maskfile)

# Number of Parcelations/Voxels
xs <- c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400, sum(mask))

# Output path
dir.create("/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/Rplots")
dir.create("/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/Rplots/parcels2voxs")
setwd("/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/Rplots/parcels2voxs")

# ROI Labels
labels <- c("rvs0025", "rvs0050", "rvs0100", "rvs0200", "rvs0400", 
            "rvs0800", "rvs1600", "rvs3200", "rvs6400", 
            "rvr0025", "rvr0050", "rvr0100", "rvr0200", "rvr0400", 
            "rvr0800", "rvr1600", "rvr3200", "rvr6400", 
            "voxelwise")

# Functions
dice <- function(a,b) {
    (2*sum(a&b))/sum(a+b)
}

dice.mat <- function(a, b, z=0) {
    xa <- a > z; xb <- b > z
    mat <- matrix(1, ncol(xa), ncol(xb))
    inds <- expand.grid(list(a=1:ncol(xa), b=1:ncol(xb)))
    for (ri in 1:nrow(inds)) {
        i <- inds[ri,1]; j <- inds[ri,2]
        mat[i,j] <- dice(xa[,i], xb[,j])
    }
    mat
}

concordance.mat <- function(xa, xb) {
    mat <- matrix(1, ncol(xa), ncol(xb))
    inds <- expand.grid(list(a=1:ncol(xa), b=1:ncol(xb)))
    for (ri in 1:nrow(inds)) {
        i <- inds[ri,1]; j <- inds[ri,2]
        mat[i,j] <- epi.ccc(xa[,i], xb[,j])$rho.c$est
    }
    mat
}


###
# Age
###

# Read in the zstats
zstat_files1 <- Sys.glob(file.path(base, "rois-to-voxel_k*", "age+gender_with-meanFD_15k_rhs.mdmr", "zstats_age.nii.gz"))
zstat_files2 <- Sys.glob(file.path(base, "rois-to-voxel_random_k*", "age+gender_with-meanFD_15k_rhs.mdmr", "zstats_age.nii.gz"))
zstat_files3 <- file.path(base, "voxelwise", "age+gender_with-meanFD_15k_rhs.mdmr", "zstats_age.nii.gz")
zstat_files <- c(zstat_files1, zstat_files2, zstat_files3)
zstats <- sapply(zstat_files, function(f) read.nifti.image(f)[mask])
colnames(zstats) <- labels

# 1. Want the correlation with voxelwise results
cor_dice <- as.vector(dice.mat(zstats, zstats[,ncol(zstats),drop=F], 1.65))
cor_pearson <- cor(zstats, method="p")[,ncol(zstats)]
cor_spearman <- cor(zstats, method="s")[,ncol(zstats)]
cor_concordance <- as.vector(concordance.mat(zstats, zstats[,ncol(zstats),drop=F]))

# 2. Want the number of significant voxels
num_sig <- apply(zstats, 2, function(x) sum(x>1.65))
percent_sig <- apply(zstats, 2, function(x) mean(x>1.65))

# 3. Setup plot
slabs <- c(rep(c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400), 2), sum(mask))
tlabs <- c(rep(c("standard", "random"), c(9,9)), "voxelwise")
df <- data.frame(
    size = slabs, 
    target = tlabs, 
    log.size = log(slabs), 
    log10.size = log10(slabs), 
    significant = percent_sig * 100, 
    dice = cor_dice, 
    pearson = cor_pearson, 
    spearman = cor_spearman, 
    concordance = cor_concordance
)

# 4. Plot percent of significant voxels
## with limited y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=significant)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_nsig_ylim_age.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=significant)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,100)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_nsig_yall_age.png")
dev.off()

# 5. Plot of dice btw parcellations vs voxelwise
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=dice)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_dice_ylim_age.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=dice)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,1)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_dice_yall_age.png")
dev.off()

# 6. Plot of pearson btw parcellations vs voxelwise
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=pearson)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_pearson_ylim_age.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=pearson)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,1)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_pearson_yall_age.png")
dev.off()

# 7. Plot of spearman btw parcellations vs voxelwise
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=spearman)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_spearman_ylim_age.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=spearman)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,1)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_spearman_yall_age.png")
dev.off()

# 8. Plot of concordance btw parcellations vs voxelwise
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=concordance)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_concordance_ylim_age.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=concordance)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,1)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_concordance_yall_age.png")
dev.off()



###
# Sex
###

# Read in the zstats
zstat_files1 <- Sys.glob(file.path(base, "rois-to-voxel_k*", "age+gender_with-meanFD_15k_rhs.mdmr", "zstats_sex.nii.gz"))
zstat_files2 <- Sys.glob(file.path(base, "rois-to-voxel_random_k*", "age+gender_with-meanFD_15k_rhs.mdmr", "zstats_sex.nii.gz"))
zstat_files3 <- file.path(base, "voxelwise", "age+gender_with-meanFD_15k_rhs.mdmr", "zstats_sex.nii.gz")
zstat_files <- c(zstat_files1, zstat_files2, zstat_files3)
zstats <- sapply(zstat_files, function(f) read.nifti.image(f)[mask])
colnames(zstats) <- labels

# 1. Want the correlation with voxelwise results
cor_dice <- as.vector(dice.mat(zstats, zstats[,ncol(zstats),drop=F], 1.65))
cor_pearson <- cor(zstats, method="p")[,ncol(zstats)]
cor_spearman <- cor(zstats, method="s")[,ncol(zstats)]
cor_concordance <- as.vector(concordance.mat(zstats, zstats[,ncol(zstats),drop=F]))

# 2. Want the number of significant voxels
num_sig <- apply(zstats, 2, function(x) sum(x>1.65))
percent_sig <- apply(zstats, 2, function(x) mean(x>1.65))

# 3. Setup plot
slabs <- c(rep(c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400), 2), sum(mask))
tlabs <- c(rep(c("standard", "random"), c(9,9)), "voxelwise")
df <- data.frame(
    size = slabs, 
    target = tlabs, 
    log.size = log(slabs), 
    log10.size = log10(slabs), 
    significant = percent_sig * 100, 
    dice = cor_dice, 
    pearson = cor_pearson, 
    spearman = cor_spearman, 
    concordance = cor_concordance
)

# 4. Plot percent of significant voxels
## with limited y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=significant)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_nsig_ylim_sex.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=significant)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,100)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_nsig_yall_sex.png")
dev.off()

# 5. Plot of dice btw parcellations vs voxelwise
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=dice)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_dice_ylim_sex.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=dice)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,1)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_dice_yall_sex.png")
dev.off()

# 6. Plot of pearson btw parcellations vs voxelwise
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=pearson)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_pearson_ylim_sex.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=pearson)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,1)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_pearson_yall_sex.png")
dev.off()

# 7. Plot of spearman btw parcellations vs voxelwise
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=spearman)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_spearman_ylim_sex.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=spearman)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,1)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_spearman_yall_sex.png")
dev.off()

# 8. Plot of concordance btw parcellations vs voxelwise
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=concordance)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_concordance_ylim_sex.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=concordance)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,1)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("parcels2voxs_concordance_yall_sex.png")
dev.off()

