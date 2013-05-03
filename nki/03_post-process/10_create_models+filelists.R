#!/usr/bin/env Rscript

#' This script will gather new dataframes for analyses
#' as well as various files with paths to the functional data

#' # Setup
#+ setup
library(ggplot2)
df <- read.csv("../subinfo/30_phenos+qc+paths.csv")


#' # Filter Subjects

#' ## Select Ages
#' We will select participants between 18-65 (ie adults).
#+ select-ages
sdf <- subset(df, Age>=18 & Age<=65)

#' ## Select Usable Scans
#' We'll generate two sets of data-frames
#' 1. For subjects with usuable short and medium scans
#+ select-scans1
df.sm = subset(sdf, short==1 & medium==1, select=-X)
cat(sprintf("# of subjects: %i\n", nrow(df.sm)))

#' 2. For subjects with all three scans as usable
#+ select-scans2
df.sml = subset(df.sm, all==3)
cat(sprintf("# of subjects: %i\n", nrow(df.sml)))

#' ## Visaulize demographics
#' Here we show the distribution of ages, sexes, and handedness.

#+ viz-demos
ggplot(df.sm, aes(Age, fill=factor(all))) + geom_histogram(binwidth=5) + 
  ggtitle(sprintf("N=%i with 2 scans and N=%i with 3 scans", nrow(df.sm), nrow(df.sml)))
ggplot(df.sm, aes(Sex, fill=factor(all))) + geom_bar() + 
  ggtitle(sprintf("N=%i with 2 scans and N=%i with 3 scans", nrow(df.sm), nrow(df.sml)))
ggplot(df.sm, aes(Handedness, fill=factor(all))) + geom_bar() + 
  ggtitle(sprintf("N=%i with 2 scans and N=%i with 3 scans", nrow(df.sm), nrow(df.sml)))



#' # Create file lists

#' Here we will create two sets of functional file lists for participants with
#' 2 scans and participants with 3 scans.
#+ list-setup
basedir <- "/home2/data/Projects/NKI_ROCKLAND_CPAC_test/Sink/sym_links"
pipelines <- c(
  "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98", 
  "linear1.wm1.global1.motion1.csf1_CSF_0.98_GM_0.7_WM_0.98"
)
suffix <- "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz"

#' ## Two Scans
#+ sm-setup
outbase <- sprintf("../subinfo/40_Set1_N%i", nrow(df.sm))
dir.create(outbase, F)
fnames <- c("short", "medium", "long")
#+ sm-lists
for (i in 1:length(fnames)) {
  name <- fnames[i]
  # compcor
  funclist <- file.path(basedir, df.sm[[paste(name, "dir", sep="_")]], suffix)
  outfile <- sprintf("%s/%s_compcor_funcpaths.txt", outbase, name)
  write.table(funclist, file=outfile, row.names=F, col.names=F)
  # global
  funclist <- gsub(pipelines[1], pipelines[2], funclist)
  outfile <- sprintf("%s/%s_global_funcpaths.txt", outbase, name)
  write.table(funclist, file=outfile, row.names=F, col.names=F)
}
#+ sm-df
outdf <- subset(df.sm, select=-c(short_dir, medium_dir, long_dir))
outfile <- file.path(outbase, "subject_info.csv")
write.csv(outdf, outfile)

#' ## Three Scans
#+ sml-setup
outbase <- sprintf("../subinfo/40_Set2_N%i", nrow(df.sml))
dir.create(outbase, F)
fnames <- c("short", "medium", "long")
#+ sml-lists
for (i in 1:length(fnames)) {
  name <- fnames[i]
  # compcor
  funclist <- file.path(basedir, df.sml[[paste(name, "dir", sep="_")]], suffix)
  outfile <- sprintf("%s/%s_compcor_funcpaths.txt", outbase, name)
  write.table(funclist, file=outfile, row.names=F, col.names=F)
  # global
  funclist <- gsub(pipelines[1], pipelines[2], funclist)
  outfile <- sprintf("%s/%s_global_funcpaths.txt", outbase, name)
  write.table(funclist, file=outfile, row.names=F, col.names=F)
}
#+ sml-df
outdf <- subset(df.sml, select=-c(short_dir, medium_dir, long_dir))
outfile <- file.path(outbase, "subject_info.csv")
write.csv(outdf, outfile)
