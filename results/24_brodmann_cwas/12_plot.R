library(ggplot2)

df <- read.csv("10_dataframe_lh.csv")

superdf <- data.frame(ba=factor(rep(df$ba, 2)), measure=rep(c("meta-analysis", "cwas"), each=nrow(df)), value=c(as.numeric(df$meta_analysis), as.numeric(df$summary_uwt*100)))

ggplot(superdf, aes(ba, value, fill=measure)) + geom_bar(position="dodge", stat="identity") + facet_grid(measure ~ .) + xlab("Brodmann Area")