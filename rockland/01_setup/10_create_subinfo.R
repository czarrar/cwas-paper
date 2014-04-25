#!/usr/bin/env Rscript

# File Paths
cat("File Paths\n")
base        <- "/home2/data/Projects/CWAS/share"
i_subinfo   <- file.path(base, "age+gender/subinfo")
o_subinfo   <- file.path(base, "rockland/subinfo")

# Data Frame
cat("Data Frame\n")
idf_file    <- file.path(i_subinfo, "04_all_df.csv")
all_df      <- read.csv(idf_file)
df          <- subset(all_df, site == "Rockland")

# Func Paths
cat("Func Paths\n")
suffix      <- "func/bandpass_freqs_0.01.0.1/functional_mni_4mm.nii.gz"
funcpaths   <- file.path(df$outdir, suffix)
if (!all(file.exists(funcpaths))) stop("path issue")

# Save
cat("Save\n")
write.csv(df, file=file.path(o_subinfo, "10_df.csv"))
write.table(funcpaths, row.names=F, col.names=F, file=file.path(o_subinfo, "10_funcpaths.txt"))
