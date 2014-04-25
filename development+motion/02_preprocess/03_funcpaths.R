#!/usr/bin/env Rscript

# This will generate the list of functional filepaths

fname <- "/home2/data/Projects/CWAS/share/development+motion/subinfo/01_subject_info.csv"
df <- read.csv(fname)

basedir <- "/home2/data/PreProc/POWER_2012/sym_links/pipeline_0"
deriv_compcor <- file.path(basedir, "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98")
deriv_regular <- file.path(basedir, "linear1.wm1.global1.motion1.csf1_CSF_0.98_GM_0.7_WM_0.98")

#func_files <- file.path(deriv_compcor, paste(df$id, "_", sep=""), "scan_rest", "func", "bandpass_freqs_0.01.0.1", "functional_mni.nii.gz")
#write.table(func_files, file="../subinfo/02_funcpaths.txt", row.names=F, col.names=F)

func_files <- file.path(deriv_regular, paste(df$id, "_", sep=""), "scan_rest", "func", "bandpass_freqs_0.01.0.1", "functional_mni.nii.gz")
write.table(func_files, file="../subinfo/02_funcpaths_global.txt", row.names=F, col.names=F)
