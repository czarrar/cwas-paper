#!/usr/bin/env Rscript

library(ggplot2)
library(niftir)

base     <- "/home/data/Projects/CWAS"
maskfile <- file.path(base, "/nki/rois/mask_gray_4mm.nii.gz")
mask     <- read.mask(maskfile)
nvoxs    <- sum(mask)



###
# NO Global
###

# Plot the percent of significant voxels

df <- read.csv(file.path(base, "nki/sca/seeds/summarize_glm-iq.csv"))
roi_types <- c("maxima", "significant", "not-significant", "minima")
scans     <- c("short", "medium")
df$label  <- factor(df$label, levels=roi_types)
df$scan   <- factor(df$scan, levels=scans) 

head(df)

mdf <- ddply(df, .(scan, label), colwise(mean))

#ggplot(data=mdf, aes(x=scan, y=(tot/nvoxs)*100, fill=label)) + 
#  geom_dotplot(binaxis="y", stackdir="center", position="dodge")

#ggplot(data=mdf, aes(x=scan, y=tot, group=label, fill=label)) + 
  #geom_bar(postition="dodge", stat="identity")

ggplot(data=mdf, aes(x=label, y=glm, group=label, fill=label)) + 
  geom_bar(postition="dodge", stat="identity") +
  facet_grid(. ~ scan) + 
  xlab("ROI Types") + 
  ylab("Percent of Significant Connectivity-IQ Associations")
ggsave(file.path(base, "figures/fig_06/B_summary_bar_plot.png"), width=10, height=6)


# THIS PLOTS EVERYTHING
#ggplot(data=df, aes(x=label, y=glm, group=label, color=label, shape=label)) + 
#  geom_point() +
#  facet_grid(. ~ scan) + 
#  xlab("ROI Types") + 
#  ylab("Percent of Significant Connectivity-IQ Associations")

