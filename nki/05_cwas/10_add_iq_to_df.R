#!/usr/bin/env Rscript

# This script combines the subject information I got online with
# IQ information on the same subjects from COINS.

#' # Setup
#+ setup
library(ggplot2)
subdir <- "../subinfo"
# read in subject info
iq.df <- read.csv(file.path(subdir, "crossCollapsetest_20130510.csv"))
set1.df <- read.csv(file.path(subdir, "40_Set1_N104", "subject_info.csv"))
set2.df <- read.csv(file.path(subdir, "40_Set2_N92", "subject_info.csv"))

#' Fix and clean the IQ data frame
#+ fix
# Deal with the two row header
notes_col <- grep("notes", colnames(iq.df))
tmp1 <- iq.df[-1,1:notes_col]
iq_cols <- as.character(sapply(iq.df[1,(notes_col+1):ncol(iq.df)], as.character))
tmp2 <- iq.df[-1,(notes_col+1):ncol(iq.df)]
colnames(tmp2) <- iq_cols
# Only keep IQ and subject columns
iq_df <- cbind(tmp1, tmp2)
iq_df <- iq_df[,-c(2:notes_col)]
# Fix the column values
iq_df[,-1] <- apply(iq_df[,-1], 2, function(x) as.numeric(as.character(x)))
iq_df[,1] <- as.character(factor(iq_df[,1]))
# Constrain to only the composite scroes
iq_df <- iq_df[,c(1,grep("Composite", colnames(iq_df)))]
colnames(iq_df) <- c("Id", "VIQ", "PIQ", "FSIQ")
rownames(iq_df) <- 1:nrow(iq_df)


#' # Combine

#' Combine the IQ info with each of the datasets.
#' I'll only be taking the FSIQ, VIQ, and PIQ combination score.
#+ combine-set1
set1.combined <- merge(set1.df, iq_df, by="Id")
all.equal(set1.combined$Id, set1.df$Id) # just double check

#+ combine-set2
set2.combined <- merge(set2.df, iq_df, by="Id")
all.equal(set2.combined$Id, set2.df$Id) # just double check


#' # Visualize
#+ viz
ggplot(set1.combined, aes(x=FSIQ, fill=factor(all))) + geom_histogram(binwidth=5) + xlab("IQ Scores") + ggtitle("Full-Scale IQ")
ggplot(set1.combined, aes(x=VIQ, fill=factor(all))) + geom_histogram(binwidth=5) + xlab("IQ Scores") + ggtitle("Verbal IQ")
ggplot(set1.combined, aes(x=PIQ, fill=factor(all))) + geom_histogram(binwidth=5) + xlab("IQ Scores") + ggtitle("Performace IQ")

#' These two plots might be relevant if we ran Verbal or Performance seperately afterwards.
#+ viz-compare
ggplot(set1.combined, aes(x=FSIQ, y=PIQ, color=factor(all))) + 
  geom_point(size=3) + xlab("FSIQ") + ylab("PIQ") + ggtitle("Full-Scale vs Performace IQ")
ggplot(set1.combined, aes(x=FSIQ, y=VIQ, color=factor(all))) + 
  geom_point(size=3) + xlab("FSIQ") + ylab("VIQ") + ggtitle("Full-Scale vs Verbal IQ")

#' # Save
#+ save
write.csv(set1.combined, file=file.path(subdir, "40_Set1_N104", "subject_info_with_iq.csv"))
write.csv(set2.combined, file=file.path(subdir, "40_Set2_N92", "subject_info_with_iq.csv"))
