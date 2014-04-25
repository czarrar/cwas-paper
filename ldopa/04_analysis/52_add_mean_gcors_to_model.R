#!/usr/bin/env Rscript

subdir   <- "../subinfo"
strategy <- "compcor"

# Model
model_file      <- file.path(subdir, "02_demo.csv")
model           <- read.csv(model_file)

# Mean Gcors
mean_gcors_file <- file.path(subdir, "mean_gcors_all_4mm_fwhm08.txt")
mean_gcors      <- read.table(mean_gcors_file)[,]

# Add to Model
model$meanGcor  <- mean_gcors

# Save
out_file <- file.path(subdir, "02_demo_with_gcors.csv")
write.csv(model, file=out_file, row.names=F)
