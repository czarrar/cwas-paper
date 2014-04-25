#!/usr/bin/env Rscript

#' This script is to create the modified model and path files for running the scan effects CWAS
#' It involves combining (row merge) the model and the path files together
#' and adding a new column in the model indicating the scan by name


#' Set paths and what not
#+ setup
basedir <- "/home2/data/Projects/CWAS"
subbase <- file.path(basedir, "share/nki/subinfo")
subdir  <- file.path(subbase, "40_Set1_N104")

in_modelfile    <- file.path(subdir, "subject_info_with_iq.csv")
out_modelfile   <- file.path(subdir, "subject_info_with_iq_byscan.csv")

scans           <- c("short", "medium")
in_pathfiles    <- file.path(subdir, sprintf("%s_compcor_funcpaths_4mm_smoothed.txt", scans))
out_pathfile    <- file.path(subdir, sprintf("%s_compcor_funcpaths_4mm_smoothed.txt", paste(scans, collapse="+")))


#' Load data and what not
#+ load
model <- read.csv(in_modelfile)
pathfiles <- lapply(in_pathfiles, function(f) as.character(read.table(f)[,1]))

#' Format model
#+ model
new_model   <- rbind(model, model)
# remove meanFD & scan QC columns
new_model   <- subset(new_model, select=-c(short_meanFD, medium_meanFD, long_meanFD))
new_model   <- subset(new_model, select=-c(short, medium, long))
# add subject and scan factor columns
new_model$subject   <- sprintf("sub%03i", rep(1:nrow(model), 2))
new_model$scan      <- rep(scans, each=nrow(model))
# add combined meanFD column
new_model$meanFD    <- c(model$short_meanFD, model$medium_meanFD)

#' Gather functional paths
#+ paths
new_pathfiles <- unlist(pathfiles)

#' Save the biznutches
#+ save
write.csv(new_model, file=out_modelfile, row.names=F)
write.table(new_pathfiles, file=out_pathfile)
