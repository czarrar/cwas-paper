# This script will filter the subjects to be used
# and match the groups

# Setup
basedir <- "/home2/data/Projects/CWAS/share/adhd200"
subdir <- file.path(basedir, "subinfo")
subfile <- file.path(subdir, "03_subjects_qc.csv")

# Read
df <- read.csv(subfile)

# Only want NYU
sdf <- subset(df, site=="NYU")
sdf$X <- 1:nrow(sdf)

# Combine the ADHD sub-groups
groups <- as.character(sdf$group)
groups[groups %in% c("ADHD-C", "ADHD-I")] = "ADHD"
sdf$group <- factor(groups)

# Match the two groups on age and sex as best as you can
inds.adhd <- sdf$group=="ADHD"  #91
inds.tdc <- sdf$group=="TDC"    #80
comp.age <- sdf$age[inds.tdc]
inds.adhd.use <- c()
for (age in comp.age) {
    i <- which.min(abs(sdf$age[inds.adhd] - age))
    inds.adhd.use <- c(inds.adhd.use, sdf$X[inds.adhd][i])
    inds.adhd[inds.adhd][i] <- F
}

# New dataframe
fdf <- rbind(
    subset(sdf, group=="TDC"), 
    sdf[inds.adhd.use,]
)

# Save
write.csv(fdf, file="../subinfo/04_subjects_matched_combined.csv")
