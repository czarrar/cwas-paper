# Setup
basedir <- "/home2/data/Projects/CWAS/share/adhd200_rerun"
subdir <- file.path(basedir, "subinfo")
subfile <- file.path(subdir, "30_subjects_matched.csv")

# Read
df <- read.csv(subfile)

# FuncPaths - Setup
pipelines <- c(
    "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98", 
    "linear1.wm1.global1.motion1.csf1_CSF_0.98_GM_0.7_WM_0.98"
)
suffix <- "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz"

# input will be the global or 2nd pipeline
global_funcs <- file.path(df$funcdir, suffix)
if (!all(file.exists(global_funcs))) stop("not all global files exist")

# also generate paths for compcor
compcor_funcs <- file.path(gsub(pipelines[2], pipelines[1], df$funcdir), suffix)
if (!all(file.exists(compcor_funcs))) stop("not all compcor files exist")

# Save
write.table(compcor_funcs, file=file.path(subdir, "30_compcor_funcpaths.txt"), 
            row.names=FALSE, col.names=FALSE)
write.table(global_funcs, file=file.path(subdir, "30_global_funcpaths.txt"), 
            row.names=FALSE, col.names=FALSE)
