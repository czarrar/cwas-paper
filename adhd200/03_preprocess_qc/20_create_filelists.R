# Setup
basedir <- "/home2/data/Projects/CWAS/share/adhd200"
subdir <- file.path(basedir, "subinfo")
subfile <- file.path(subdir, "03_subjects_matched.csv")

# Read
df <- read.csv(subfile)

# FuncPaths - Setup
preprocdir <- "/home2/data/PreProc/ADHD200/sym_links/pipeline_0"
pipelines <- c(
    "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98", 
    "linear1.wm1.global1.motion1.csf1_CSF_0.98_GM_0.7_WM_0.98"
)
suffix <- "scan_rest/func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz"

# FuncPaths - CompCor
compcor_funcs <- file.path(preprocdir, pipelines[1], 
                            sprintf("%07i_", df$ScanDir.ID), 
                            suffix)
## fix
other_subs <- !file.exists(compcor_funcs)
other_preprocdir <- file.path(dirname(preprocdir), "pipeline_HackettCity")
compcor_funcs[other_subs] <- file.path(other_preprocdir, pipelines[1], 
                                       sprintf("%07i", df$ScanDir.ID[other_subs]), 
                                       suffix)

# FuncPaths - Global
global_funcs <- file.path(preprocdir, pipelines[2], 
                            sprintf("%07i_", df$ScanDir.ID), 
                            suffix)
## fix
other_subs <- !file.exists(global_funcs)
other_preprocdir <- file.path(dirname(preprocdir), "pipeline_HackettCity")
global_funcs[other_subs] <- file.path(other_preprocdir, pipelines[2], 
                                       sprintf("%07i", df$ScanDir.ID[other_subs]), 
                                       suffix)

# Save
write.table(compcor_funcs, file=file.path(subdir, "04a_compcor_funcpaths.txt"), 
            row.names=FALSE, col.names=FALSE)
write.table(global_funcs, file=file.path(subdir, "04b_global_funcpaths.txt"), 
            row.names=FALSE, col.names=FALSE)
