#!/usr/bin/env Rscript

library(ggplot2)
suppressPackageStartupMessages(library(niftir))

base     <- "/home/data/Projects/CWAS"
maskfile <- file.path(base, "/nki/rois/mask_gray_2mm.nii.gz")
mask     <- read.mask(maskfile)
nvoxs    <- sum(mask)


## Summarizes data.
## Gives count, mean, standard deviation, standard error of the mean, and confidence interval (default 95%).
##   data: a data frame.
##   measurevar: the name of a column that contains the variable to be summariezed
##   groupvars: a vector containing names of columns that contain grouping variables
##   na.rm: a boolean that indicates whether to ignore NA's
##   conf.interval: the percent range of the confidence interval (default is 95%)
summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
                      conf.interval=.95, .drop=TRUE) {
    require(plyr)

    # New version of length which can handle NA's: if na.rm==T, don't count them
    length2 <- function (x, na.rm=FALSE) {
        if (na.rm) sum(!is.na(x))
        else       length(x)
    }

    # This is does the summary; it's not easy to understand...
    datac <- ddply(data, groupvars, .drop=.drop,
                   .fun= function(xx, col, na.rm) {
                           c( N    = length2(xx[,col], na.rm=na.rm),
                              mean = mean   (xx[,col], na.rm=na.rm),
                              sd   = sd     (xx[,col], na.rm=na.rm)
                              )
                          },
                    measurevar,
                    na.rm
             )

    # Rename the "mean" column    
    datac <- rename(datac, c("mean"=measurevar))

    datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean

    # Confidence interval multiplier for standard error
    # Calculate t-statistic for confidence interval: 
    # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
    ciMult <- qt(conf.interval/2 + .5, datac$N-1)
    datac$ci <- datac$se * ciMult

    return(datac)
}

# Theme Setting For Scatter Plot
barplot_theme <- theme_grey() + 
  theme(text=element_text(family="Helvetica")) + 
  theme(axis.ticks = element_blank(), axis.title = element_blank()) + 
  theme(axis.text = element_text(size=18)) + 
  theme(legend.position="none") + 
  theme(strip.text = element_text(size=18)) + 
  theme(panel.grid.major.y = element_line(color="white", size=1), 
        panel.grid.minor.y = element_line(color="white", size=0.5), 
        panel.grid.major.x = element_blank(), 
        panel.grid.minor.x = element_blank())
        


###
# NO Global
###

# Plot the percent of significant voxels

df        <- read.csv(file.path(base, "nki/sca/summarize_sca-iq.csv"))
df$perc   <- (df$tot/nvoxs)*100
mdf       <- summarySE(df, "perc", c("scan", "label"))

roi_types <- c("maxima", "significant", "not-significant", "minima")
scans     <- c("short", "medium", "long")
mdf$label <- factor(mdf$label, levels=roi_types)
mdf$scan  <- factor(mdf$scan, levels=scans, labels=c("Scan 1", "Scan 2", "Scan 3"))



#write.table(mdf, quote=F, file=file.path(base, "figures/fig_06/B_summary_bar_plot.txt"))

#ggplot(data=mdf, aes(x=scan, y=(tot/nvoxs)*100, fill=label)) + 
#  geom_dotplot(binaxis="y", stackdir="center", position="dodge")

#ggplot(data=mdf, aes(x=scan, y=tot, group=label, fill=label)) + 
  #geom_bar(postition="dodge", stat="identity")

ggplot(data=mdf, aes(x=label, y=perc, group=label, fill=label)) + 
  geom_bar(postition="dodge", stat="identity") +
  geom_errorbar(aes(ymin=perc-se, ymax=perc+se),
                    width=.2,                    # Width of the error bars
                    position=position_dodge(.9)) + 
  facet_grid(. ~ scan) + 
  geom_hline(yintercept=0) + 
  ylim(c(0,20)) + 
  xlab("ROI Types") + 
  ylab("Percent of Significant Connectivity-IQ Associations") + 
  barplot_theme + 
  theme(axis.text.x = element_blank())
ggsave(file.path(base, "figures/fig_06/B_summary_bar_plot_scan1.png"), width=6, height=4)


# This will plot all the points
#ggplot(data=df, aes(x=label, y=(tot/nvoxs)*100, group=label, color=label, shape=label)) + 
#  geom_point() +
#  facet_grid(. ~ scan) + 
#  xlab("ROI Types") + 
#  ylab("Percent of Significant Connectivity-IQ Associations")


# How to get the colors
#h = c(0, 360) + 15, c = 100, l = 65,
#         h.start = 0, direction = 1, na.value = "grey50"
#
#> sapply(roi_types, function(x) sample(sdf$roi[sdf$label==x], 1))
#         maxima     significant not-significant          minima 
#              5              28              53              64 

# rainbow_hcl(4, c=100, l=65, start=15)



###
# NO Global - Scan 2
###

df        <- read.csv(file.path(base, "nki/sca2/summarize_sca-iq.csv"))
df$perc   <- (df$tot/nvoxs)*100
mdf       <- summarySE(df, "perc", c("scan", "label"))

roi_types <- c("maxima", "significant", "not-significant", "minima")
scans     <- c("short", "medium", "long")
mdf$label <- factor(mdf$label, levels=roi_types)
mdf$scan  <- factor(mdf$scan, levels=scans, labels=c("Scan 1", "Scan 2", "Scan 3"))

ggplot(data=mdf, aes(x=label, y=perc, group=label, fill=label)) + 
  geom_bar(postition="dodge", stat="identity") +
  geom_errorbar(aes(ymin=perc-se, ymax=perc+se),
                    width=.2,                    # Width of the error bars
                    position=position_dodge(.9)) + 
  facet_grid(. ~ scan) + 
  geom_hline(yintercept=0) + 
  ylim(c(0,20)) + 
  xlab("ROI Types") + 
  ylab("Percent of Significant Connectivity-IQ Associations") + 
  barplot_theme + 
  theme(axis.text.x = element_blank())
ggsave(file.path(base, "figures/fig_06/B_summary_bar_plot_scan2.png"), width=6, height=4)




####
## YES Global
####
#
## Plot the percent of significant voxels
#
#df <- read.csv(file.path(base, "nki/sca/summarize_sca-iq_meanGcor.csv"))
#roi_types <- c("maxima", "significant", "not-significant", "minima")
#scans     <- c("short", "medium", "long")
#df$label  <- factor(df$label, levels=roi_types)
#df$scan   <- factor(df$scan, levels=scans) 
#
#head(df)
#
#mdf <- ddply(df, .(scan, label), colwise(mean))
#write.table(mdf, quote=F, file=file.path(base, "figures/fig_06/B_summary_bar_plot_meanGcor.txt"))
#
##ggplot(data=mdf, aes(x=scan, y=(tot/nvoxs)*100, fill=label)) + 
##  geom_dotplot(binaxis="y", stackdir="center", position="dodge")
#
##ggplot(data=mdf, aes(x=scan, y=tot, group=label, fill=label)) + 
#  #geom_bar(postition="dodge", stat="identity")
#
#ggplot(data=mdf, aes(x=label, y=(tot/nvoxs)*100, group=label, fill=label)) + 
#  geom_bar(postition="dodge", stat="identity") +
#  facet_grid(. ~ scan) + 
#  xlab("ROI Types") + 
#  ylab("Percent of Significant Connectivity-IQ Associations") + 
#  ylim(0,10)
#ggsave(file.path(base, "figures/fig_06/B_summary_bar_plot_meanGcor.png"), width=10, height=6)

