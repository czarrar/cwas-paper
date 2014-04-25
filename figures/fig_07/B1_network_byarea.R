#!/usr/bin/env Rscript

# This script will generate tablish plots to display the number of significant
# findings within each of the seven Yeo brain networks.


###
# Setup

library(niftir)

# General Variables
base        <- "/home2/data/Projects/CWAS"
studies     <- c("development+motion", "adhd200_rerun", "ldopa")

# Input Paths
interm      <- "cwas/compcor_kvoxs_smoothed"
clterm      <- "cluster_correct_v05_c05/easythresh"
mdmr_paths  <- c(
    file.path(base, "development+motion", interm, "age+motion_sex+tr.mdmr"), 
    file.path(base, "adhd200_rerun", interm, "adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr"), 
    file.path(base, "ldopa", interm, "ldopa_subjects+meanFD.mdmr")
)
logp_paths  <- c(
    file.path(mdmr_paths[1], clterm, "thresh_zstat_age.nii.gz"), 
    file.path(mdmr_paths[2], clterm, "thresh_zstat_diagnosis.nii.gz"), 
    file.path(mdmr_paths[3], clterm, "thresh_zstat_conditions.nii.gz")
)
mask_paths  <- file.path(dirname(mdmr_paths), "mask.nii.gz")

# Output Path
outdir   <- file.path(base, "figures/fig_07")

# ROI directory
roidir      <- file.path(base, "nki", "rois")

# 1 = visual network
# 2 = somatomotor network
# 3 = dorsal attention
# 4 = ventral attention
# 5 = limbic
# 6 = fronto-parietal
# 7 = default network
labels <- c("visual", "somatomotor", "dorsal attention", "ventral attention", 
            "limbic", "fronto-parietal", "default")

###


###
# Read

logps <- sapply(1:length(studies), function(i) {
    logp_path <- logp_paths[i]
    mask_path <- mask_paths[i]
    
    mask    <- read.mask(mask_path)
    logp    <- read.nifti.image(logp_path)[mask]
    
    return(logp)
})

rois <- sapply(1:length(studies), function(i) {
    logp_path <- logp_paths[i]
    mask_path <- mask_paths[i]
    
    mask    <- read.mask(mask_path)
    rois    <- read.nifti.image(file.path(roidir, "all_7networks_4mm.nii.gz"))[mask]
    
    return(rois)
})

r <- unlist(rois)
urois <- sort(unique(r[r!=0]))

names(logps) <- studies
names(rois) <- studies

###


###
# Summarize

res <- sapply(1:length(studies), function(i) {
    sapply(1:length(urois), function(j) {
        mean(logps[[i]][rois[[i]]==urois[j]]>0)
    })
})
colnames(res) <- studies
rownames(res) <- labels

print(res)

res2 <- sapply(1:length(studies), function(i) {
    sapply(1:length(urois), function(j) {
        sum(logps[[i]][rois[[i]]==urois[j]]>0)/sum(logps[[i]]>0)
    })
})
colnames(res2) <- studies
rownames(res2) <- labels

print(res2)

###


###
# Additional visualization

library(reshape)
library(ggplot2)
library(RColorBrewer)

df <- melt(res2)
colnames(df) <- c("network", "study", "value")
#df$scan <- factor(df$scan, c("short", "medium", "overlap"))
df$network <- factor(df$network, labels[order(rowMeans(res), decreasing=TRUE)])

outfile <- file.path(outdir, "B_network_line_plot.png")
ggplot(df, aes(x=network, y=value, color=study)) +
  geom_point() +
  geom_line(aes(x=as.numeric(network), y=value)) + 
  ylab("% Significant Associations") + 
  xlab("Network") + 
  scale_color_manual(values=brewer.pal(8, "Dark2")[c(1,4,6)]) + 
  theme(axis.text = element_text(size=16), 
        axis.text.x = element_text(angle=45, vjust=0.5), 
        legend.text = element_text(size=16))
ggsave(outfile)

outfile <- file.path(outdir, "B_network_bar_plot.png")
ggplot(df, aes(x=network, y=value, fill=study)) +
  geom_bar(position="dodge") + 
  ylab("% Significant Associations") + 
  xlab("Network") + 
  scale_fill_manual(values=brewer.pal(8, "Dark2")[c(1,4,6)]) +
  theme(axis.text = element_text(size=16), 
        axis.text.x = element_text(angle=45, vjust=0.5), 
        legend.text = element_text(size=16))
ggsave(outfile)


###


###
# Figure!

library(ggplot2)
library(RColorBrewer)
library(stringr)
library(corrplot)

bs <- colorRampPalette(c("#67001F", "#B2182B", "#D6604D", "#F4A582", "#FDDBC7"))(100)
rs <- colorRampPalette(c("#D1E5F0", "#92C5DE", "#4393C3", "#2166AC", "#053061"))(100)
cols <- rev(c(bs,rs))

scaled.res <- res2/max(res2)
for (i in 1:length(studies)) {
  outfile <- file.path(outdir, sprintf("B_network_byarea_%s.png", studies[i]))
  png(outfile, width=800, height=200, bg="transparent")
	corrplot(t(scaled.res[,i,drop=F]), method="circle", col=cols, bg="transparent", 
				tl.pos="n", cl.pos='n', cl.lim=range(scaled.res), outline=T)
	dev.off()
}

outfile <- file.path(outdir, "B_network_byarea_combined.png")
png(outfile, width=800, height=200, bg="transparent")
corrplot(t(scaled.res), method="circle", col=cols, bg="transparent", 
         tl.pos="n", cl.pos='n', cl.lim=range(scaled.res), outline=T)
dev.off()

cat("Max proportion of voxels:", max(res2), "\n")

###
