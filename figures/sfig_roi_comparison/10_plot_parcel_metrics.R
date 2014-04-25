#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(niftir))
library(ggplot2)

# This script gathers information for the three metrics:
# - percent of significant voxels (averaged across the two scans)
# - reproducibility between scans
# - overlap with voxelwise data


###
# Setup P1
###

# General Variables
base     <- "/home2/data/Projects/CWAS"
odir     <- file.path(base, "figures", "sfig_roi_comparison")

# Input Ingredients
factor      <- "FSIQ"
study       <- "nki"
scans       <- c("short", "medium")
prefixes    <- file.path(base, study, "cwas", scans)
ks          <- c(25, 50, 100, 200, 400, 800, 1600, 3200, 6400)

# Input Paths
subdirs <- unlist(lapply(prefixes, function(p) {
    paths <- file.path(p, sprintf("compcor_only_rois_random_k%04i", ks))# parcellations
    c(paths, file.path(p, "compcor_kvoxs_fwhm08_to_kvoxs_fwhm08"))      # voxelwise
}))
mdmrdirs <- file.path(subdirs, "iq_age+sex+meanFD.mdmr")
easydirs <- file.path(mdmrdirs, "cluster_correct_v05_c05/easythresh")

# Input Filenames
raw.fn <- "zstat_FSIQ.nii.gz"
thr.fn <- "thresh_zstat_FSIQ.nii.gz"


###
# Setup P2
###

# Mask
maskfile <- file.path(base, "nki/rois/mask_gray_4mm.nii.gz")
mask <- read.mask(maskfile)
nvoxs <- sum(mask)

# Total
ks <- c(ks, nvoxs)

# Setup the general dataframe
paths <- data.frame(
    scan = rep(c("short", "medium"), each=length(ks)), 
    k    = rep(ks, 2), 
    easy = easydirs
)
df <- data.frame(
    index = 1:length(easydirs), 
    scan = rep(c("short", "medium"), each=length(ks)), 
    k    = rep(ks, 2)
)

# Load the data
dat.raw <- sapply(easydirs, function(f) {
    read.nifti.image(file.path(f, raw.fn))[mask]
})
dat.thr <- sapply(easydirs, function(f) {
    read.nifti.image(file.path(f, thr.fn))[mask]
})


###
# Metrics
###

dice <- function(a,b) (2 * sum(a&b))/(sum(a) + sum(b))

# 1. Percent significant
df$psig <- colMeans(dat.thr>0) * 100

# 2. Reproducibility
tmp <- daply(df, .(k), function(dfk) {
    si <- dfk$index[dfk$scan == "short"]
    mi <- dfk$index[dfk$scan == "medium"]
    dice(dat.thr[,si]>0, dat.thr[,mi]>0)
})
df$reproduce <- rep(tmp, 2)

# 3. Overlap with voxelwise
short.vox.i  <- length(ks); medium.vox.i <- length(easydirs)
df$overlap <- daply(df, .(index), function(x) {
    if (x$scan == "short") {
        vox.i <- short.vox.i
    } else {
        vox.i <- medium.vox.i
    }
    
    noverlap <- sum((dat.thr[,x$index]>0) & (dat.thr[,vox.i]>0))
    nvox     <- sum(dat.thr[,vox.i]>0)
    
    (noverlap/nvox) * 100
})



###
# Combine
###

ave_df <- ddply(df, .(k), colwise(mean, .(psig, reproduce, overlap)))
write.table(ave_df, file=file.path(odir, "10_parcel_metrics_table.txt"))

# if you want rank ordering
# cbind(ave_df$k, rowMeans(cbind(rank(ave_df$psig), rank(ave_df$reproduce), rank(ave_df$overlap))))


###
# Plot
###

# Theme Setting For Scatter Plot
scatter_theme <- theme_grey() + 
  theme(text=element_text(family="Helvetica")) + 
  theme(axis.ticks = element_blank(), axis.title = element_blank()) + 
  theme(axis.text = element_text(size=18)) + 
  theme(panel.grid.major = element_line(color="white", size=1), 
        panel.grid.minor = element_line(color="white", size=0.25))

str_ks <- as.character(ks)
str_ks[length(str_ks)] <- sprintf("%i\nvoxelwise", nvoxs)

# 1. Percent Significant
p <- ggplot(ave_df, aes(x=log(k), y=psig)) + 
  geom_line(color="grey60") + 
  geom_point(size=4, color="grey30") + 
  xlab("Number of Parcellations") + 
  ylab("Percent of Significant Voxels") + 
  ylim(c(0,30)) + 
  scatter_theme + 
  theme(panel.grid.minor.x = element_blank()) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5)) + 
  scale_x_continuous(breaks=log(ks), labels=ks)
plot(p)
ggsave(file.path(odir, "A1_percent_signif.png"), width=6, height=4)

# 2. Reproducibility
p <- ggplot(ave_df, aes(x=log(k), y=reproduce)) + 
  geom_line(color="grey60") + 
  geom_point(size=4, color="grey30") + 
  xlab("Number of Parcellations") + 
  ylab("Overlap of Significant Associations Between Scans (dice)") + 
  scatter_theme + 
  theme(panel.grid.minor.x = element_blank()) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5)) + 
  scale_x_continuous(breaks=log(ks), labels=ks)
plot(p)
ggsave(file.path(odir, "A2_reproducibility.png"), width=6, height=4)

# 3. Overlap with voxelwise results
#    (don't show voxelwise 100% results)
tmp_df <- ave_df
tmp_df$overlap[nrow(tmp_df)] <- NA
p <- ggplot(tmp_df, aes(x=log(k), y=overlap)) + 
  geom_line(color="grey60") + 
  geom_point(size=4, color="grey30") + 
  xlab("Number of Parcellations") + 
  ylab("Percent of Significant Associations Overlapping with Voxelwise Results") + 
  scatter_theme + 
  theme(panel.grid.minor.x = element_blank()) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5)) + 
  scale_x_continuous(breaks=log(ks), labels=ks)
plot(p)
ggsave(file.path(odir, "A3_overlap_voxelwise.png"), width=6, height=4)
