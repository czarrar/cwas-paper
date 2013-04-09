# This script will visualize the demographic data per site

## Setup

library(ggplot2)
library(plyr)

basedir <- "/home/data/Projects/CWAS"
sdir <- file.path(basedir, "share/age+gender/subinfo")

new_df <- read.csv(file.path(sdir, "04_all_df.csv"))

mytheme <- theme_bw() + theme(
    legend.background = element_blank(),
    legend.key        = element_blank(),
    panel.background  = element_blank(),
    panel.border      = element_blank(),
    strip.background  = element_blank(),
    plot.background   = element_blank(),
    axis.line         = element_blank(),
    panel.grid.minor  = element_blank()
)


## Sex

p <- ggplot(new_df, aes(site, fill=sex)) + 
        geom_bar() + 
        facet_grid(sample ~ .) + 
        xlab("") + 
        ylab("Number of Participants") + 
        mytheme
p + theme(
    legend.title        = element_blank(), 
    axis.text.x         = element_text(angle = 90, vjust = 0.5, hjust = 1), 
    panel.grid.major.y  = element_line(color="grey90", linetype="dashed"), 
    panel.grid.major.x  = element_blank(), 
    axis.ticks.x        = element_blank()
)


## Age

p <- ggplot(new_df, aes(site, age)) + 
        geom_violin(aes(fill = site)) + 
        facet_grid(sample ~ .) + 
        xlab("") + 
        ylab("Age") + 
        scale_y_continuous(breaks = seq(20, 80, by = 10)) + 
        mytheme
p + theme(
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1), 
        axis.ticks.x = element_blank(), 
        legend.position = "none", 
        panel.grid.minor.y = element_line(colour = "grey98", size = 0.5), 
        panel.grid.major.x = element_blank()
)

