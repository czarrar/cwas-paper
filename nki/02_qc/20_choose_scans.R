#' This script does some quick comparisons of the scans following QC
#' 

#+ setup, include=FALSE
library(ggplot2)
df <- read.csv("../subinfo/qc-2_usable_scans.csv")
df <- df[,colnames(df)!="subdir"] # remove the path column


###
# Examine 2 of the scans
###

#' # Two Scans

#' Here we examine subjects who have 645 and 1400ms TR scans that pass QC.
#' We look at the distribution of ages and the breakdown of sex and handedness.
#+ two-scans-subset
sdf <- subset(df, short==1 & medium==1)

#' Age appears to be bimodally distributed, is this an issue?
#+ two-scans-age
ggplot(sdf, aes(Age)) + geom_histogram(binwidth=5) + ggtitle("Age for Participants with 2 Scans")

#' Note there is one participant who doesn't have gender recorded.
#+ two-scans-sex
table(sdf$Sex)
ggplot(sdf, aes(Sex)) + geom_bar() + ggtitle("Sex for Participants with 2 Scans")

#' Woot, majority of people are right-handed.
#+ two-scans-handedness
table(sdf$Handedness)
ggplot(sdf, aes(Handedness)) + geom_bar() + ggtitle("Handedness for Participants with 2 Scans")


###
# Examine all three scans
###

#' # Three Scans

#' Here I will be seeing how the distribution of the subjects from above
#' will differ with the removal of subjects who don't have a 3rd scan.
#' Where color is shown, red means subjects with only two scans, while
#' blue means subjects with all three scans usable.

#' Subjects that would be lost if looking at three scans are in red (shown first)
#' Only subjects with three usable scans are shown second.
#+ three-scans-age
ggplot(sdf, aes(Age, fill=factor(all))) + geom_histogram(binwidth=5) + ggtitle("Age for Participants with 2/3 Scans")
ggplot(sdf[sdf$all==3,], aes(Age)) + geom_histogram(binwidth=5) + ggtitle("Age for Participants with 3 Scans")

#' The first table output is for 2 scans and the second is for 3 scans.
#+ three-scans-sex
table(sdf$Sex)
table(sdf$Sex[sdf$all==3])
ggplot(sdf, aes(Sex, fill=factor(all))) + geom_bar() + ggtitle("Sex for Participants with 2/3 Scans")
ggplot(sdf[sdf$all==3,], aes(Sex)) + geom_bar() + ggtitle("Sex for Participants with 3 Scans")

#' The first table output is for 2 scans and the second is for 3 scans.
#' Woot, majority of people are still right-handed.
#+ three-scans-handedness
table(sdf$Handedness)
table(sdf$Handedness[sdf$all==3])
ggplot(sdf, aes(Handedness, fill=factor(all))) + geom_bar() + ggtitle("Handedness for Participants with 2/3 Scans")
ggplot(sdf[sdf$all==3,], aes(Handedness)) + geom_bar() + ggtitle("Handedness for Participants with 3 Scans")

