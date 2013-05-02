# This script will go through the subjectsand soft-link their original data 
# in a usable fashion so that C-PAC can be easily used

library(plyr)

df <- read.csv("/home2/data/Projects/CWAS/share/adhd200/subinfo/02_subject_info_all.csv")
df$id <- sprintf("%07i", df$id)

in_basedir <- "/data/Originals/ADHD200/usable_copy/unsorted"
out_basedir <- "/home2/data/Projects/CWAS/adhd200/Originals"

# create output site directories
l_ply(unique(df$site), function(site) {
    dir.create(file.path(out_basedir, site))
})

# patch fixes
df$anat.run[df$id == "0010043"] <- 1
df$anat.run[df$id == "5971050"] <- 1
df$rest.run[df$id == "3619797"] <- 1

# check
for (i in 1:nrow(df)) {
    line <- df[i,]
    
    cat("Subject:", line$id, "\n")
    
    in_subdir <- file.path(in_basedir, line$id)
    in_sesdir <- file.path(in_subdir, "session_1")
    if (!file.exists(in_subdir)) stop("subject directory doesn't exist")
    if (!file.exists(in_sesdir)) stop("session directory doesn't exist")
        
    in_mprage <- file.path(in_sesdir, sprintf("anat_%i", line$anat.run), "mprage.nii.gz")
    in_rest <- file.path(in_sesdir, sprintf("rest_%i", line$rest.run), "rest.nii.gz")
    if (!file.exists(in_mprage)) stop("mprage ", in_mprage, " doesn't exist")
    if (!file.exists(in_rest)) stop("rest ", in_rest, " doesn't exist")    
}

# create
for (i in 1:nrow(df)) {
    line <- df[i,]
    
    cat("Subject:", line$id, "\n")
    
    in_subdir <- file.path(in_basedir, line$id)
    in_sesdir <- file.path(in_subdir, "session_1")
    if (!file.exists(in_subdir)) stop("subject directory doesn't exist")
    if (!file.exists(in_sesdir)) stop("session directory doesn't exist")
        
    in_mprage <- file.path(in_sesdir, sprintf("anat_%i", line$anat.run), "mprage.nii.gz")
    in_rest <- file.path(in_sesdir, sprintf("rest_%i", line$rest.run), "rest.nii.gz")
    if (!file.exists(in_mprage)) stop("mprage ", in_mprage, " doesn't exist")
    if (!file.exists(in_rest)) stop("rest doesn't exist")
        
    out_subdir <- file.path(out_basedir, line$site, line$id)    
    out_mprage <- file.path(out_subdir, "mprage.nii.gz")
    out_rest <- file.path(out_subdir, "rest.nii.gz")
    dir.create(out_subdir)
    file.symlink(in_mprage, out_mprage)
    file.symlink(in_rest, out_rest)    
}

