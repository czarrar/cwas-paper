# This generates the specific list of ROI paths for the discovery and 
# replication samples

sbase <- "/home2/data/Projects/CWAS/share/age+gender/analysis/03_robustness/subinfo"
obase <- "/home2/data/Projects/CWAS/share/age+gender/analysis/03_robustness/roisinfo"

disc.funcs <- read.table("subinfo/04_discovery_funcpaths_4mm.txt")
disc.funcs <- as.character(disc.funcs[,])

repl.funcs <- read.table("subinfo/04_replication_funcpaths_4mm.txt")
repl.funcs <- as.character(repl.funcs[,])

ks <- c(25,50,100,200,400,800,1600,3200)

# Discovery
for (k in ks) {
    rois <- file.path(dirname(disc.funcs), sprintf("rois_random_k%04i.nii.gz", k))
    ofile <- file.path("roisinfo", sprintf("discovery_rois_random_k%04i_nifti.txt", k))
    write.table(rois, file=ofile, row.names=F, col.names=F)    
}

# Replication
for (k in ks) {
    rois <- file.path(dirname(repl.funcs), sprintf("rois_random_k%04i.nii.gz", k))
    ofile <- file.path("roisinfo", sprintf("replication_rois_random_k%04i_nifti.txt", k))
    write.table(rois, file=ofile, row.names=F, col.names=F)
}
