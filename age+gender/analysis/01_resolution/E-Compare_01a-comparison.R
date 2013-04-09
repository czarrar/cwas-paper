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

# ROIs
basedir <- "/home2/data/Projects/CWAS"
roidir <- file.path(basedir, "share/age+gender/analysis/01_resolution/rois")
roi.files <- Sys.glob(file.path(roidir, "rois_*.nii.gz"))
list.rois <- lapply(roi.files, function(f) {
    nii <- read.nifti.image(f)
    nii[mask]
})
list.rois <- c(list.rois, list.rois)
nrois <- length(list.rois)

labels <- c("vrs0025", "vrs0050", "vrs0100", "vrs0200", "vrs0400", 
            "vrs0800", "vrs1600", "vrs3200", "vrs6400", 
            "vrr0025", "vrr0050", "vrr0100", "vrr0200", "vrr0400", 
            "vrr0800", "vrr1600", "vrr3200", "vrr6400", 
            "rvs0025", "rvs0050", "rvs0100", "rvs0200", "rvs0400", 
            "rvs0800", "rvs1600", "rvs3200", "rvs6400", 
            "rvr0025", "rvr0050", "rvr0100", "rvr0200", "rvr0400", 
            "rvr0800", "rvr1600", "rvr3200", "rvr6400", 
            "voxelwise")

# Read in the zstats
zstat_files <- Sys.glob(file.path(base, "rois*", "age+gender_with-meanFD_15k_rhs.mdmr", 
                        "zstats_age.nii.gz"))
zstat_files <- c(zstat_files, file.path(base, "voxelwise", "age+gender_with-meanFD_15k_rhs.mdmr", "zstats_age.nii.gz"))
zstats1 <- sapply(zstat_files, function(f) read.nifti.image(f)[mask])
colnames(zstats1) <- labels

# Read in the zstats as matrices
zstat_files <- Sys.glob(file.path(base, "rois*", "age+gender_with-meanFD_15k_rhs.mdmr", 
                        "pvals.desc"))
zstat_files <- c(zstat_files, file.path(base, "voxelwise", "age+gender_with-meanFD_15k_rhs.mdmr", "pvals.desc"))
zstats2 <- lapply(zstat_files, function(f) 
                    qt(attach.big.matrix(f)[,1], Inf, lower.tail=F))
names(zstats2) <- labels

# Downsample the rois for voxel->roi
zstats3 <- zstats2
inds <- grep("rois_.*/", zstat_files)
for (i in inds) {
    rois <- list.rois[[i]]
    urois <- sort(unique(rois))
    urois <- urois[urois!=0]
    n <- length(urois)
    
    vec <- vector("numeric", n)
    for (ui in 1:length(urois)) {
        v <- zstats2[[i]][rois==urois[ui]]
        v <- v[is.finite(v)]    # ghetto fix
        vec[ui] <- mean(v)
    }
    zstats3[[i]] <- vec
}

# 1. Want the correlation with voxelwise results
cor_with_voxelwise <- cor(zstats1, method="s")[,ncol(zstats1)]

# 2. Want the correlation with the downsampled voxelwise results
cor_with_voxelwise_ds <- sapply(1:length(list.rois), function(i) {
    rois <- list.rois[[i]]
    urois <- sort(unique(rois))
    urois <- urois[urois!=0]
    n <- length(urois)
    
    vec <- vector("numeric", n)
    for (ui in 1:length(urois)) {
        v <- zstats3[[length(zstats3)]][rois==urois[ui]]
        v <- v[is.finite(v)]
        vec[ui] <- mean(v)
    }
    
    cor(zstats3[[i]], vec)
})
cor_with_voxelwise_ds <- c(cor_with_voxelwise_ds, 1)
names(cor_with_voxelwise_ds) <- labels

# 3. Want the number of significant voxels
num_sig <- apply(zstats1, 2, function(x) sum(x>1.65))
percent_sig <- apply(zstats1, 2, function(x) mean(x>1.65))

# 4. Plot
slabs <- c(rep(c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400), 4), sum(mask))
tlabs <- c(rep(rep(c("standard", "random"), c(9,9)), 2), "voxelwise")
elabs <- rep(c("voxel", "roi", "voxel"), c(18,18,1))
df <- data.frame(
    size = slabs, 
    target = tlabs, 
    seed = elabs, 
    log.size = log(slabs), 
    log10.size = log10(slabs), 
    significant = percent_sig * 100, 
    r = cor_with_voxelwise, 
    r.ds = cor_with_voxelwise_ds
)
## percent of significant voxels

# Feedback for changes in R
# - Remove the line fit
# - Have the y axis be both 0-100 and the best fit (so 2 graphs)

# Feedback for changes in Pages:
# - Label y as Percent Significant
# - Label x as Number of Parcellations 
# - Have (voxels) underneath voxels on x-axis

x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=significant)) + 
    geom_point(aes(shape=target, color=seed, size=3, alpha=0.75)) + 
    geom_smooth(aes(color=seed), method=lm, se=FALSE) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("plots_age_percent_significant_withseeds.png")
dev.off()
## correlation with voxelwise results
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=r)) + 
    geom_point(aes(shape=target, color=seed, size=3, alpha=0.75)) + 
    geom_smooth(aes(color=seed), method=lm, se=FALSE) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("plots_age_correlation_with_voxelwise_withseeds.png")
dev.off()
## correlation with voxelwise results (downsampled)
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=r.ds)) + 
    geom_point(aes(shape=target, color=seed, size=3, alpha=0.75)) + 
    geom_smooth(aes(color=seed), method=lm, se=FALSE) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("plots_age_correlation_with_voxelwise_withseeds.png")
dev.off()


###
# Gender
###

# ROIs
basedir <- "/home2/data/Projects/CWAS"
roidir <- file.path(basedir, "share/age+gender/analysis/01_resolution/rois")
roi.files <- Sys.glob(file.path(roidir, "rois_*.nii.gz"))
list.rois <- lapply(roi.files, function(f) {
    nii <- read.nifti.image(f)
    nii[mask]
})
list.rois <- c(list.rois, list.rois)
nrois <- length(list.rois)

labels <- c("vrs0025", "vrs0050", "vrs0100", "vrs0200", "vrs0400", 
            "vrs0800", "vrs1600", "vrs3200", "vrs6400", 
            "vrr0025", "vrr0050", "vrr0100", "vrr0200", "vrr0400", 
            "vrr0800", "vrr1600", "vrr3200", "vrr6400", 
            "rvs0025", "rvs0050", "rvs0100", "rvs0200", "rvs0400", 
            "rvs0800", "rvs1600", "rvs3200", "rvs6400", 
            "rvr0025", "rvr0050", "rvr0100", "rvr0200", "rvr0400", 
            "rvr0800", "rvr1600", "rvr3200", "rvr6400", 
            "voxelwise")

# Read in the zstats
zstat_files <- Sys.glob(file.path(base, "rois*", "age+gender_with-meanFD_15k_rhs.mdmr", 
                        "zstats_sex.nii.gz"))
zstat_files <- c(zstat_files, file.path(base, "voxelwise", "age+gender_with-meanFD_15k_rhs.mdmr", "zstats_sex.nii.gz"))
zstats1 <- sapply(zstat_files, function(f) read.nifti.image(f)[mask])
colnames(zstats1) <- labels

# Read in the zstats as matrices
zstat_files <- Sys.glob(file.path(base, "rois*", "age+gender_with-meanFD_15k_rhs.mdmr", 
                        "pvals.desc"))
zstat_files <- c(zstat_files, file.path(base, "voxelwise", "age+gender_with-meanFD_15k_rhs.mdmr", "pvals.desc"))
zstats2 <- lapply(zstat_files, function(f) 
                    qt(attach.big.matrix(f)[,2], Inf, lower.tail=F))
names(zstats2) <- labels

# Downsample the rois for voxel->roi
zstats3 <- zstats2
inds <- grep("rois_.*/", zstat_files)
for (i in inds) {
    rois <- list.rois[[i]]
    urois <- sort(unique(rois))
    urois <- urois[urois!=0]
    n <- length(urois)
    
    vec <- vector("numeric", n)
    for (ui in 1:length(urois)) {
        v <- zstats2[[i]][rois==urois[ui]]
        v <- v[is.finite(v)]    # ghetto fix
        vec[ui] <- mean(v)
    }
    zstats3[[i]] <- vec
}

# 1. Want the correlation with voxelwise results
cor_with_voxelwise <- cor(zstats1, method="s")[,ncol(zstats1)]

# 2. Want the correlation with the downsampled voxelwise results
cor_with_voxelwise_ds <- sapply(1:length(list.rois), function(i) {
    rois <- list.rois[[i]]
    urois <- sort(unique(rois))
    urois <- urois[urois!=0]
    n <- length(urois)
    
    vec <- vector("numeric", n)
    for (ui in 1:length(urois)) {
        v <- zstats3[[length(zstats3)]][rois==urois[ui]]
        v <- v[is.finite(v)]
        vec[ui] <- mean(v)
    }
    
    cor(zstats3[[i]], vec)
})
cor_with_voxelwise_ds <- c(cor_with_voxelwise_ds, 1)
names(cor_with_voxelwise_ds) <- labels

# 3. Want the number of significant voxels
num_sig <- apply(zstats1, 2, function(x) sum(x>1.65))
percent_sig <- apply(zstats1, 2, function(x) mean(x>1.65))

# 4. Plot
slabs <- c(rep(c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400), 4), sum(mask))
tlabs <- c(rep(rep(c("standard", "random"), c(9,9)), 2), "voxelwise")
elabs <- rep(c("voxel", "roi", "voxel"), c(18,18,1))
df <- data.frame(
    size = slabs, 
    target = tlabs, 
    seed = elabs, 
    log.size = log(slabs),
    log10.size = log10(slabs), 
    significant = percent_sig * 100, 
    r = cor_with_voxelwise, 
    r.ds = cor_with_voxelwise_ds
)
## percent of significant voxels
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=significant)) + 
    geom_point(aes(shape=target, color=seed, size=3, alpha=0.75)) + 
    geom_smooth(aes(color=seed), method=lm, se=FALSE) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("plots_gender_percent_significant_withseeds.png")
dev.off()
## correlation with voxelwise results
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=r)) + 
    geom_point(aes(shape=target, color=seed, size=3, alpha=0.75)) + 
    geom_smooth(aes(color=seed), method=lm, se=FALSE) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("plots_gender_correlation_with_voxelwise_withseeds.png")
dev.off()
## correlation with voxelwise results (downsampled)
x11(width=8, height=6)
ggplot(df, aes(x=log.size, y=r.ds)) + 
    geom_point(aes(shape=target, color=seed, size=3, alpha=0.75)) + 
    geom_smooth(aes(color=seed), method=lm, se=FALSE) + 
    scale_x_continuous(breaks=df$log.size, labels=slabs) + 
    theme(axis.text = element_text(face="bold", size=20), 
          axis.title=element_blank(), 
          legend.position="none")
ggsave("plots_gender_correlation_with_voxelwise_withseeds.png")
dev.off()



####
## Age
####
#
## Read in the zstats
#zstat_files <- Sys.glob(file.path(base, "*", "age+gender_with-meanFD_15k_rhs.mdmr", 
#                            "zstats_age.nii.gz"))
#zstats <- sapply(zstat_files, function(f) read.nifti.image(f)[mask])
#colnames(zstats) <- c("k0025", "k0050", "k0100", "k0200", "k0400", "k0800", 
#                      "k1600", "k3200", "k6400", "voxelwise")
#
## 1. Want the correlation with voxelwise results
#cor_with_voxelwise <- cor(zstats, method="s")[,ncol(zstats)]
#
## 2. Want the number of significant voxels
#num_sig <- apply(zstats, 2, function(x) sum(x>1.65))
#percent_sig <- apply(zstats, 2, function(x) mean(x>1.65))
#
## 3. Plot
#df <- data.frame(
#    size=xs, 
#    log.size=log(xs),
#    log10.size=log10(xs), 
#    significant=percent_sig * 100, 
#    r=cor_with_voxelwise
#)
### percent of significant voxels
#x11(width=8, height=6)
#ggplot(df, aes(x=log.size, y=significant)) + 
#    geom_point() + geom_smooth(method=lm, se=FALSE) + 
#    scale_x_continuous(breaks=df$log.size, labels=xs) + 
#    theme(axis.text = element_text(face="bold", size=20), axis.title=element_blank())
#ggsave("plots_age_percent_significant.png")
#dev.off()
### correlation with voxelwise results
#x11(width=8, height=6)
#ggplot(df, aes(x=log.size, y=r)) + 
#    geom_point() + geom_smooth(method=lm, se=FALSE) + 
#    scale_x_continuous(breaks=df$log.size, labels=xs) + 
#theme(axis.text = element_text(face="bold", size=20), axis.title=element_blank())
#ggsave("plots_age_correlation_with_voxelwise.png")
##dev.off()
#
#
####
## Gender
####
#
## Read in the zstats
#zstat_files <- Sys.glob(file.path(base, "*", "age+gender_with-meanFD_15k_rhs.mdmr", 
#                            "zstats_sex.nii.gz"))
#zstats <- sapply(zstat_files, function(f) read.nifti.image(f)[mask])
#colnames(zstats) <- c("k0025", "k0050", "k0100", "k0200", "k0400", "k0800", 
#                      "k1600", "k3200", "k6400", "voxelwise")
#
## 1. Want the correlation with voxelwise results
#cor_with_voxelwise <- cor(zstats, method="s")[,ncol(zstats)]
#
## 2. Want the number of significant voxels
#num_sig <- apply(zstats, 2, function(x) sum(x>1.65))
#percent_sig <- apply(zstats, 2, function(x) mean(x>1.65))
#
## 3. Plot
#df <- data.frame(
#    size=xs, 
#    log.size=log(xs),
#    log10.size=log10(xs), 
#    significant=percent_sig * 100, 
#    r=cor_with_voxelwise
#)
### percent of significant voxels
#x11(width=8, height=6)
#ggplot(df, aes(x=log.size, y=significant)) + 
#    geom_point() + geom_smooth(method=lm, se=FALSE) + 
#    scale_x_continuous(breaks=df$log.size, labels=xs) + 
#    theme(axis.text = element_text(face="bold", size=20), axis.title=element_blank())
#ggsave("plots_gender_percent_significant.png")
#dev.off()
### correlation with voxelwise results
#x11(width=8, height=6)
#ggplot(df, aes(x=log.size, y=r)) + 
#    geom_point() + geom_smooth(method=lm, se=FALSE) + 
#    scale_x_continuous(breaks=df$log.size, labels=xs) + 
#theme(axis.text = element_text(face="bold", size=20), axis.title=element_blank())
#ggsave("plots_gender_correlation_with_voxelwise.png")
#dev.off()

