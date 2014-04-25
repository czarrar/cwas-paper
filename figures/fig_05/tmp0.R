#!/usr/bin/env Rscript

library(connectir)
library(ggplot2)
library(RColorBrewer)

# Paths
base    <- "/home2/data/Projects/CWAS"
odir    <- file.path(base, "figures/fig_05")
dir.create(odir)

# Scans
scans   <- c("short", "medium")

# Mask
mask    <- read.mask(file.path(base, "nki/rois/mask_gray_4mm.nii.gz"))
nvoxs   <- sum(mask)

# GLM
sdirs   <- file.path(base, sprintf("nki/glm/old_%s_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/summary", scans))
gfiles  <- file.path(sdirs, "uwt_iq.nii.gz")
glms    <- sapply(gfiles, function(f) read.nifti.image(f)[mask])
glms    <- (glms/nvoxs)*100
colnames(glms) <- scans

# MDMR
sdirs   <- file.path(base, sprintf("nki/cwas/%s/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08", scans))
mdirs   <- file.path(sdirs, "iq_age+sex+meanFD+meanGcor.mdmr")
mfiles  <- file.path(mdirs, "cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz")
mdmrs   <- sapply(mfiles, function(f) read.nifti.image(f)[mask])
mdmrs   <- -log10(pt(mdmrs, Inf, lower.tail=F))
colnames(mdmrs) <- scans

## No mean connectivity correction
## GLM
#sdirs   <- file.path(base, sprintf("nki/glm/%s_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/summary", scans))
#gfiles  <- file.path(sdirs, "uwt_iq.nii.gz")
#glms0   <- sapply(gfiles, function(f) read.nifti.image(f)[mask])
#glms0   <- (glms0/nvoxs)*100
#colnames(glms0) <- scans
#
## MDMR
#sdirs   <- file.path(base, sprintf("nki/cwas/%s/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08", scans))
#mdirs   <- file.path(sdirs, "iq_age+sex+meanFD.mdmr")
#mfiles  <- file.path(mdirs, "cluster_correct_v05_c05/easythresh/zstat_FSIQ.nii.gz")
#mdmrs0  <- sapply(mfiles, function(f) read.nifti.image(f)[mask])
#mdmrs0  <- -log10(pt(mdmrs0, Inf, lower.tail=F))
#colnames(mdmrs0) <- scans

# Create the dataframes
df.short    <- data.frame(
    mdmr    = mdmrs[,1], 
    glm     = glms[,1]
)
df.medium   <- data.frame(
    mdmr    = mdmrs[,2], 
    glm     = glms[,2]
)

# Gather colors
cols <- brewer.pal(6, "Dark2")[c(1,4,6,2)]
names(cols) <- c("short", "medium", "overlap", "long")
cols <- as.list(cols)

# Ranges
xmax <- max(c(df.short$mdmr, df.medium$mdmr))
ymax <- max(c(df.short$glm, df.medium$glm))

# Gather colors
cols <- brewer.pal(6, "Dark2")[c(1,4,6,2)]
names(cols) <- c("short", "medium", "overlap", "long")
cols <- as.list(cols)

# Theme Setting For Scatter Plot
scatter_theme <- theme_grey() + 
  theme(text=element_text(family="Helvetica")) + 
  theme(axis.ticks = element_blank(), axis.title = element_blank()) + 
  theme(axis.text = element_text(size=18)) + 
  theme(panel.grid.major = element_line(color="white", size=1), 
        panel.grid.minor = element_line(color="white", size=0.5))

# Short
p <- ggplot(df.short, aes(mdmr, glm)) + 
    geom_point(color=I(cols$short), size=I(5), alpha=I(0.25)) + 
    geom_vline(xintercept=-log10(0.05), linetype='dotted') + 
    xlim(0, xmax) + 
    ylim(0, ymax) + 
    # Labels won't be shown but entered here for clarity
    xlab("MDMR Significance (-log10p)") + 
    ylab("GLM Percent Significant Connections") + 
    scatter_theme
plot(p)
ggsave(file.path(odir, "ztest_A_mdmr_vs_glm_scan01.png"), width=4, height=4)

# Medium
p <- ggplot(df.medium, aes(mdmr, glm)) + 
  geom_point(color=I(cols$medium), size=I(5), alpha=I(0.25)) + 
  geom_vline(xintercept=-log10(0.05), linetype='dotted') + 
  xlim(0, xmax) + 
  ylim(0, ymax) + 
  # Labels won't be shown but entered here for clarity
  xlab("MDMR Significance (-log10p)") + 
  ylab("GLM Percent Significant Connections") + 
  scatter_theme
plot(p)
ggsave(file.path(odir, "ztest_A_mdmr_vs_glm_scan02.png"), width=4, height=4)
