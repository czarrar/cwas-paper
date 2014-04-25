#!/usr/bin/env Rscript

# Setup
cat("Setup\n")
basedir <- "/home2/data/Projects/CWAS/share/adhd200"
subdir <- file.path(basedir, "subinfo")
subfile <- file.path(subdir, "04_subjects_matched_combined.csv")

# Read
cat("Read\n")
df <- read.csv(subfile)

# FuncPaths - Setup
cat("Funcpaths - Setup\n")
preprocdir <- "/home2/data/PreProc/ADHD200/sym_links/pipeline_0"
pipelines <- c(
    "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98", 
    "linear1.wm1.global1.motion1.csf1_CSF_0.98_GM_0.7_WM_0.98"
)
suffix <- "scan_rest/func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz"

# FuncPaths - CompCor
cat("Funcpaths - CompCor\n")
compcor_funcs <- file.path(preprocdir, pipelines[1], 
                            sprintf("%07i_", df$id), 
                            suffix)
## fix
other_subs <- !file.exists(compcor_funcs)
other_preprocdir <- file.path(dirname(preprocdir), "pipeline_HackettCity")
compcor_funcs[other_subs] <- file.path(other_preprocdir, pipelines[1], 
                                       sprintf("%07i", df$id[other_subs]), 
                                       suffix)

# FuncPaths - Global
cat("Funcpaths - Global\n")
global_funcs <- file.path(preprocdir, pipelines[2], 
                            sprintf("%07i_", df$id), 
                            suffix)
## fix
other_subs <- !file.exists(global_funcs)
other_preprocdir <- file.path(dirname(preprocdir), "pipeline_HackettCity")
global_funcs[other_subs] <- file.path(other_preprocdir, pipelines[2], 
                                       sprintf("%07i", df$id[other_subs]), 
                                       suffix)

# Save
cat("Save\n")
write.table(compcor_funcs, file=file.path(subdir, "05_compcor_funcpaths_combined.txt"), 
            row.names=FALSE, col.names=FALSE)
write.table(global_funcs, file=file.path(subdir, "06_global_funcpaths_combined.txt"), 
            row.names=FALSE, col.names=FALSE)
