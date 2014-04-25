#!/usr/bin/env Rscript

library(ggplot2)

df <- data.frame(
    method=c("Degree", "GLM", "MDMR", "SVM", "K-Means"), 
    time=c(5.7681699999999836, 30.121669999999945, 51.73251000000004, 228.89548000000013, 788.41194999999982)
)
df$method <- factor(as.character(df$method), levels=as.character(df$method))

barplot_theme <- theme_grey() + 
  theme(text=element_text(family="Helvetica")) + 
  theme(axis.ticks = element_blank(), axis.title.y = element_text(size=20), axis.title.x=element_blank()) + 
  theme(axis.text = element_text(size=18)) + 
  theme(legend.position="none") + 
  theme(strip.text = element_text(size=18)) + 
  theme(panel.grid.major.y = element_line(color="white", size=1), 
        panel.grid.minor.y = element_line(color="white", size=0.5), 
        panel.grid.major.x = element_blank(), 
        panel.grid.minor.x = element_blank())

ggplot(df, aes(x=method, y=time)) + 
    geom_bar() +
    ylab("Time (ms)") + 
    barplot_theme

