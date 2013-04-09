# This script compares the results of doing voxelwise => ROI
# to voxelwise => voxelwise

base <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"
library(niftir)
library(ggplot2)

# Read in the mask
maskfile <- file.path(base, "voxelwise", "mask.nii.gz")
mask <- read.mask(maskfile)

xs <- c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400, sum(mask))

dir.create("/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/combined_rois+voxelwise")
setwd("/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/combined_rois+voxelwise")


###
# Age
###

basedir <- "/home2/data/Projects/CWAS"
labels <- c("rr_k0025", "rr_k0050", "rr_k0100", "rr_k0200", "rr_k0400", 
            "rr_k0800", "rr_k1600", "rr_k3200", "rr_k6400", "rv_voxel")

# Read in the zstats as matrices
find_dirs <- c("roi-k3200_with_roi-k*", "rois-to-voxel_k3200")
zstat_files <- Sys.glob(file.path(base, find_dirs, "age+gender_with-meanFD_15k_rhs.mdmr", 
                        "pvals.desc"))
zstats <- sapply(zstat_files, function(f) 
                    qt(attach.big.matrix(f)[,1], Inf, lower.tail=F))
colnames(zstats) <- labels

# 1. Want the correlation with voxelwise results
cor_with_voxelwise <- cor(zstats, method="s")[,ncol(zstats)]

# 2. Want the number of significant voxels
num_sig <- apply(zstats, 2, function(x) sum(x>1.65))
percent_sig <- apply(zstats, 2, function(x) mean(x>1.65))

# 3. Plots
## data frame
df <- data.frame(
    size = xs, 
    log.size = log(xs), 
    log10.size = log10(xs), 
    significant = percent_sig * 100, 
    r = cor_with_voxelwise
)
## percent of significant voxels
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=significant)) + 
    geom_point(size=3) + 
    geom_smooth(method=lm, se=FALSE) + 
    scale_x_continuous(breaks=df$log.size, labels=xs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("plots_roi_k3200_age_percent_significant.png")
dev.off()
## correlation with voxelwise results
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=r)) + 
    geom_point(size=3) + 
    geom_smooth(method=lm, se=FALSE) + 
    scale_x_continuous(breaks=df$log.size, labels=xs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("plots_roi_k3200_age_correlation_with_voxelwise.png")
dev.off()


###
# Gender
###

basedir <- "/home2/data/Projects/CWAS"
labels <- c("rr_k0025", "rr_k0050", "rr_k0100", "rr_k0200", "rr_k0400", 
            "rr_k0800", "rr_k1600", "rr_k3200", "rr_k6400", "rv_voxel")

# Read in the zstats as matrices
find_dirs <- c("roi-k3200_with_roi-k*", "rois-to-voxel_k3200")
zstat_files <- Sys.glob(file.path(base, find_dirs, "age+gender_with-meanFD_15k_rhs.mdmr", 
                        "pvals.desc"))
zstats <- sapply(zstat_files, function(f) 
                    qt(attach.big.matrix(f)[,2], Inf, lower.tail=F))
colnames(zstats) <- labels

# 1. Want the correlation with voxelwise results
cor_with_voxelwise <- cor(zstats, method="s")[,ncol(zstats)]

# 2. Want the number of significant voxels
num_sig <- apply(zstats, 2, function(x) sum(x>1.65))
percent_sig <- apply(zstats, 2, function(x) mean(x>1.65))

# 3. Plots
## data frame
df <- data.frame(
    size = xs, 
    log.size = log(xs), 
    log10.size = log10(xs), 
    significant = percent_sig * 100, 
    r = cor_with_voxelwise
)
## percent of significant voxels
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=significant)) + 
    geom_point(size=3) + 
    geom_smooth(method=lm, se=FALSE) + 
    scale_x_continuous(breaks=df$log.size, labels=xs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("plots_roi_k3200_gender_percent_significant.png")
dev.off()
## correlation with voxelwise results
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=r)) + 
    geom_point(size=3) + 
    geom_smooth(method=lm, se=FALSE) + 
    scale_x_continuous(breaks=df$log.size, labels=xs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("plots_roi_k3200_gender_correlation_with_voxelwise.png")
dev.off()


