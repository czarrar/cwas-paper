# This script compares the results of doing voxelwise => ROI
# to voxelwise => voxelwise

base <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"
library(niftir)
library(ggplot2)

# Read in the mask
maskfile <- file.path(base, "voxelwise", "mask.nii.gz")
mask <- read.mask(maskfile)

# Number of Parcelations/Voxels
xs <- c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400, sum(mask))

# Output path
dir.create("/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/Rplots")
dir.create("/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/Rplots/voxs2parcels")
setwd("/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/Rplots/voxs2parcels")

# ROI Labels
labels <- c("vrs0025", "vrs0050", "vrs0100", "vrs0200", "vrs0400", 
            "vrs0800", "vrs1600", "vrs3200", "vrs6400", 
            "vrr0025", "vrr0050", "vrr0100", "vrr0200", "vrr0400", 
            "vrr0800", "vrr1600", "vrr3200", "vrr6400", 
            "voxelwise")


###
# Age
###

# Read in the zstats
zstat_files1 <- Sys.glob(file.path(base, "rois_k*", "age+gender_with-meanFD_15k_rhs.mdmr", 
                         "zstats_age.nii.gz"))
zstat_files2 <- Sys.glob(file.path(base, "rois_random_k*", "age+gender_with-meanFD_15k_rhs.mdmr", 
                         "zstats_age.nii.gz"))
zstat_files3 <- file.path(base, "voxelwise", "age+gender_with-meanFD_15k_rhs.mdmr", "zstats_age.nii.gz")
zstat_files <- c(zstat_files1, zstat_files2, zstat_files3)
zstats <- sapply(zstat_files, function(f) read.nifti.image(f)[mask])
colnames(zstats) <- labels

# 1. Want the correlation with voxelwise results
cor_with_voxelwise <- cor(zstats, method="s")[,ncol(zstats)]

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
    r = cor_with_voxelwise
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
ggsave("voxs2parcels_nsig_ylim_age.png")
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
ggsave("voxs2parcels_nsig_yall_age.png")
dev.off()

# 5. Plot of correlations between parcellations vs voxelwise
ggplot(df, aes(x=log.size, y=r)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("voxs2parcels_corr_ylim_age.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=r)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,1)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("voxs2parcels_corr_yall_age.png")
dev.off()


###
# Sex
###

# Read in the zstats
zstat_files1 <- Sys.glob(file.path(base, "rois_k*", "age+gender_with-meanFD_15k_rhs.mdmr", 
                         "zstats_sex.nii.gz"))
zstat_files2 <- Sys.glob(file.path(base, "rois_random_k*", "age+gender_with-meanFD_15k_rhs.mdmr", 
                         "zstats_sex.nii.gz"))
zstat_files3 <- file.path(base, "voxelwise", "age+gender_with-meanFD_15k_rhs.mdmr", "zstats_sex.nii.gz")
zstat_files <- c(zstat_files1, zstat_files2, zstat_files3)
zstats <- sapply(zstat_files, function(f) read.nifti.image(f)[mask])
colnames(zstats) <- labels

# 1. Want the correlation with voxelwise results
cor_with_voxelwise <- cor(zstats, method="s")[,ncol(zstats)]

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
    r = cor_with_voxelwise
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
ggsave("voxs2parcels_nsig_ylim_sex.png")
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
ggsave("voxs2parcels_nsig_yall_sex.png")
dev.off()

# 5. Plot of correlations between parcellations vs voxelwise
ggplot(df, aes(x=log.size, y=r)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("voxs2parcels_corr_ylim_sex.png")
dev.off()
## with complete y-axis
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=r)) + 
    geom_point(aes(shape=target, color=target, size=3, alpha=0.75)) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    ylim(c(0,1)) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("voxs2parcels_corr_yall_sex.png")
dev.off()


