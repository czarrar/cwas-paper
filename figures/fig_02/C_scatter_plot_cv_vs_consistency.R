#!/usr/bin/env Rscript

library(niftir)
library(ggplot2)


# Histograms of voxelwise distance summaries


###
# Paths
###

basedir     <- "/home2/data/Projects/CWAS/nki/stability"
strategy    <- "N104_compcor"
kstr        <- "kvoxs_fwhm08_to_kvoxs_fwhm08"
measures    <- c("mean_short", "mean_medium", "sd_short", "sd_medium", 
                 "cv_short", "cv_medium", "consistency")
mask_file   <- "/home2/data/Projects/CWAS/nki/rois/mask_gray_4mm.nii.gz"

# Input Directory
indir       <- file.path(basedir, sprintf("%s_%s", strategy, kstr))

# Input Measure Files
infiles1    <- file.path(indir, sprintf("%s.nii.gz", measures))
infiles2    <- file.path(indir, sprintf("%s_zscore.nii.gz", measures))

# Out
odir <- "/home2/data/Projects/CWAS/figures/fig_02"


###
# Read NIFTI
###

# Mask
mask <- read.mask(mask_file)

# Voxelwise Images
imgs1 <- sapply(infiles1, function(f) read.nifti.image(f)[mask])
imgs2 <- sapply(infiles2, function(f) read.nifti.image(f)[mask])

# Used
df <- data.frame(
    measure = rep(rep(c("CV-short", "CV-medium", "Consistency-between"), 2), each=sum(mask)),
    standardize = rep(c("no", "yes"), each=sum(mask)*3),
    value = c(as.vector(imgs1[,5:7]), as.vector(imgs2[,5:7]))
)


####
## Histograms
####
#
#cat("histograms\n")
#
#sdf <- subset(df, standardize == "no")
#p <- ggplot(sdf, aes(x=value)) + 
#    geom_histogram() +
#    facet_grid(measure ~ .)
#plot(p)
#ggsave(file.path(odir, "hists_no_z.png"))
#
#sdf <- subset(df, standardize == "yes")
#p <- ggplot(sdf, aes(x=value)) + 
#  geom_histogram() +
#  facet_grid(measure ~ .)
#plot(p)
#ggsave(file.path(odir, "hists_z.png"))


###
# Scatter Plot
###

sdf <- subset(df, standardize == 'yes')
scatter_df <- data.frame(
  cv.short = sdf$value[sdf$measure == "CV-short"], 
  cv.medium = sdf$value[sdf$measure == "CV-medium"], 
  cv = (sdf$value[sdf$measure == "CV-short"] + sdf$value[sdf$measure == "CV-medium"])/2, 
  consistency = sdf$value[sdf$measure == "Consistency-between"]
)

# Theme Setting For Scatter Plot
scatter_theme <- theme_grey() + 
  theme(text=element_text(family="Helvetica")) + 
  theme(axis.ticks = element_blank(), axis.title = element_blank()) + 
  theme(axis.text = element_text(size=18)) + 
  theme(panel.grid.major = element_line(color="white", size=1), 
        panel.grid.minor = element_line(color="white", size=0.25))

## Compare to average
#p <- ggplot(scatter_df, aes(x=cv, y=consistency)) + 
#    geom_point(color=I("grey5"), size=I(5), alpha=I(0.25)) + 
#    # Labels won't be shown but entered here for clarity
#    xlab("Coefficieny of Variation (Z-Score)") + 
#    ylab("Consistency Between Scans (Z-Score)") + 
#    scatter_theme
#plot(p)
#ggsave(file.path(odir, "scatter_cv_vs_consistency_z.png"), width=4, height=4)

# Compare to scan 1
cat("scan 1 CV vs consistency\n")
p <- ggplot(scatter_df, aes(x=cv.short, y=consistency)) + 
    geom_point(color=I("grey5"), size=I(5), alpha=I(0.25)) + 
    # Labels won't be shown but entered here for clarity
    xlab("Scan 1 - Coefficieny of Variation (Z-Score)") + 
    ylab("Consistency Between Scans (Z-Score)") + 
    ylim(-3.1, 3.1) + 
    xlim(-3.1, 4.4) + 
    scatter_theme
plot(p)
ggsave(file.path(odir, "C_scatter_cv1_vs_consistency.png"), width=4, height=4)

# Compare to scan 2
cat("scan 2 CV vs consistency\n")
p <- ggplot(scatter_df, aes(x=cv.medium, y=consistency)) + 
    geom_point(color=I("grey5"), size=I(5), alpha=I(0.25)) + 
    # Labels won't be shown but entered here for clarity
    xlab("Scan 2 - Coefficieny of Variation (Z-Score)") + 
    ylab("Consistency Between Scans (Z-Score)") + 
    ylim(-3.1, 3.1) + 
    xlim(-3.1, 4.4) +
    scatter_theme
plot(p)
ggsave(file.path(odir, "C_scatter_cv2_vs_consistency.png"), width=4, height=4)
