#!/usr/bin/env Rscript

subdir   <- "../subinfo/40_Set1_N104"
scans    <- c("short", "medium")
strategy <- "compcor"

# Model
model_file      <- file.path(subdir, "subject_info_with_iq.csv")
model           <- read.csv(model_file)

# Mean Gcors
mean_gcors_file <- file.path(subdir, sprintf("mean_gcors_short+medium_%s_4mm_fwhm08.txt", strategy))
mean_gcors      <- read.table(mean_gcors_file)[,]

# Add to Model
model$short_meanGcor  <- mean_gcors[,1]
model$medium_meanGcor <- mean_gcors[,2]

# Save
out_file <- file.path(subdir, "subject_info_with_iq_and_gcors.csv")
write.csv(model, file=out_file, row.names=F)

out_file <- file.path(subdir, "short_mean_global.txt")
col <- subset(model, select=c("short_meanGcor"))
col$short_meanGcor <- scale(col$short_meanGcor, scale=F)
write.table(col, file=out_file, row.names=F, quote=F)

out_file <- file.path(subdir, "medium_mean_global.txt")
col <- subset(model, select=c("medium_meanGcor"))
col$medium_meanGcor <- scale(col$medium_meanGcor, scale=F)
write.table(col, file=out_file, row.names=F, quote=F)
