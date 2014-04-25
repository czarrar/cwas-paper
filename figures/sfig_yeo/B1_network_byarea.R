#!/usr/bin/env Rscript

# This script will generate tablish plots to display the number of significant
# findings within each of the seven Yeo brain networks.


###
# Setup

library(niftir)

base        <- "/home2/data/Projects/CWAS"
roidir      <- file.path(base, "nki", "rois")

scans       <- c("short", "medium")
strategy    <- "compcor"
kstr        <- "kvoxs_fwhm08_to_kvoxs_fwhm08"
mname       <- "iq_age+sex+meanFD+meanGcor.mdmr"
cname       <- "cluster_correct_v05_c05"
factor      <- "FSIQ"

datadirs    <- file.path(base, "nki/cwas", scans, sprintf("%s_%s", strategy, kstr), mname, cname)
logpfiles   <- file.path(datadirs, "easythresh", sprintf("thresh_zstat_%s.nii.gz", factor))
if (!all(file.exists(logpfiles))) stop("input clust_logp files don't exist")

odir        <- file.path(base, "figures", "sfig_yeo")

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

mask    <- read.mask(file.path(roidir, "mask_gray_4mm.nii.gz"))
rois    <- read.nifti.image(file.path(roidir, "all_7networks_4mm.nii.gz"))[mask]
urois   <- sort(unique(rois[rois!=0]))
logps   <- sapply(logpfiles, function(f) read.nifti.image(f)[mask])

colnames(logps) <- scans

###


###
# Overlap (add it)

logps <- cbind(logps, logps[,1]*logps[,2])
scans <- c(scans, "overlap")
colnames(logps) <- scans

###


###
# Summarize

res <- sapply(1:length(scans), function(i) {
    sapply(1:length(urois), function(j) {
        mean(logps[rois==urois[j],i]>0)
    })
})
colnames(res) <- scans
rownames(res) <- labels
write.table(res, file=file.path(odir, "C_percent_associations_within_network.txt"))

res2 <- sapply(1:length(scans), function(i) {
    sapply(1:length(urois), function(j) {
        sum(logps[rois==urois[j],i]>0)/sum(logps[,i]>0)
    })
})
colnames(res2) <- scans
rownames(res2) <- labels
write.table(res2, file=file.path(odir, "C_percent_associations_across_networks.txt"))

###


###
# Additional visualization

library(reshape)
library(ggplot2)
library(RColorBrewer)

df <- melt(res2)
colnames(df) <- c("network", "scan", "value")
df$scan <- factor(df$scan, c("short", "medium", "overlap"))
df$network <- factor(df$network, labels[order(rowMeans(res2[,1:2]), decreasing=TRUE)])

outfile <- file.path(odir, "B_network_line_plot.png")
ggplot(df, aes(x=network, y=value, color=scan)) +
  geom_point() +
  geom_line(aes(x=as.numeric(network), y=value)) + 
  ylab("% Significant Associations") + 
  xlab("Network") + 
  scale_color_manual(values=brewer.pal(8, "Dark2")[c(1,4,6)]) + 
  theme(axis.text = element_text(size=16), 
        axis.text.x = element_text(angle=45, vjust=0.5), 
        legend.text = element_text(size=16))
ggsave(outfile)

outfile <- file.path(odir, "B_network_bar_plot.png")
ggplot(df, aes(x=network, y=value, fill=scan)) +
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
for (i in 1:length(scans)) {
  outfile <- file.path(odir, sprintf("B_network_byarea_%s.png", scans[i]))
  png(outfile, width=800, height=200, bg="transparent")
	corrplot(t(scaled.res[,i,drop=F]), method="circle", col=cols, bg="white", 
				tl.pos="n", cl.pos='n', cl.lim=range(scaled.res), outline=T)
	dev.off()
}

outfile <- file.path(odir, "B_network_byarea_combined.png")
png(outfile, width=800, height=200, bg="transparent")
corrplot(t(scaled.res), method="circle", col=cols, bg="white", 
         tl.pos="n", cl.pos='n', cl.lim=range(scaled.res), outline=T)
dev.off()

###
